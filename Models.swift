import Foundation

enum ConsoleType: String, Codable, CaseIterable {
    case ps4 = "PS4"
    case ps5 = "PS5"
    case both = "PS4 & PS5"
}

enum NewsType: String, Codable {
    case jailbreak = "Jailbreak"
    case update = "System Update"
    case patch = "Patch"
    case progress = "In Progress"
}

struct NewsItem: Identifiable, Codable {
    var id: String
    var title: String
    var body: String
    var date: String
    var type: NewsType
    var console: ConsoleType
    var firmware: String
    var url: String
    var isNew: Bool

    var dateValue: Date {
        let f = ISO8601DateFormatter()
        return f.date(from: date) ?? Date.distantPast
    }
}

struct FirmwareInfo: Identifiable, Codable {
    var id: String
    var console: ConsoleType
    var version: String
    var date: String
    var notes: String
    var jailbreakStatus: String
    var isPatched: Bool
}

struct Feed: Codable {
    var news: [NewsItem]
    var firmwares: [FirmwareInfo]
}
