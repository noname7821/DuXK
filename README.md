# DuXK

PS4 / PS5 Jailbreak News App + Foto Sync. iOS 14.0+. SwiftUI.

## App

Tabs: Setup + Settings.

Setup: 10-Zeichen Key von der Website eingeben. Bei gültigem Key zeigt die App
All Set + verbundenen Account (Name + Bild). Fotos laden dann auf die Website.
Unlink trennt die Verbindung.

Server URL steht in `Config.swift`. Nach Render Deploy dort eintragen.

## Website (Render)

Ordner `web/`. Node 20+. Start: `npm install --prefix web`, `npm start --prefix web`.
Daten liegen in `STORAGE_DIR` (Render Disk `/data`).

Ablauf:
1. Auf Render: New -> Blueprint -> dieses Repo wählen (`render.yaml`).
2. Disk `duxk-data` wird angelegt.
3. URL aus Render in `Config.swift` eintragen, pushen, IPA aus Actions laden.

Website: Register/Login (Name oder Email, Email optional), Login bleibt gespeichert,
2-step per Authenticator App (an/aus, Email nur mit 2-step ändern, Passwort ändern,
Name ändern, Bild ändern). Oben rechts Bild + Name, Menü Settings + Logout.
Keys erstellen (10 Zeichen), Regenerate, Löschen. Geräte entfernen.
Galerie: Stack, anklicken, links/rechts, einzeln laden, mehrere oder alle als ZIP laden.

## Xcode Setup

Projekt liegt bei (`DuXK.xcodeproj`). Bundle ID z.B. `com.duxk.app`.
Foto Zugriff Text steht in `Info.plist`.

## Build

Bei jedem Push baut Actions ein unsigned IPA (Artifacts).
Installieren per TrollStore oder erst mit Ksign signieren.
