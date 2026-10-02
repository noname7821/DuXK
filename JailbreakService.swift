// Feed sources + loading
import Foundation
import Combine

class JailbreakService: ObservableObject {
    static let shared = JailbreakService()

    @Published var news: [NewsItem] = []
    @Published var firmwares: [FirmwareInfo] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?

    // Remote feed you can update anytime (create this file in your GitHub)
    private let remoteURL = URL(string: "https://raw.githubusercontent.com/duxk40/duxk-feed/main/duxk-feed.json")!

    // Public sources shown in Settings
    let sources: [(name: String, url: String)] = [
        ("Wololo.net", "https://wololo.net"),
        ("PSX-Place", "https://psx-place.com"),
        ("PSXHAX", "https://www.psxhax.com"),
        ("GBATemp PS4 Scene", "https://gbatemp.net/forums/ps4-scene.175/"),
        ("GBATemp PS5 Scene", "https://gbatemp.net/forums/ps5-scene.243/"),
        ("PPPwn (TheOfficialFloW)", "https://github.com/TheOfficialFloW/PPPwn"),
        ("PS5 UMTX / Jailbreak History", "https://github.com/EchoStretch/ps5-umtX"),
        ("PlayStation System Updates PS4", "https://www.playstation.com/en-us/support/hardware/ps4/system-software/"),
        ("PlayStation System Updates PS5", "https://www.playstation.com/en-us/support/hardware/ps5/system-software/")
    ]

    private let seenKey = "duxk.seenIDs"

    init() {
        loadFallback()
    }

    // First load from bundle
    func loadFallback() {
        if let url = Bundle.main.url(forResource: "fallbackNews", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let feed = try? JSONDecoder().decode(Feed.self, from: data) {
            self.news = feed.news.sorted { $0.dateValue > $1.dateValue }
            self.firmwares = feed.firmwares
        } else {
            // Built-in fallback if json missing
            self.news = Self.builtinNews
            self.firmwares = Self.builtinFirmware
        }
    }

    // Fetch remote + notify on new
    func refresh(completion: ((Bool) -> Void)? = nil) {
        isLoading = true
        let task = URLSession.shared.dataTask(with: remoteURL) { data, _, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data,
                      let feed = try? JSONDecoder().decode(Feed.self, from: data) else {
                    completion?(false)
                    return
                }
                self.applyNewFeed(feed)
                completion?(true)
            }
        }
        task.resume()
    }

    // Compare + notify
    func applyNewFeed(_ feed: Feed) {
        let oldIDs = Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? [])
        let sorted = feed.news.sorted { $0.dateValue > $1.dateValue }
        let fresh = sorted.filter { !oldIDs.contains($0.id) && $0.isNew }

        self.news = sorted
        self.firmwares = feed.firmwares
        self.lastUpdated = Date()

        // Save seen
        let allIDs = sorted.map { $0.id }
        UserDefaults.standard.set(allIDs, forKey: seenKey)

        // Notify for each fresh item
        for item in fresh.prefix(3) {
            NotificationManager.shared.notifyNews(item)
        }
    }

    // Mark all as seen (stops "NEW" badge)
    func markAllSeen() {
        let ids = news.map { $0.id }
        UserDefaults.standard.set(ids, forKey: seenKey)
        // Clear flags locally
        for i in news.indices { news[i].isNew = false }
    }

    // Filter helpers
    var jailbreaks: [NewsItem] {
        news.filter { $0.type == .jailbreak || $0.type == .progress }
    }

    var updates: [NewsItem] {
        news.filter { $0.type == .update || $0.type == .patch }
    }

    // Built-in data if no files
    static var builtinNews: [NewsItem] = [
        NewsItem(id: "ps4-1100-pppwn", title: "PS4 11.00 PPPwn Jailbreak Available", body: "PPPwn exploit by TheOfficialFloW supports PS4 on firmware 11.00 and below. Run GoldHEN after exploit for homebrew. Stay on 11.00 or lower, do NOT update if you want homebrew.", date: "2024-05-10T12:00:00Z", type: .jailbreak, console: .ps4, firmware: "11.00", url: "https://github.com/TheOfficialFloW/PPPwn", isNew: true),
        NewsItem(id: "ps4-900-stable", title: "PS4 9.00 Still Most Stable", body: "Firmware 9.00 with pOOBs4 remains the most stable option. If you are on 9.00, stay there. 9.60+ users should wait, no stable port yet.", date: "2024-04-02T12:00:00Z", type: .jailbreak, console: .ps4, firmware: "9.00", url: "https://wololo.net", isNew: false),
        NewsItem(id: "ps5-umtx-761", title: "PS5 UMTX Jailbreak up to 7.61", body: "UMTX kernel exploit chain supports PS5 firmwares up to 7.61 with ItemzFlow / etaHEN. Higher firmwares are patched. Do not update past 7.61.", date: "2025-06-15T12:00:00Z", type: .jailbreak, console: .ps5, firmware: "7.61", url: "https://wololo.net", isNew: true),
        NewsItem(id: "ps5-progress", title: "New PS5 Exploit In Progress", body: "Developers reported progress on a new userland entry point. No release yet. Stay on lowest firmware possible and disable auto-updates.", date: "2025-11-20T12:00:00Z", type: .progress, console: .ps5, firmware: "TBD", url: "https://www.psxhax.com", isNew: true),
        NewsItem(id: "ps4-ofw-new", title: "PS4 System Update Patched Exploit", body: "Latest PS4 system software patches PPPwn. Update notes mention stability and security fixes. If you care about jailbreak, do NOT update.", date: "2025-03-10T12:00:00Z", type: .patch, console: .ps4, firmware: "12.50", url: "https://www.playstation.com/en-us/support/hardware/ps4/system-software/", isNew: false),
        NewsItem(id: "ps5-ofw-new", title: "PS5 System Update Released", body: "Latest PS5 firmware adds features and patches UMTX. Jailbreak users must stay on 7.61 or lower. Details and patch diff in Updates tab.", date: "2025-08-01T12:00:00Z", type: .update, console: .ps5, firmware: "12.00", url: "https://www.playstation.com/en-us/support/hardware/ps5/system-software/", isNew: false)
    ]

    static var builtinFirmware: [FirmwareInfo] = [
        FirmwareInfo(id: "ps4-1250", console: .ps4, version: "12.50", date: "2025-03-10", notes: "Security fixes. Patches PPPwn. No jailbreak. Stay below 11.00 for homebrew.", jailbreakStatus: "Patched - No Jailbreak", isPatched: true),
        FirmwareInfo(id: "ps4-1100", console: .ps4, version: "11.00", date: "2024-04-10", notes: "Last vulnerable to PPPwn. Use PPPwn + GoldHEN.", jailbreakStatus: "Vulnerable - PPPwn", isPatched: false),
        FirmwareInfo(id: "ps4-900", console: .ps4, version: "9.00", date: "2021-09-15", notes: "Most stable. pOOBs4 + GoldHEN. Recommended to stay.", jailbreakStatus: "Vulnerable - Stable", isPatched: false),
        FirmwareInfo(id: "ps5-1200", console: .ps5, version: "12.00", date: "2025-08-01", notes: "Patches UMTX. New features, improved stability.", jailbreakStatus: "Patched - No Jailbreak", isPatched: true),
        FirmwareInfo(id: "ps5-761", console: .ps5, version: "7.61", date: "2024-08-10", notes: "Last version supporting UMTX. Use etaHEN. Disable updates.", jailbreakStatus: "Vulnerable - UMTX", isPatched: false)
    ]
}
