# DuXK 🦆 — PS4 / PS5 Jailbreak Notifier

SwiftUI app, TrollStore-style clean UI, iOS 14.0+ all devices.
All texts in English.

## 1. Create project in Xcode (Mac)

1. Open Xcode → File → New → Project → iOS → App
   - Name: `DuXK`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployments: iOS 14.0
2. Copy all `.swift` files from this folder into the project (drag into Xcode, Copy items).
3. Drag `fallbackNews.json` into project (Copy Bundle Resources).
4. Assets:
   - Save your duck picture as `duck.png`
   - Assets.xcassets → AppIcon → drag duck image into all sizes (1024 for App Store)
   - Assets.xcassets → + New Image Set → name `duck` → add `duck.png` (used for Welcome + Credits circle)
5. Capabilities:
   - Signing & Capabilities → + Background Modes → check `Background fetch` + `Remote notifications`
6. Info.plist — add:
   - `UIBackgroundModes`: fetch, remote-notification
   - `NSUserNotificationUsageDescription` (not needed, but keep)
   - `ITSAppUsesNonExemptEncryption`: NO

## 2. Permissions

App asks for Notification permission after Accept. All jailbreak / update info is also shown inside notifications (title + body).

If user disables: Settings tab → Enable Notifications → Open System Settings.

## 3. How news updates work

`JailbreakService.swift`:
- Loads `fallbackNews.json` first (offline)
- Then fetches remote:
```
https://raw.githubusercontent.com/duxk40/duxk-feed/main/duxk-feed.json
```
Create that repo/file with same format as `fallbackNews.json`. Just edit JSON, app picks it up + sends local notification (`notifyNews`).

Sources already linked in Settings:
Wololo, PSX-Place, PSXHAX, GBATemp, PPPwn GitHub, PlayStation update pages.

To add live RSS later: parse `https://wololo.net/feed/` with XMLParser and map to NewsItem.

## 4. Flow you asked for

- First launch → Welcome popup: Welcome / Thanks for using DuXK / I'm a Duck quack quack / info text / disclaimer / Accept & Continue / Decline
- Decline → App Locked screen, not usable, button Review Terms Again
- Accept → MainTabs: Home / Updates / Settings
- Home: `Show Latest Jailbreaks` + `Show Latest System Updates & Patches` + Recent News preview. Tap → detail page (not popup). New items show NEW badge + banner notification.
- Updates tab: Firmware cards (version, patched / jailbreakable) + Patch News
- Settings: Notifications toggle, Read Terms, Credits `duxk40` circle avatar → https://www.tiktok.com/@duxk40?is_from_webapp=1&sender_device=pc with text Our Official TikTok account!, Sources, Version 1.0.0, iOS 14.0+ All devices

## 5. Build IPA (TrollStore / Sideload)

- Xcode → Product → Archive → Distribute → Ad Hoc / Development
- Or use Ksign / TrollStore direct install with bundle id e.g. `com.duxk.app`
- Bundle ID + Team: set in Signing & Capabilities

## 6. Files

- DuXKApp.swift — entry + notification delegate
- ContentView.swift — Accept/Decline routing + TabView
- WelcomeView.swift — popup
- HomeView.swift — home + lists + detail
- UpdatesView.swift — firmware + patches
- SettingsView.swift — notifs, terms, credits, sources
- TermsView.swift — liability text
- Models.swift, JailbreakService.swift, NotificationManager.swift
- fallbackNews.json — offline + example remote format
