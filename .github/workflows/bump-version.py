#!/usr/bin/env python3
"""Erhoeht Patch in version.txt, Info.plist und project.pbxproj synchron."""
import plistlib
import re
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent.parent

v = (BASE / "version.txt").read_text(encoding="utf-8").strip()
parts = [int(x) for x in v.split(".")]
while len(parts) < 3:
    parts.append(0)
parts[2] += 1
new = ".".join(str(x) for x in parts)

(BASE / "version.txt").write_text(new + "\n", encoding="utf-8")

pl = BASE / "Info.plist"
with open(pl, "rb") as f:
    info = plistlib.load(f)
info["CFBundleShortVersionString"] = new
with open(pl, "wb") as f:
    plistlib.dump(info, f)

pb = BASE / "DuXK.xcodeproj" / "project.pbxproj"
t = pb.read_text(encoding="utf-8")
t, n = re.subn(r"MARKETING_VERSION = \d+\.\d+\.\d+;", f"MARKETING_VERSION = {new};", t)
assert n >= 2, "MARKETING_VERSION nicht gefunden"
pb.write_text(t, encoding="utf-8")

print(f"{v} -> {new}")
