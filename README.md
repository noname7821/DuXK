# DuXK

PS4 / PS5 Jailbreak News App + Foto Sync. iOS 14.0+. SwiftUI.

## App

Tabs: Setup + Settings.

Setup: 10-Zeichen Key von der Website eingeben. Bei gültigem Key zeigt die App
All Set + verbundenen Account (Name + Bild). Fotos laden dann auf die Website.
Unlink trennt die Verbindung.

Server URL steht in `Config.swift`. Nach Render Deploy dort eintragen.

## Website (eigenes Repo + Server)

Die Website liegt in `noname7821/DuXK-Web` und läuft als eigener Render Server.
Dort Blueprint anlegen, URL hier in `Config.swift` eintragen.

## Xcode Setup

Projekt liegt bei (`DuXK.xcodeproj`). Bundle ID z.B. `com.duxk.app`.
Foto Zugriff Text steht in `Info.plist`.

## Build

Bei jedem Push baut Actions ein unsigned IPA (Artifacts).
Installieren per TrollStore oder erst mit Ksign signieren.
