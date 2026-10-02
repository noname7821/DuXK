# DuXK

PS4 / PS5 Jailbreak News App. iOS 14.0+. SwiftUI.

## Xcode Setup

1. Xcode -> New -> Project -> iOS -> App
   - Name: `DuXK`
   - Interface: SwiftUI
   - Minimum Deployments: iOS 14.0
2. Alle `.swift` Dateien in das Projekt ziehen.
3. `fallbackNews.json` und `duxk-feed.json` als Bundle Resource dazu.
4. Bild:
   - `duck.png` als Image Set `duck` in Assets anlegen
   - AppIcon mit dem Duck Bild füllen
5. Background Modes: `fetch`, `remote-notification`
6. Bundle ID setzen, z.B. `com.duxk.app`

## Mitteilungen

Nach Accept fragt die App nach Mitteilungs-Erlaubnis.
Einstellungen -> Mitteilungen an/aus, System Einstellungen öffnen.

## News Datei

Offline: `fallbackNews.json`
Online: `duxk-feed.json`

URL:
```
https://raw.githubusercontent.com/noname7821/DuXK/main/duxk-feed.json
```

Zum Updaten nur `duxk-feed.json` im Repo ändern und pushen. Format gleich wie `fallbackNews.json`. Neue Einträge mit `"isNew": true` senden eine Mitteilung.

## Struktur

- Home: Jailbreak Liste, Update Liste, Neuigkeiten
- Updates: Firmware Liste, Patch News, Detail Seite
- Einstellungen: Mitteilungen, Terms, Credits, Quellen, Version

## Build

Xcode -> Product -> Archive -> Ad Hoc.
IPA per Sideload installieren.

## Dateien

- DuXKApp.swift
- ContentView.swift
- WelcomeView.swift
- HomeView.swift
- UpdatesView.swift
- SettingsView.swift
- TermsView.swift
- Models.swift
- JailbreakService.swift
- NotificationManager.swift
- fallbackNews.json
- duxk-feed.json
