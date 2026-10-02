#!/usr/bin/env python3
"""DuXK feed auto-updater.

Laeuft als GitHub Action (siehe .github/workflows/update-feed.yml).
- Holt neueste etaHEN- + PPPwn-Releases ueber die GitHub API (kein Token noetig).
- Aktualisiert duxk-feed.json + fallbackNews.json (identisch halten!).
- OFW-Versionen (Sony) stehen unten als Konstanten: nur bei neuem
  Sony-Update einmalig hochsetzen, Rest geht automatisch.

Nur Stdlib: python3 update-feed.py
"""
import json
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

    # OFW-Karten synchron zu den Konstanten halten (kein Scraping, kein Raten)
    for f in feed["firmwares"]:
        if f["id"] == "ps4-1400":
            f["version"], f["date"] = PS4_LATEST["version"], PS4_LATEST["date"]
        elif f["id"] == "ps4-1352":
            f["version"], f["date"] = PS4_EXPLOITABLE["version"], PS4_EXPLOITABLE["date"]
        elif f["id"] == "ps5-1410":
            f["version"], f["date"] = PS5_LATEST["version"], PS5_LATEST["date"]
        elif f["id"] == "ps5-761":
            f["version"], f["date"] = PS5_STABLE_JB["version"], PS5_STABLE_JB["date"]

    feed["news"] = sorted(feed["news"], key=lambda n: n["date"], reverse=True)
    out = json.dumps(feed, ensure_ascii=False, indent=2) + "\n"
    open(FEED, "w", encoding="utf-8").write(out)
    open(FALLBACK, "w", encoding="utf-8").write(out)
    print("changed:", changed if changed else "none (feed aktuell)")


if __name__ == "__main__":
    main()
