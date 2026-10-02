import Foundation
import Combine
import UIKit

/// Offene Remote-Steuerung, bewusst NICHT versteckt:
/// - version.txt  -> Update-Hinweis (Popup + Settings-Zeile)
/// - shutdown.txt -> "Yes" = ehrlicher Abschalt-Screen + Beenden nach 5s.
/// Kein Fake-404, kein Tarn-Code: Open Source bleibt lesbar.
class RemoteConfig: ObservableObject {
    static let shared = RemoteConfig()

    private let versionURL = URL(string: "https://raw.githubusercontent.com/noname7821/DuXK/refs/heads/main/version.txt")!
    private let shutdownURL = URL(string: "https://raw.githubusercontent.com/noname7821/DuXK/refs/heads/main/shutdown.txt")!
    private let discordURL = URL(string: "https://raw.githubusercontent.com/noname7821/DuXK/refs/heads/main/discord.txt")!
    static let releasesURL = URL(string: "https://github.com/noname7821/DuXK/releases")!
    static let termsURL = URL(string: "https://github.com/noname7821/DuXK/blob/main/TERMS.md")!

    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var shutdownActive = false
    @Published var discordInvite = ""

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1"
    }

    var snoozedVersion: String {
        get { UserDefaults.standard.string(forKey: "duxk.snoozedVersion") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "duxk.snoozedVersion") }
    }

    func check() {
        fetchText(versionURL) { [weak self] remote in
            guard let self = self, let remote = remote else { return }
            let v = remote.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                self.latestVersion = v
                self.updateAvailable = self.isNewer(remote: v, local: self.appVersion)
                    && v != self.snoozedVersion
            }
        }
        fetchText(shutdownURL) { [weak self] remote in
            guard let remote = remote else { return }
            let flag = remote.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if flag == "yes" {
                DispatchQueue.main.async { self?.shutdownActive = true }
            }
        }
        fetchText(discordURL) { [weak self] remote in
            guard let remote = remote else { return }
            let invite = remote.trimmingCharacters(in: .whitespacesAndNewlines)
            guard invite.hasPrefix("https://") else { return }
            DispatchQueue.main.async { self?.discordInvite = invite }
        }
    }

    var hasValidDiscord: Bool {
        discordInvite.hasPrefix("https://")
    }

    func snooze() {
        snoozedVersion = latestVersion
        updateAvailable = false
    }

    func openReleases() {
        UIApplication.shared.open(Self.releasesURL, options: [:], completionHandler: nil)
    }

    private func isNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let a = i < r.count ? r[i] : 0
            let b = i < l.count ? l[i] : 0
            if a != b { return a > b }
        }
        return false
    }

    private func fetchText(_ url: URL, completion: @escaping (String?) -> Void) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        URLSession(configuration: config).dataTask(with: url) { data, _, _ in
            guard let data = data, let s = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            completion(s)
        }.resume()
    }
}
