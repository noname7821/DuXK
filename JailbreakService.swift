import Foundation
import Combine

class JailbreakService: ObservableObject {
    static let shared = JailbreakService()

    @Published var news: [NewsItem] = []
    @Published var firmwares: [FirmwareInfo] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?

    private let remoteURL = URL(string: "https://raw.githubusercontent.com/noname7821/DuXK/main/duxk-feed.json")!

    let sources: [(name: String, url: String)] = [
        ("Wololo.net", "https://wololo.net"),
        ("PSXHAX", "https://www.psxhax.com"),
        ("PSX-Place", "https://psx-place.com"),
        ("GBATemp PS4 Scene", "https://gbatemp.net/forums/ps4-scene.175/"),
        ("GBATemp PS5 Scene", "https://gbatemp.net/forums/ps5-scene.243/"),
        ("PPPwn (TheOfficialFloW)", "https://github.com/TheOfficialFloW/PPPwn"),
        ("PS5 UMTX Jailbreak (PS5Dev)", "https://github.com/PS5Dev/PS5-UMTX-Jailbreak"),
        ("etaHEN Releases", "https://github.com/etaHEN/etaHEN/releases"),
        ("GoldHEN (PS4 HEN)", "https://github.com/GoldHEN/GoldHEN"),
        ("ConsoleMods PS4 Exploit Chart", "https://consolemods.org/wiki/PS4:Exploit_Chart"),
        ("r/ps4homebrew", "https://www.reddit.com/r/ps4homebrew/"),
        ("r/PS5_Jailbreak", "https://www.reddit.com/r/PS5_Jailbreak/"),
        ("PlayStation Blog", "https://blog.playstation.com/"),
        ("PlayStation System Updates PS4", "https://www.playstation.com/en-us/support/hardware/ps4/system-software/"),
        ("PlayStation System Updates PS5", "https://www.playstation.com/en-us/support/hardware/ps5/system-software/")
    ]

    private let seenKey = "duxk.seenIDs"
    private let cacheKey = "duxk.cachedFeed"
    private let lastRefreshKey = "duxk.lastRefresh"
    private let autoInterval: TimeInterval = 6 * 60 * 60
    private var autoTimer: Timer?

    init() {
        loadFallback()
        loadCache()
        startAutoRefresh()
    }

    func loadFallback() {
        if let url = Bundle.main.url(forResource: "fallbackNews", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let feed = try? JSONDecoder().decode(Feed.self, from: data) {
            self.news = feed.news.sorted { $0.dateValue > $1.dateValue }
            self.firmwares = feed.firmwares
        } else {
            self.news = Self.builtinNews
            self.firmwares = Self.builtinFirmware
        }
    }

    func refresh(completion: ((Bool) -> Void)? = nil) {
        refreshForced(true, completion: completion)
    }

    /// Automatisch: nur laden wenn älter als 6h oder noch nie geladen.
    /// `force=true` (Pull-to-Refresh / Button) lädt immer.
    func refreshIfStale(completion: ((Bool) -> Void)? = nil) {
        let last = UserDefaults.standard.double(forKey: lastRefreshKey)
        if last > 0 && Date().timeIntervalSince1970 - last < autoInterval {
            completion?(true)
            return
        }
        refreshForced(false, completion: completion)
    }

    private func refreshForced(_ force: Bool, completion: ((Bool) -> Void)? = nil) {
        if isLoading { completion?(false); return }
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
                self.saveCache(data)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: self.lastRefreshKey)
                completion?(true)
            }
        }
        task.resume()
        _ = force
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshIfStale()
        autoTimer = Timer.scheduledTimer(withTimeInterval: autoInterval, repeats: true) { [weak self] _ in
            self?.refreshIfStale()
        }
    }

    func stopAutoRefresh() {
        autoTimer?.invalidate()
        autoTimer = nil
    }

    private func saveCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let feed = try? JSONDecoder().decode(Feed.self, from: data),
              !feed.news.isEmpty else { return }
        self.news = feed.news.sorted { $0.dateValue > $1.dateValue }
        self.firmwares = feed.firmwares
    }

    func applyNewFeed(_ feed: Feed) {
        let oldIDs = Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? [])
        let sorted = feed.news.sorted { $0.dateValue > $1.dateValue }
        let fresh = sorted.filter { !oldIDs.contains($0.id) && $0.isNew }

        self.news = sorted
        self.firmwares = feed.firmwares
        self.lastUpdated = Date()

        let allIDs = sorted.map { $0.id }
        UserDefaults.standard.set(allIDs, forKey: seenKey)

        for item in fresh.prefix(3) {
            NotificationManager.shared.notifyNews(item)
        }
    }

    func markAllSeen() {
        let ids = news.map { $0.id }
        UserDefaults.standard.set(ids, forKey: seenKey)
        for i in news.indices { news[i].isNew = false }
    }

    var jailbreaks: [NewsItem] {
        news.filter { $0.type == .jailbreak || $0.type == .progress }
    }

    var updates: [NewsItem] {
        news.filter { $0.type == .update || $0.type == .patch }
    }

    static var builtinNews: [NewsItem] = [
        NewsItem(id: "ps5-1410-update", title: "PS5 26.06-14.10.00 Released Oct 1 2026 - Do NOT Update", body: "Sony pushed PS5 26.06-14.10.00 on Oct 1 2026 with security fixes. It patches UMTX/etaHEN chains. Stay on 7.61 or lower for stable jailbreak, newer 8.xx-10.xx only partial toolbox/cheats support.", date: "2026-10-01T12:00:00Z", type: .update, console: .ps5, firmware: "14.10", url: "https://www.playstation.com/en-us/support/hardware/ps5/system-software/", isNew: true),
        NewsItem(id: "ps4-1400-patch", title: "PS4 14.00 Released Sept 16 2026 - Do NOT Update", body: "PS4 14.00 is out since Sept 16 2026 and patches the 13.52 chain. If you want homebrew, stay on 13.52 or lower. Updating kills GoldHEN.", date: "2026-09-16T12:00:00Z", type: .patch, console: .ps4, firmware: "14.00", url: "https://www.playstation.com/en-us/support/hardware/ps4/system-software/", isNew: true),
        NewsItem(id: "ps4-1352-jb", title: "PS4 13.52 Is Latest Exploitable (Sept 2026)", body: "As of Sept 20 2026 ConsoleMods lists 13.52 as latest publicly exploitable PS4 firmware with GoldHEN. 14.00 is patched. Stay on 13.52 or lower, disable auto-updates.", date: "2026-09-20T12:00:00Z", type: .jailbreak, console: .ps4, firmware: "13.52", url: "https://consolemods.org/wiki/PS4:Exploit_Chart", isNew: true),
        NewsItem(id: "ps5-ethen-25b", title: "etaHEN 2.5B: Full Support to 8.20, Partial to 10.01", body: "etaHEN 2.5B adds full 8.00/8.20 kstuff support, toolbox/cheats for 8.40-10.01. UMTX chain stays most stable on 7.61 and below. Higher than 10.01: no public jailbreak.", date: "2025-12-25T12:00:00Z", type: .jailbreak, console: .ps5, firmware: "7.61-10.01", url: "https://github.com/etaHEN/etaHEN/releases", isNew: false),
        NewsItem(id: "ps4-1100-pppwn", title: "PS4 11.00 PPPwn Jailbreak Available", body: "PPPwn exploit by TheOfficialFloW supports PS4 on firmware 11.00 and below. Run GoldHEN after exploit for homebrew. Stay on 11.00 or lower, do NOT update if you want homebrew.", date: "2024-05-10T12:00:00Z", type: .jailbreak, console: .ps4, firmware: "11.00", url: "https://github.com/TheOfficialFloW/PPPwn", isNew: false),
        NewsItem(id: "ps5-umtx-761", title: "PS5 UMTX Stable up to 7.61", body: "UMTX kernel exploit chain is most stable up to PS5 7.61 with ItemzFlow / etaHEN. Newer firmwares have only partial support. Do not update past 7.61 for full jailbreak.", date: "2025-06-15T12:00:00Z", type: .jailbreak, console: .ps5, firmware: "7.61", url: "https://github.com/PS5Dev/PS5-UMTX-Jailbreak", isNew: false)
    ]

    static var builtinFirmware: [FirmwareInfo] = [
        FirmwareInfo(id: "ps5-1410", console: .ps5, version: "14.10 (26.06-14.10.00)", date: "2026-10-01", notes: "Security fixes Oct 2026. Patches UMTX/etaHEN. No jailbreak. Stay on 7.61 or lower.", jailbreakStatus: "Patched - No Jailbreak", isPatched: true),
        FirmwareInfo(id: "ps4-1400", console: .ps4, version: "14.00", date: "2026-09-16", notes: "Patches 13.52 chain. No jailbreak. Stay on 13.52 or lower for homebrew.", jailbreakStatus: "Patched - No Jailbreak", isPatched: true),
        FirmwareInfo(id: "ps4-1352", console: .ps4, version: "13.52", date: "2026-06-17", notes: "Latest exploitable as of Sept 2026. Use GoldHEN. Disable updates, do NOT go to 14.00.", jailbreakStatus: "Vulnerable - GoldHEN", isPatched: false),
        FirmwareInfo(id: "ps4-1100", console: .ps4, version: "11.00", date: "2024-04-10", notes: "Legacy PPPwn entry point. Use PPPwn + GoldHEN. 13.52 chain is newer if you are already higher.", jailbreakStatus: "Vulnerable - PPPwn", isPatched: false),
        FirmwareInfo(id: "ps5-761", console: .ps5, version: "7.61", date: "2024-08-10", notes: "Last fully stable UMTX version. Use etaHEN. Disable updates.", jailbreakStatus: "Vulnerable - UMTX", isPatched: false)
    ]
}
