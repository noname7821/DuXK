import Foundation

struct ServerConfig {
    static let baseURL = URL(string: "https://duxk-web.onrender.com")!

    static func abs(_ p: String?) -> URL? {
        guard let p = p else { return nil }
        if p.hasPrefix("http") { return URL(string: p) }
        return URL(string: p, relativeTo: baseURL)
    }
}
