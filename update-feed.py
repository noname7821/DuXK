#!/usr/bin/env python3
"""DuXK feed auto-updater.

Laeuft als GitHub Action (siehe .github/workflows/update-feed.yml).
- Holt neueste etaHEN-/GoldHEN-Releases ueber die GitHub API.
- Erkennt neue Sony-Firmwares automatisch (PS4: Wikipedia-Infobox,
  PS5: PlayStation-Blog/PSXHAX-RSS als Best-Effort).
- Aktualisiert duxk-feed.json + fallbackNews.json (identisch halten!).
- Sicherheit: OFW nur HOCH, nie runter. Neue OFW immer als gepatcht.
  Vulnerable-Eintraege fasst der Bot nie an (nur manuell).
- Manuelle Konstanten unten sind der Mindeststand (Fallback).

Nur Stdlib: python3 update-feed.py
"""
import json
import re
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent
FEED = str(BASE / "duxk-feed.json")
FALLBACK = str(BASE / "fallbackNews.json")

# --- Manuelle Konstanten: nur bei neuem Sony-OFW aendern ---
PS4_LATEST = {"version": "14.00", "date": "2026-09-16"}
PS4_EXPLOITABLE = {"version": "13.52", "date": "2026-06-17"}
PS5_LATEST = {"version": "14.10 (26.06-14.10.00)", "date": "2026-10-01"}
PS5_STABLE_JB = {"version": "7.61", "date": "2024-08-10"}

UA = {"User-Agent": "DuXK-feed-updater/1.0"}


def gh_latest(repo):
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.load(r)
    except Exception as e:
        print(f"WARN {repo}: {e}")
        return None


def iso(dt_str):
    try:
        return datetime.fromisoformat(dt_str.replace("Z", "+00:00")).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main():
    feed = json.load(open(FEED, encoding="utf-8"))
    by_id = {n["id"]: n for n in feed["news"]}
    changed = []

    etahen = gh_latest("etaHEN/etaHEN")
    if etahen:
        tag = etahen.get("tag_name", "")
        date = iso(etahen.get("published_at", ""))
        e = by_id.get("ps5-ethen-25b")
        if e and tag and tag not in e.get("title", ""):
            e["title"] = f"etaHEN {tag}: Full Support to 8.20, Partial to 10.01"
            e["body"] = (f"{tag} vom {date[:10]}: volle 8.00/8.20 kstuff-Unterstuetzung, "
                         "Toolbox/Cheats fuer 8.40-10.01. UMTX am stabilsten bis 7.61. "
                         "Ueber 10.01: kein Public Jailbreak.")
            e["date"] = date
            e["url"] = etahen.get("html_url", e["url"])
            e["isNew"] = True
            changed.append(f"etaHEN {tag}")

    goldhen = gh_latest("GoldHEN/GoldHEN")
    if goldhen:
        tag = goldhen.get("tag_name", "")
        date = iso(goldhen.get("published_at", ""))
        e = by_id.get("ps4-goldhen")
        if e is None:
            e = {"id": "ps4-goldhen", "title": "", "body": "", "date": date,
                 "type": "Jailbreak", "console": "PS4", "firmware": "9.00",
                 "url": "https://github.com/GoldHEN/GoldHEN/releases", "isNew": True}
            feed["news"].append(e)
            by_id["ps4-goldhen"] = e
        if tag and tag not in e.get("title", ""):
            e["title"] = f"GoldHEN {tag} fuer PS4"
            e["body"] = (f"GoldHEN {tag} vom {date[:10]}: Homebrew Enabler nach Jailbreak "
                         "starten (5.05/6.72/9.00/11.00+, je nach Kette). Details im Release.")
            e["date"] = date
            e["url"] = goldhen.get("html_url", e["url"])
            e["isNew"] = True
            changed.append(f"GoldHEN {tag}")

    pppwn = None
    try:
        req = urllib.request.Request(
            "https://api.github.com/repos/TheOfficialFloW/PPPwn/commits?per_page=1",
            headers=UA,
        )
        with urllib.request.urlopen(req, timeout=20) as r:
            commits = json.load(r)
            if commits:
                pppwn = {"sha": commits[0]["sha"][:7],
                         "date": commits[0]["commit"]["committer"]["date"]}
    except Exception as e:
        print(f"WARN PPPwn commits: {e}")
    # PPPwn ist seit Juni 2024 dormant (letzter Commit fb4ab5f) -> nur bei
    # wirklich neuem Commit anfassen, sonst statisch lassen.
    if pppwn and pppwn["date"] > "2024-06-16T15:57:50Z":
        e = by_id.get("ps4-1100-pppwn")
        if e and pppwn["sha"] not in e.get("body", ""):
            e["body"] += f" (Upstream {pppwn['sha']}, {pppwn['date'][:10]})."
            changed.append(f"PPPwn {pppwn['sha']}")

    # --- Sony-OFW automatisch erkennen (nur hoch, nie runter) ---
    detect_sony_ofw(feed, by_id, changed)

    feed["news"] = sorted(feed["news"], key=lambda n: n["date"], reverse=True)
    out = json.dumps(feed, ensure_ascii=False, indent=2) + "\n"
    open(FEED, "w", encoding="utf-8").write(out)
    open(FALLBACK, "w", encoding="utf-8").write(out)
    print("changed:", changed if changed else "none (feed aktuell)")


def key4(v):
    p = re.findall(r"\d+", v or "")[:2]
    return tuple(int(x) for x in p) if len(p) == 2 else (0, 0)


def key5(v):
    m = re.search(r"(\d+)\.(\d+)-(\d+)\.(\d+)", v or "")
    return tuple(int(x) for x in m.groups()) if m else (0, 0, 0, 0)


def wiki_ps4_latest():
    """PS4-Latest aus Wikipedia-Infobox. Gibt (version, datum|None) oder None."""
    try:
        url = ("https://en.wikipedia.org/w/api.php?action=query&prop=revisions"
               "&rvprop=content&format=json&formatversion=2"
               "&titles=PlayStation_4_system_software")
        req = urllib.request.Request(url, headers={"User-Agent": "DuXK-feed-updater/1.0"})
        with urllib.request.urlopen(req, timeout=20) as r:
            c = json.load(r)["query"]["pages"][0]["revisions"][0]["content"]
        m = re.search(r"latest_release_version\s*=\s*(\d+\.\d+)", c)
        if not m:
            return None
        d = re.search(r"latest_release_date\s*=\s*\{\{[^}]*?(\d{4})\|(\d{1,2})\|(\d{1,2})", c)
        date = f"{d.group(1)}-{int(d.group(2)):02d}-{int(d.group(3)):02d}" if d else None
        return (m.group(1), date)
    except Exception as e:
        print(f"WARN wiki ps4: {e}")
        return None


def rss_ps5_candidates():
    """PS5-Kandidaten aus PlayStation-Blog + PSXHAX RSS.
    Gibt Liste (full, short, datum|None, url). Best-Effort."""
    out = []
    feeds = [
        "https://blog.playstation.com/feed/",
        "https://www.psxhax.com/forums/-/index.rss",
    ]
    for url in feeds:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                xml = r.read().decode("utf-8", "ignore")
        except Exception as e:
            print(f"WARN rss {url}: {e}")
            continue
        for it in re.findall(r"<item>(.*?)</item>", xml, re.DOTALL):
            t = re.sub(r"<!\[CDATA\[|\]\]>", "", re.search(r"<title>(.*?)</title>", it, re.DOTALL).group(1))
            if "ps5" not in t.lower() or "system software" not in t.lower():
                continue
            m = re.search(r"(\d{2}\.\d{2}-\d+\.\d+(?:\.\d+)?)", t)
            if not m:
                continue
            pub = re.search(r"<pubDate>(.*?)</pubDate>", it)
            link = re.search(r"<link>(.*?)</link>", it)
            try:
                dt = datetime.strptime(pub.group(1)[:16], "%a, %d %b %Y").strftime("%Y-%m-%d") if pub else None
            except Exception:
                dt = None
            short = m.group(1).split("-")[1].split(".")[0] + "." + m.group(1).split("-")[1].split(".")[1]
            out.append((m.group(1), short, dt, link.group(1).strip() if link else ""))
    return out


def upsert_ofw_news(by_id, feed, nid, title, body, date_iso, ntype, console, fw, url):
    e = by_id.get(nid)
    if e and e.get("title") == title:
        return False
    if e is None:
        e = {"id": nid, "title": "", "body": "", "date": date_iso, "type": ntype,
             "console": console, "firmware": fw, "url": url, "isNew": True}
        feed["news"].append(e)
        by_id[nid] = e
    e.update({"title": title, "body": body, "date": date_iso, "type": ntype,
              "console": console, "firmware": fw, "url": url, "isNew": True})
    return True


def detect_sony_ofw(feed, by_id, changed):
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    fwmap = {f["id"]: f for f in feed["firmwares"]}

    # PS4: Wikipedia-Infobox, Boden = manuelle Konstante
    cands = [(PS4_LATEST["version"], PS4_LATEST["date"])]
    w = wiki_ps4_latest()
    if w:
        cands.append(w)
    best = max(cands, key=lambda c: key4(c[0]))
    card = fwmap.get("ps4-1400")
    if card and key4(best[0]) > key4(card.get("version", "0.0")):
        v, d = best[0], best[1] or today
        card.update({"version": v, "date": d,
                     "notes": f"Security fixes. Patches jailbreak chains. No jailbreak. Stay on 13.52 or lower.",
                     "jailbreakStatus": "Patched - No Jailbreak", "isPatched": True})
        if upsert_ofw_news(by_id, feed, "ps4-ofw-auto",
                           f"PS4 {v} Released - Do NOT Update",
                           f"PS4 {v} ({d}) patches jailbreak chains. Stay low, disable auto-updates.",
                           f"{d}T12:00:00Z", "Patch", "PS4", v,
                           "https://www.playstation.com/en-us/support/hardware/ps4/system-software/"):
            changed.append(f"PS4 OFW {v} (auto)")

    # PS5: Blog-/Forum-RSS, Boden = manuelle Konstante
    pcands = [(PS5_LATEST["version"], PS5_LATEST["date"], "")]
    for full, short, dt, link in rss_ps5_candidates():
        pcands.append((f"{short} ({full})", dt or today, link))
    best5 = max(pcands, key=lambda c: key5(c[0]))
    card5 = fwmap.get("ps5-1410")
    if card5 and key5(best5[0]) > key5(card5.get("version", "")):
        v, d, link = best5[0], best5[1], best5[2] or "https://www.playstation.com/en-us/support/hardware/ps5/system-software/"
        card5.update({"version": v, "date": d,
                      "notes": "Security fixes. Patches UMTX/etaHEN. No jailbreak. Stay on 7.61 or lower.",
                      "jailbreakStatus": "Patched - No Jailbreak", "isPatched": True})
        short = v.split(" ")[0]
        if upsert_ofw_news(by_id, feed, "ps5-ofw-auto",
                           f"PS5 {v} Released - Do NOT Update",
                           f"PS5 {v} ({d}) with security fixes. Stay on 7.61 or lower for jailbreak.",
                           f"{d}T12:00:00Z", "System Update", "PS5", short, link):
            changed.append(f"PS5 OFW {v} (auto)")


if __name__ == "__main__":
    main()
