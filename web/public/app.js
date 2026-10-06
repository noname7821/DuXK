let ME = null;
let PHOTOS = [];
let SEL = new Set();
let LIGHT = -1;
let TMP2FA = null;

async function api(path, opt) {
  opt = opt || {};
  opt.headers = opt.headers || {};
  if (opt.body && typeof opt.body === 'object' && !(opt.body instanceof FormData)) {
    opt.headers['Content-Type'] = 'application/json';
    opt.body = JSON.stringify(opt.body);
  }
  const r = await fetch(path, opt);
  const t = await r.text();
  let j = {};
  try { j = JSON.parse(t); } catch (e) { j = { error: 'Server error' }; }
  if (!r.ok) throw new Error(j.error || ('Error ' + r.status));
  return j;
}

function showAuth(which) {
  document.getElementById('form-login').classList.toggle('hidden', which !== 'login');
  document.getElementById('form-register').classList.toggle('hidden', which !== 'register');
  document.getElementById('tab-login').classList.toggle('on', which === 'login');
  document.getElementById('tab-register').classList.toggle('on', which === 'register');
}

async function boot() {
  try {
    const j = await api('/api/me');
    enter(j.user);
  } catch (e) {
    document.getElementById('view-auth').classList.remove('hidden');
  }
}

function enter(u) {
  ME = u;
  document.getElementById('view-auth').classList.add('hidden');
  document.getElementById('view-app').classList.remove('hidden');
  document.getElementById('pf-name').textContent = u.username;
  const img = document.getElementById('pf-img');
  if (u.avatar_url) { img.src = u.avatar_url; img.classList.remove('hidden'); document.getElementById('pf-duck').classList.add('hidden'); }
  else { img.classList.add('hidden'); document.getElementById('pf-duck').classList.remove('hidden'); }
  go('home');
  loadAll();
}

async function doRegister() {
  const err = document.getElementById('auth-err');
  err.textContent = '';
  try {
    const j = await api('/api/auth/register', { method: 'POST', body: {
      username: document.getElementById('rg-name').value.trim(),
      email: document.getElementById('rg-mail').value.trim(),
      password: document.getElementById('rg-pass').value
    }});
    enter(j.user);
  } catch (e) { err.textContent = e.message; }
}

async function doLogin() {
  const err = document.getElementById('auth-err');
  err.textContent = '';
  const box = document.getElementById('li-2fa');
  try {
    if (!box.classList.contains('hidden')) {
      const j = await api('/api/auth/verify', { method: 'POST', body: { tmp: TMP2FA, code: document.getElementById('li-code').value.trim() } });
      box.classList.add('hidden');
      enter(j.user);
      return;
    }
    const j = await api('/api/auth/login', { method: 'POST', body: {
      login: document.getElementById('li-login').value.trim(),
      password: document.getElementById('li-pass').value
    }});
    if (j.need2fa) { TMP2FA = j.tmp; box.classList.remove('hidden'); err.textContent = 'Enter your 2-step code'; return; }
    enter(j.user);
  } catch (e) { err.textContent = e.message; }
}

async function doLogout() {
  await api('/api/auth/logout', { method: 'POST' }).catch(() => {});
  location.reload();
}

function go(v) {
  document.getElementById('view-home').classList.toggle('hidden', v !== 'home');
  document.getElementById('view-settings').classList.toggle('hidden', v !== 'settings');
  if (v === 'settings') loadSettings();
}

async function loadAll() {
  await loadCodes();
  await loadPhotos();
}

async function loadCodes() {
  const j = await api('/api/codes').catch(() => null);
  if (!j) return;
  const cl = document.getElementById('code-list');
  cl.innerHTML = '';
  j.codes.forEach(c => {
    const d = document.createElement('div');
    d.className = 'code';
    d.innerHTML = '<span></span><button>Copy</button><button>Regenerate</button><button>Delete</button>';
    d.children[0].textContent = c.code;
    d.children[1].onclick = () => { navigator.clipboard.writeText(c.code); };
    d.children[2].onclick = async () => { const r = await api('/api/codes/regenerate', { method: 'POST', body: { code: c.code } }); alert('New key: ' + r.code); loadCodes(); };
    d.children[3].onclick = async () => { await api('/api/codes', { method: 'DELETE', body: { code: c.code } }); loadCodes(); };
    cl.appendChild(d);
  });
  const dl = document.getElementById('dev-list');
  dl.innerHTML = '';
  if (!j.devices.length) dl.innerHTML = '<p class="hint">No phone linked. Enter a key in the app.</p>';
  j.devices.forEach(v => {
    const d = document.createElement('div');
    d.className = 'dev';
    const av = ME.avatar_url ? '<img src="' + ME.avatar_url + '">' : '<span style="font-size:30px">🦆</span>';
    d.innerHTML = av + '<div class="who"><b></b><span></span></div><button>Remove</button>';
    d.querySelector('b').textContent = 'Connected with ' + ME.username;
    d.querySelector('span').textContent = v.name + (v.model ? ' • ' + v.model : '');
    d.querySelector('button').onclick = async () => { await api('/api/devices', { method: 'DELETE', body: { token: v.token } }); loadCodes(); };
    dl.appendChild(d);
  });
}

async function newCode() {
  const j = await api('/api/codes', { method: 'POST' });
  alert('New key: ' + j.code);
  loadCodes();
}

async function loadPhotos() {
  const j = await api('/api/photos?limit=500').catch(() => null);
  if (!j) return;
  PHOTOS = j.photos;
  SEL = new Set();
  document.getElementById('ph-count').textContent = '(' + j.total + ')';
  const g = document.getElementById('grid');
  g.innerHTML = '';
  PHOTOS.forEach((p, i) => {
    const c = document.createElement('div');
    c.className = 'cell';
    c.innerHTML = '<img loading="lazy"><div class="tick">✓</div>';
    c.children[0].src = p.url;
    c.onclick = (e) => {
      if (e.target.className === 'tick') { toggle(i); return; }
      openLight(i);
    };
    c.children[1].onclick = () => toggle(i);
    g.appendChild(c);
  });
}

function paint() {
  const g = document.getElementById('grid').children;
  for (let i = 0; i < g.length; i++) g[i].classList.toggle('sel', SEL.has(PHOTOS[i].id));
}

function toggle(i) {
  const id = PHOTOS[i].id;
  if (SEL.has(id)) SEL.delete(id); else SEL.add(id);
  paint();
}

function selAll(on) {
  SEL = new Set();
  if (on) PHOTOS.forEach(p => SEL.add(p.id));
  paint();
}

function openLight(i) {
  LIGHT = i;
  showLight();
  document.getElementById('light').classList.remove('hidden');
}

function showLight() {
  const p = PHOTOS[LIGHT];
  document.getElementById('light-img').src = p.url;
  document.getElementById('light-dl').onclick = () => { window.location = '/api/photos/' + p.id + '/file?download=1'; };
}

function navLight(d) {
  LIGHT = (LIGHT + d + PHOTOS.length) % PHOTOS.length;
  showLight();
}

function closeLight() {
  document.getElementById('light').classList.add('hidden');
}

async function dlSelected() {
  if (!SEL.size) return alert('Select photos first');
  const r = await fetch('/api/photos/zip', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ids: [...SEL] }) });
  if (!r.ok) return alert('Download failed');
  saveBlob(await r.blob(), 'duxk-photos.zip');
}

async function dlAll() {
  if (!PHOTOS.length) return alert('No photos');
  const r = await fetch('/api/photos/zip', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ all: true }) });
  if (!r.ok) return alert('Download failed');
  saveBlob(await r.blob(), 'duxk-photos.zip');
}

function saveBlob(b, name) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(b);
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 5000);
}

async function loadSettings() {
  const j = await api('/api/me');
  ME = j.user;
  document.getElementById('set-name').value = ME.username;
  document.getElementById('set-mail').value = ME.email || '';
  const img = document.getElementById('set-img');
  if (ME.avatar_url) { img.src = ME.avatar_url; img.classList.remove('hidden'); document.getElementById('set-duck').classList.add('hidden'); }
  else { img.classList.add('hidden'); document.getElementById('set-duck').classList.remove('hidden'); }
  document.getElementById('tfa-off').classList.toggle('hidden', ME.totp_on);
  document.getElementById('tfa-onc').classList.toggle('hidden', !ME.totp_on);
  document.getElementById('mail-2fa-row').classList.toggle('hidden', !ME.totp_on);
}

async function saveName() {
  const err = document.getElementById('set-err');
  err.textContent = '';
  try {
    const j = await api('/api/me', { method: 'PUT', body: { username: document.getElementById('set-name').value.trim() } });
    enter(j.user); go('settings');
  } catch (e) { err.textContent = e.message; }
}

async function saveMail() {
  const err = document.getElementById('set-err');
  err.textContent = '';
  try {
    const j = await api('/api/me/email', { method: 'PUT', body: {
      email: document.getElementById('set-mail').value.trim(),
      code: document.getElementById('set-mail-code').value.trim()
    }});
    enter(j.user); go('settings');
  } catch (e) { err.textContent = e.message; }
}

async function savePw() {
  const err = document.getElementById('set-err');
  err.textContent = '';
  try {
    await api('/api/me/password', { method: 'PUT', body: {
      current: document.getElementById('pw-cur').value,
      next: document.getElementById('pw-new').value
    }});
    document.getElementById('pw-cur').value = '';
    document.getElementById('pw-new').value = '';
    err.textContent = 'Password changed';
  } catch (e) { err.textContent = e.message; }
}

async function upAvatar() {
  const err = document.getElementById('set-err');
  err.textContent = '';
  const f = document.getElementById('set-file').files[0];
  if (!f) { err.textContent = 'Pick a picture first'; return; }
  const fd = new FormData();
  fd.append('avatar', f);
  try {
    const r = await fetch('/api/me/avatar', { method: 'POST', body: fd });
    const j = await r.json();
    if (!r.ok) throw new Error(j.error || 'Error');
    enter(j.user); go('settings');
  } catch (e) { err.textContent = e.message; }
}

async function tfaSetup() {
  const j = await api('/api/2fa/setup');
  document.getElementById('tfa-qr').src = j.qr;
  document.getElementById('tfa-setup').classList.remove('hidden');
  document.getElementById('tfa-start').classList.add('hidden');
}

async function tfaOn() {
  const err = document.getElementById('set-err');
  err.textContent = '';
  try {
    const j = await api('/api/2fa/enable', { method: 'POST', body: { code: document.getElementById('tfa-code').value.trim() } });
    enter(j.user); go('settings');
  } catch (e) { err.textContent = e.message; }
}

async function tfaOff() {
  const err = document.getElementById('set-err');
  err.textContent = '';
  try {
    const j = await api('/api/2fa/disable', { method: 'POST', body: { password: document.getElementById('tfa-pw').value } });
    enter(j.user); go('settings');
  } catch (e) { err.textContent = e.message; }
}

document.addEventListener('keydown', (e) => {
  if (document.getElementById('light').classList.contains('hidden')) return;
  if (e.key === 'Escape') closeLight();
  if (e.key === 'ArrowLeft') navLight(-1);
  if (e.key === 'ArrowRight') navLight(1);
});

boot();
