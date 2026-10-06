const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const initSqlJs = require('sql.js');
const multer = require('multer');
const archiver = require('archiver');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');
const cookieParser = require('cookie-parser');

const PORT = process.env.PORT || 3000;
const DATA = process.env.STORAGE_DIR || path.join(__dirname, 'data');
fs.mkdirSync(path.join(DATA, 'avatars'), { recursive: true });
fs.mkdirSync(path.join(DATA, 'photos'), { recursive: true });
const DBFILE = path.join(DATA, 'duxk.db');

let db;
function saveDb() { fs.writeFileSync(DBFILE, Buffer.from(db.export())); }
function q(sql, p) {
  const st = db.prepare(sql);
  if (p) st.bind(p);
  const out = [];
  while (st.step()) out.push(st.getAsObject());
  st.free();
  return out;
}
function one(sql, p) { return q(sql, p)[0]; }
function run(sql, p) {
  const st = db.prepare(sql);
  st.run(p || []);
  st.free();
  const id = db.exec('SELECT last_insert_rowid() AS id;')[0].values[0][0];
  saveDb();
  return id;
}
function del(sql, p) {
  const st = db.prepare(sql);
  st.run(p || []);
  st.free();
  saveDb();
}

const app = express();
app.set('trust proxy', 1);
app.use(express.json({ limit: '1mb' }));
app.use(cookieParser());

const CODE_ABC = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
function makeCode() {
  let s = '';
  for (let i = 0; i < 10; i++) s += CODE_ABC[crypto.randomInt(CODE_ABC.length)];
  return s;
}
function makeToken() { return crypto.randomBytes(32).toString('hex'); }
function avatarUrl(uid) {
  const u = one('SELECT avatar FROM users WHERE id=?', [uid]);
  if (u && u.avatar) return '/api/public/avatar/' + uid;
  return null;
}
function pubUser(u) {
  return { id: u.id, username: u.username, email: u.email || null, avatar_url: avatarUrl(u.id), totp_on: !!u.totp_on, is_admin: !!u.is_admin };
}
function cleanSessions() { del('DELETE FROM sessions WHERE expires < ?', [Date.now()]); }
function newSession(uid, days) {
  cleanSessions();
  const token = makeToken();
  run('INSERT INTO sessions (token, user_id, expires, pending) VALUES (?,?,?,0)', [token, uid, Date.now() + days * 86400000]);
  return token;
}
function setCookie(res, token, days) {
  res.cookie('duxk_session', token, { httpOnly: true, sameSite: 'lax', secure: process.env.NODE_ENV === 'production', maxAge: days * 86400000 });
}
function auth(req, res, next) {
  const t = req.cookies.duxk_session;
  if (!t) return res.status(401).json({ error: 'Not logged in' });
  const s = one('SELECT * FROM sessions WHERE token=?', [t]);
  if (!s || s.expires < Date.now() || s.pending) return res.status(401).json({ error: 'Not logged in' });
  const u = one('SELECT * FROM users WHERE id=?', [s.user_id]);
  if (!u) return res.status(401).json({ error: 'Not logged in' });
  if (u.banned) return res.status(403).json({ error: 'Banned: ' + (u.ban_reason || 'no reason') });
  req.user = u;
  next();
}

const hits = new Map();
function limited(req, res, next) {
  const k = req.ip + req.path;
  const now = Date.now();
  const arr = (hits.get(k) || []).filter(t => now - t < 600000);
  arr.push(now);
  hits.set(k, arr);
  if (arr.length > 30) return res.status(429).json({ error: 'Too many tries. Wait a few minutes.' });
  next();
}
function validName(n) { return typeof n === 'string' && /^[A-Za-z0-9_.]{3,20}$/.test(n); }
function validMail(e) { return typeof e === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e); }

app.post('/api/auth/register', limited, (req, res) => {
  const { username, password, email } = req.body || {};
  if (!validName(username)) return res.status(400).json({ error: 'Username: 3-20 chars, letters numbers _ .' });
  if (typeof password !== 'string' || password.length < 6) return res.status(400).json({ error: 'Password needs 6+ chars' });
  let mail = null;
  if (email) {
    if (!validMail(email)) return res.status(400).json({ error: 'Bad email' });
    mail = email.toLowerCase();
    if (one('SELECT id FROM users WHERE email=?', [mail])) return res.status(400).json({ error: 'Email taken' });
  }
  if (one('SELECT id FROM users WHERE username=?', [username])) return res.status(400).json({ error: 'Name taken' });
  const id = run('INSERT INTO users (username, email, pass, created) VALUES (?,?,?,?)', [username, mail, bcrypt.hashSync(password, 10), Date.now()]);
  if (process.env.ADMIN_USERNAME && username === process.env.ADMIN_USERNAME) {
    del('UPDATE users SET is_admin=1 WHERE id=?', [id]);
  }
  const token = newSession(id, 30);
  setCookie(res, token, 30);
  res.json({ user: pubUser(one('SELECT * FROM users WHERE id=?', [id])) });
});

app.post('/api/auth/login', limited, (req, res) => {
  const { login, password } = req.body || {};
  if (typeof login !== 'string' || typeof password !== 'string') return res.status(400).json({ error: 'Missing login' });
  const u = one('SELECT * FROM users WHERE username=? OR email=?', [login, login.toLowerCase()]);
  if (!u || !bcrypt.compareSync(password, u.pass)) return res.status(401).json({ error: 'Wrong login or password' });
  if (u.banned) return res.status(403).json({ error: 'Banned: ' + (u.ban_reason || 'no reason') });
  if (u.totp_on) {
    cleanSessions();
    const tmp = makeToken();
    run('INSERT INTO sessions (token, user_id, expires, pending) VALUES (?,?,?,1)', [tmp, u.id, Date.now() + 600000]);
    return res.json({ need2fa: true, tmp });
  }
  const token = newSession(u.id, 30);
  setCookie(res, token, 30);
  res.json({ user: pubUser(u) });
});

app.post('/api/auth/verify', limited, (req, res) => {
  const { tmp, code } = req.body || {};
  const s = one('SELECT * FROM sessions WHERE token=?', [tmp]);
  if (!s || s.expires < Date.now() || !s.pending) return res.status(401).json({ error: 'Code expired. Log in again.' });
  const u = one('SELECT * FROM users WHERE id=?', [s.user_id]);
  if (!u || !u.totp) return res.status(401).json({ error: 'Code expired. Log in again.' });
  const ok = speakeasy.totp.verify({ secret: u.totp, encoding: 'base32', token: String(code || '').trim(), window: 1 });
  if (!ok) return res.status(401).json({ error: 'Wrong code' });
  del('DELETE FROM sessions WHERE token=?', [tmp]);
  const token = newSession(u.id, 30);
  setCookie(res, token, 30);
  res.json({ user: pubUser(u) });
});

app.post('/api/auth/logout', (req, res) => {
  const t = req.cookies.duxk_session;
  if (t) del('DELETE FROM sessions WHERE token=?', [t]);
  res.clearCookie('duxk_session');
  res.json({ ok: true });
});

app.get('/api/me', auth, (req, res) => { res.json({ user: pubUser(req.user) }); });

app.put('/api/me', auth, (req, res) => {
  const { username } = req.body || {};
  if (!validName(username)) return res.status(400).json({ error: 'Username: 3-20 chars, letters numbers _ .' });
  if (one('SELECT id FROM users WHERE username=? AND id<>?', [username, req.user.id])) return res.status(400).json({ error: 'Name taken' });
  del('UPDATE users SET username=? WHERE id=?', [username, req.user.id]);
  res.json({ user: pubUser(one('SELECT * FROM users WHERE id=?', [req.user.id])) });
});

app.put('/api/me/email', auth, (req, res) => {
  const { email, code } = req.body || {};
  if (email && !validMail(email)) return res.status(400).json({ error: 'Bad email' });
  if (req.user.totp_on) {
    const ok = speakeasy.totp.verify({ secret: req.user.totp, encoding: 'base32', token: String(code || '').trim(), window: 1 });
    if (!ok) return res.status(401).json({ error: 'Wrong 2-step code' });
  }
  const mail = email ? email.toLowerCase() : null;
  if (mail && one('SELECT id FROM users WHERE email=? AND id<>?', [mail, req.user.id])) return res.status(400).json({ error: 'Email taken' });
  del('UPDATE users SET email=? WHERE id=?', [mail, req.user.id]);
  res.json({ user: pubUser(one('SELECT * FROM users WHERE id=?', [req.user.id])) });
});

app.put('/api/me/password', auth, (req, res) => {
  const { current, next } = req.body || {};
  if (!bcrypt.compareSync(String(current || ''), req.user.pass)) return res.status(401).json({ error: 'Wrong current password' });
  if (typeof next !== 'string' || next.length < 6) return res.status(400).json({ error: 'New password needs 6+ chars' });
  del('UPDATE users SET pass=? WHERE id=?', [bcrypt.hashSync(next, 10), req.user.id]);
  res.json({ ok: true });
});

const avUp = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
app.post('/api/me/avatar', auth, avUp.single('avatar'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file' });
  if (!req.file.mimetype.startsWith('image/')) return res.status(400).json({ error: 'Image only' });
  const ext = (req.file.mimetype.split('/')[1] || 'jpg').replace(/[^a-z0-9]/gi, '').slice(0, 4) || 'jpg';
  const p = path.join(DATA, 'avatars', req.user.id + '.' + ext);
  fs.readdirSync(path.join(DATA, 'avatars')).forEach(f => { if (f.startsWith(req.user.id + '.')) fs.unlinkSync(path.join(DATA, 'avatars', f)); });
  fs.writeFileSync(p, req.file.buffer);
  del('UPDATE users SET avatar=? WHERE id=?', [p, req.user.id]);
  res.json({ user: pubUser(one('SELECT * FROM users WHERE id=?', [req.user.id])) });
});

app.get('/api/2fa/setup', auth, async (req, res) => {
  const secret = speakeasy.generateSecret({ name: 'DuXK (' + req.user.username + ')', length: 20 });
  del('UPDATE users SET totp=? WHERE id=?', [secret.base32, req.user.id]);
  const qrCode = await QRCode.toDataURL(secret.otpauth_url);
  res.json({ qr: qrCode });
});

app.post('/api/2fa/enable', auth, (req, res) => {
  const u = one('SELECT * FROM users WHERE id=?', [req.user.id]);
  if (!u.totp) return res.status(400).json({ error: 'Open setup first' });
  const ok = speakeasy.totp.verify({ secret: u.totp, encoding: 'base32', token: String((req.body || {}).code || '').trim(), window: 1 });
  if (!ok) return res.status(401).json({ error: 'Wrong code' });
  del('UPDATE users SET totp_on=1 WHERE id=?', [req.user.id]);
  res.json({ user: pubUser(one('SELECT * FROM users WHERE id=?', [req.user.id])) });
});

app.post('/api/2fa/disable', auth, (req, res) => {
  if (!bcrypt.compareSync(String((req.body || {}).password || ''), req.user.pass)) return res.status(401).json({ error: 'Wrong password' });
  del('UPDATE users SET totp=NULL, totp_on=0 WHERE id=?', [req.user.id]);
  res.json({ user: pubUser(one('SELECT * FROM users WHERE id=?', [req.user.id])) });
});

app.get('/api/codes', auth, (req, res) => {
  const rows = q('SELECT code, created FROM codes WHERE user_id=? ORDER BY created DESC', [req.user.id]);
  const devs = q('SELECT * FROM devices WHERE user_id=?', [req.user.id]);
  res.json({ codes: rows, devices: devs });
});

app.post('/api/codes', auth, (req, res) => {
  let code = makeCode();
  while (one('SELECT code FROM codes WHERE code=?', [code])) code = makeCode();
  run('INSERT INTO codes (code, user_id, created) VALUES (?,?,?)', [code, req.user.id, Date.now()]);
  res.json({ code });
});

app.post('/api/codes/regenerate', auth, (req, res) => {
  const { code } = req.body || {};
  del('DELETE FROM codes WHERE code=? AND user_id=?', [String(code || '').toUpperCase(), req.user.id]);
  let nc = makeCode();
  while (one('SELECT code FROM codes WHERE code=?', [nc])) nc = makeCode();
  run('INSERT INTO codes (code, user_id, created) VALUES (?,?,?)', [nc, req.user.id, Date.now()]);
  res.json({ code: nc });
});

app.delete('/api/codes', auth, (req, res) => {
  del('DELETE FROM codes WHERE code=? AND user_id=?', [String((req.body || {}).code || '').toUpperCase(), req.user.id]);
  res.json({ ok: true });
});

app.delete('/api/devices', auth, (req, res) => {
  const d = one('SELECT * FROM devices WHERE token=? AND user_id=?', [(req.body || {}).token, req.user.id]);
  if (!d) return res.status(404).json({ error: 'Not found' });
  del('DELETE FROM devices WHERE token=?', [d.token]);
  res.json({ ok: true });
});

app.post('/api/link', limited, (req, res) => {
  const { code, device_name, device_model } = req.body || {};
  const c = String(code || '').trim().toUpperCase();
  if (!c) return res.status(400).json({ error: 'Enter a key' });
  const row = one('SELECT * FROM codes WHERE code=?', [c]);
  if (!row) return res.status(404).json({ error: 'Invalid key' });
  const u = one('SELECT * FROM users WHERE id=?', [row.user_id]);
  if (!u) return res.status(404).json({ error: 'Invalid key' });
  const token = makeToken();
  run('INSERT INTO devices (token, user_id, name, model, linked) VALUES (?,?,?,?,?)',
    [token, u.id, String(device_name || 'iPhone').slice(0, 60), String(device_model || '').slice(0, 60), Date.now()]);
  del('DELETE FROM codes WHERE code=?', [c]);
  res.json({ device_token: token, account: { username: u.username, avatar_url: avatarUrl(u.id) } });
});

app.get('/api/device/status', (req, res) => {
  const d = one('SELECT * FROM devices WHERE token=?', [String(req.query.token || '')]);
  if (!d) return res.json({ linked: false });
  const u = one('SELECT * FROM users WHERE id=?', [d.user_id]);
  if (!u) return res.json({ linked: false });
  res.json({ linked: true, account: { username: u.username, avatar_url: avatarUrl(u.id) }, device: { name: d.name, model: d.model } });
});

app.post('/api/device/unlink', (req, res) => {
  del('DELETE FROM devices WHERE token=?', [String((req.body || {}).token || '')]);
  res.json({ ok: true });
});

const phUp = multer({ storage: multer.memoryStorage(), limits: { fileSize: 100 * 1024 * 1024 } });
app.post('/api/device/photos', phUp.single('photo'), (req, res) => {
  const d = one('SELECT * FROM devices WHERE token=?', [String((req.body || {}).token || '')]);
  if (!d) return res.status(401).json({ error: 'Not linked' });
  const owner = one('SELECT banned FROM users WHERE id=?', [d.user_id]);
  if (owner && owner.banned) return res.status(403).json({ error: 'Blocked' });
  if (!req.file) return res.status(400).json({ error: 'No file' });
  if (!req.file.mimetype.startsWith('image/')) return res.status(400).json({ error: 'Image only' });
  const dir = path.join(DATA, 'photos', String(d.user_id));
  fs.mkdirSync(dir, { recursive: true });
  const safe = (req.file.originalname || 'photo.jpg').replace(/[^A-Za-z0-9_.-]/g, '_').slice(0, 80);
  const id = run('INSERT INTO photos (user_id, device, name, file, mime, size, taken, uploaded) VALUES (?,?,?,?,?,?,?,?)',
    [d.user_id, d.token, safe, '', req.file.mimetype, req.file.size, Number((req.body || {}).taken) || null, Date.now()]);
  const fp = path.join(dir, id + '_' + safe);
  fs.writeFileSync(fp, req.file.buffer);
  del('UPDATE photos SET file=? WHERE id=?', [fp, id]);
  res.json({ id });
});

function photoJson(p) {
  return { id: p.id, name: p.name, mime: p.mime, size: p.size, taken: p.taken, uploaded: p.uploaded, url: '/api/photos/' + p.id + '/file' };
}

app.get('/api/photos', auth, (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 200, 500);
  const offset = Number(req.query.offset) || 0;
  const rows = q('SELECT * FROM photos WHERE user_id=? ORDER BY uploaded DESC LIMIT ? OFFSET ?', [req.user.id, limit, offset]);
  const total = one('SELECT COUNT(*) c FROM photos WHERE user_id=?', [req.user.id]).c;
  res.json({ total, photos: rows.map(photoJson) });
});

app.get('/api/photos/:id/file', auth, (req, res) => {
  const p = one('SELECT * FROM photos WHERE id=? AND user_id=?', [req.params.id, req.user.id]);
  if (!p || !fs.existsSync(p.file)) return res.status(404).end();
  if (req.query.download) res.download(p.file, p.name);
  else res.sendFile(p.file);
});

app.post('/api/photos/zip', auth, (req, res) => {
  const { ids, all } = req.body || {};
  let rows;
  if (all) rows = q('SELECT * FROM photos WHERE user_id=? ORDER BY uploaded DESC', [req.user.id]);
  else {
    if (!Array.isArray(ids) || !ids.length) return res.status(400).json({ error: 'Nothing selected' });
    rows = q('SELECT * FROM photos WHERE user_id=?', [req.user.id]).filter(p => ids.includes(p.id));
  }
  if (!rows.length) return res.status(404).json({ error: 'Nothing found' });
  res.setHeader('Content-Type', 'application/zip');
  res.setHeader('Content-Disposition', 'attachment; filename="duxk-photos.zip"');
  const z = archiver('zip', { zlib: { level: 5 } });
  z.on('error', () => { try { res.end(); } catch (e) { /* noop */ } });
  z.pipe(res);
  rows.forEach(p => { if (fs.existsSync(p.file)) z.file(p.file, { name: p.id + '_' + p.name }); });
  z.finalize();
});

app.get('/api/public/avatar/:uid', (req, res) => {
  const u = one('SELECT avatar FROM users WHERE id=?', [req.params.uid]);
  if (!u || !u.avatar || !fs.existsSync(u.avatar)) return res.status(404).end();
  res.sendFile(u.avatar);
});

function admin(req, res, next) {
  if (!req.user.is_admin) return res.status(403).json({ error: 'Nope' });
  next();
}

app.get('/api/admin/users', auth, admin, (req, res) => {
  const rows = q('SELECT id, username, email, created, banned, ban_reason, is_admin FROM users ORDER BY created DESC');
  res.json({ users: rows.map(u => ({
    id: u.id, username: u.username, email: u.email, created: u.created,
    banned: !!u.banned, ban_reason: u.ban_reason, is_admin: !!u.is_admin,
    codes: one('SELECT COUNT(*) c FROM codes WHERE user_id=?', [u.id]).c,
    devices: one('SELECT COUNT(*) c FROM devices WHERE user_id=?', [u.id]).c,
    photos: one('SELECT COUNT(*) c FROM photos WHERE user_id=?', [u.id]).c
  })) });
});

app.post('/api/admin/ban', auth, admin, (req, res) => {
  const { user_id, reason } = req.body || {};
  if (user_id === req.user.id) return res.status(400).json({ error: 'No' });
  if (!one('SELECT id FROM users WHERE id=?', [user_id])) return res.status(404).json({ error: 'Not found' });
  del('UPDATE users SET banned=1, ban_reason=? WHERE id=?', [String(reason || '').slice(0, 200), user_id]);
  del('DELETE FROM codes WHERE user_id=?', [user_id]);
  del('DELETE FROM sessions WHERE user_id=?', [user_id]);
  res.json({ ok: true });
});

app.post('/api/admin/unban', auth, admin, (req, res) => {
  del('UPDATE users SET banned=0, ban_reason=NULL WHERE id=?', [(req.body || {}).user_id]);
  res.json({ ok: true });
});

app.delete('/api/admin/users', auth, admin, (req, res) => {
  const { user_id } = req.body || {};
  if (user_id === req.user.id) return res.status(400).json({ error: 'No' });
  if (!one('SELECT id FROM users WHERE id=?', [user_id])) return res.status(404).json({ error: 'Not found' });
  q('SELECT file FROM photos WHERE user_id=?', [user_id]).forEach(p => {
    try { if (p.file && fs.existsSync(p.file)) fs.unlinkSync(p.file); } catch (e) { /* noop */ }
  });
  const av = one('SELECT avatar FROM users WHERE id=?', [user_id]);
  if (av && av.avatar) { try { if (fs.existsSync(av.avatar)) fs.unlinkSync(av.avatar); } catch (e) { /* noop */ } }
  del('DELETE FROM photos WHERE user_id=?', [user_id]);
  del('DELETE FROM devices WHERE user_id=?', [user_id]);
  del('DELETE FROM codes WHERE user_id=?', [user_id]);
  del('DELETE FROM sessions WHERE user_id=?', [user_id]);
  del('DELETE FROM users WHERE id=?', [user_id]);
  res.json({ ok: true });
});

app.use(express.static(path.join(__dirname, 'public')));
app.get('/', (req, res) => { res.sendFile(path.join(__dirname, 'public', 'index.html')); });

(async () => {
  const SQL = await initSqlJs();
  if (fs.existsSync(DBFILE)) db = new SQL.Database(fs.readFileSync(DBFILE));
  else db = new SQL.Database();
  db.exec(`
CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT UNIQUE, email TEXT UNIQUE, pass TEXT, avatar TEXT, totp TEXT, totp_on INTEGER DEFAULT 0, banned INTEGER DEFAULT 0, ban_reason TEXT, is_admin INTEGER DEFAULT 0, created INTEGER);
CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, user_id INTEGER, expires INTEGER, pending INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS codes (code TEXT PRIMARY KEY, user_id INTEGER, created INTEGER);
CREATE TABLE IF NOT EXISTS devices (token TEXT PRIMARY KEY, user_id INTEGER, name TEXT, model TEXT, linked INTEGER);
CREATE TABLE IF NOT EXISTS photos (id INTEGER PRIMARY KEY, user_id INTEGER, device TEXT, name TEXT, file TEXT, mime TEXT, size INTEGER, taken INTEGER, uploaded INTEGER);
`);
  try { db.exec('ALTER TABLE users ADD COLUMN banned INTEGER DEFAULT 0;'); } catch (e) { /* noop */ }
  try { db.exec('ALTER TABLE users ADD COLUMN ban_reason TEXT;'); } catch (e) { /* noop */ }
  try { db.exec('ALTER TABLE users ADD COLUMN is_admin INTEGER DEFAULT 0;'); } catch (e) { /* noop */ }
  if (process.env.ADMIN_USERNAME) {
    del('UPDATE users SET is_admin=1 WHERE username=?', [process.env.ADMIN_USERNAME]);
  }
  saveDb();
  app.listen(PORT, () => { console.log('DuXK web on ' + PORT); });
})();
