import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var granted = false

    func setup() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async {
                self.granted = (s.authorizationStatus == .authorized)
            }
        }
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
            DispatchQueue.main.async {
                self.granted = ok
                completion?(ok)
            }
            if ok {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func notifyNews(_ item: NewsItem) {
        let content = UNMutableNotificationContent()
        content.title = item.type.rawValue + " • " + item.console.rawValue + " " + item.firmware
        content.body = item.title + " — " + item.body
        content.sound = .default
        content.userInfo = ["id": item.id, "url": item.url]

        let req = UNNotificationRequest(identifier: item.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, completionHandler: nil)
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
