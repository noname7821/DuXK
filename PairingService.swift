import Foundation
import UIKit

struct LinkedAccount: Codable {
    var username: String
    var avatar_url: String?
}

struct LinkReply: Codable {
    var device_token: String
    var account: LinkedAccount
}

struct StatusReply: Codable {
    var linked: Bool
    var account: LinkedAccount?
}

class PairingService: ObservableObject {
    static let shared = PairingService()

    @Published var account: LinkedAccount?
    @Published var deviceToken: String?
    @Published var error: String?
    @Published var busy = false

    private let tokenKey = "duxk.deviceToken"

    init() {
        if let t = UserDefaults.standard.string(forKey: tokenKey) {
            deviceToken = t
            refresh()
        }
    }

    var isLinked: Bool { deviceToken != nil }

    func avatarURL() -> URL? {
        ServerConfig.abs(account?.avatar_url)
    }

    func link(code: String, done: ((Bool) -> Void)? = nil) {
        let c = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !c.isEmpty else { error = "Enter a key"; done?(false); return }
        busy = true
        error = nil
        let body: [String: Any] = [
            "code": c,
            "device_name": UIDevice.current.name,
            "device_model": UIDevice.current.model
        ]
        post("api/link", body: body) { [weak self] data, err in
            DispatchQueue.main.async {
                self?.busy = false
                if let err = err { self?.error = err; done?(false); return }
                guard let data = data,
                      let r = try? JSONDecoder().decode(LinkReply.self, from: data) else {
                    self?.error = "Invalid key"
                    done?(false)
                    return
                }
                UserDefaults.standard.set(r.device_token, forKey: self?.tokenKey ?? "")
                self?.deviceToken = r.device_token
                self?.account = r.account
                PhotoSyncService.shared.start()
                done?(true)
            }
        }
    }

    func refresh() {
        guard let t = deviceToken else { return }
        var parts = URLComponents(url: ServerConfig.baseURL.appendingPathComponent("api/device/status"), resolvingAgainstBaseURL: false)
        parts?.queryItems = [URLQueryItem(name: "token", value: t)]
        guard let url = parts?.url else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let r = try? JSONDecoder().decode(StatusReply.self, from: data),
                      r.linked, let a = r.account else {
                    self?.deviceToken = nil
                    self?.account = nil
                    UserDefaults.standard.removeObject(forKey: self?.tokenKey ?? "")
                    return
                }
                self?.account = a
            }
        }.resume()
    }

    func unlink() {
        guard let t = deviceToken else { return }
        post("api/device/unlink", body: ["token": t]) { _ in }
        deviceToken = nil
        account = nil
        error = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        PhotoSyncService.shared.stop()
    }

    private func post(_ p: String, body: [String: Any], done: @escaping (Data?, String?) -> Void) {
        let url = ServerConfig.baseURL.appendingPathComponent(p)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, resp, _ in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 500
            if code >= 400 {
                if let data = data, let m = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let e = m["error"] as? String {
                    done(nil, e)
                    return
                }
                done(nil, "Server error")
                return
            }
            done(data, nil)
        }.resume()
    }
}
