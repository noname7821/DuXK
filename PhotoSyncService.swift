import Foundation
import Photos
import UIKit

class PhotoSyncService: ObservableObject {
    static let shared = PhotoSyncService()

    @Published var info = "Not started"
    @Published var uploading = false
    @Published var done = 0
    @Published var total = 0

    private let idsKey = "duxk.uploadedIDs"
    private var stopFlag = false

    var uploadedIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: idsKey) ?? [])
    }

    func remember(_ id: String) {
        var a = UserDefaults.standard.stringArray(forKey: idsKey) ?? []
        if !a.contains(id) {
            a.append(id)
            UserDefaults.standard.set(a, forKey: idsKey)
        }
    }

    func start() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] s in
            DispatchQueue.main.async {
                if s == .authorized || s == .limited {
                    self?.sync()
                } else {
                    self?.info = "Photo access denied. Allow access in Settings."
                }
            }
        }
    }

    func stop() {
        stopFlag = true
        uploading = false
        info = "Stopped"
    }

    func sync() {
        guard !uploading else { return }
        guard let token = PairingService.shared.deviceToken else { info = "Link a key first"; return }
        stopFlag = false
        uploading = true
        info = "Reading photos"
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let opts = PHFetchOptions()
            opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let all = PHAsset.fetchAssets(with: opts)
            var ids: [String] = []
            let known = self.uploadedIDs
            all.enumerateObjects { a, _, _ in
                if !known.contains(a.localIdentifier) { ids.append(a.localIdentifier) }
            }
            let byId = Dictionary(uniqueKeysWithValues: all.objects(at: IndexSet(integersIn: 0..<all.count)).map { ($0.localIdentifier, $0) })
            DispatchQueue.main.async {
                self.total = ids.count
                self.done = 0
                self.info = ids.isEmpty ? "All Set. Nothing new." : "Uploading"
            }
            self.pushNext(ids: ids, byId: byId, token: token, idx: 0)
        }
    }

    private func pushNext(ids: [String], byId: [String: PHAsset], token: String, idx: Int) {
        if stopFlag || idx >= ids.count {
            DispatchQueue.main.async { [weak self] in
                self?.uploading = false
                if !(self?.stopFlag ?? true) { self?.info = "All Set" }
            }
            return
        }
        guard let asset = byId[ids[idx]] else {
            pushNext(ids: ids, byId: byId, token: token, idx: idx + 1)
            return
        }
        let ro = PHImageRequestOptions()
        ro.isNetworkAccessAllowed = true
        ro.deliveryMode = .highQualityFormat
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: ro) { [weak self] data, _, _, _ in
            guard let self = self, let data = data else {
                self?.pushNext(ids: ids, byId: byId, token: token, idx: idx + 1)
                return
            }
            self.upload(data: data, name: "photo.jpg", token: token) { ok in
                if ok { self.remember(ids[idx]) }
                DispatchQueue.main.async {
                    self.done += 1
                    self.info = "Uploading \(self.done)/\(self.total)"
                }
                self.pushNext(ids: ids, byId: byId, token: token, idx: idx + 1)
            }
        }
    }

    private func upload(data: Data, name: String, token: String, done: @escaping (Bool) -> Void) {
        let url = ServerConfig.baseURL.appendingPathComponent("api/device/photos")
        let b = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(b)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(b)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"token\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(token)\r\n".data(using: .utf8)!)
        body.append("--\(b)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(b)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        URLSession.shared.dataTask(with: req) { d, resp, _ in
            done((resp as? HTTPURLResponse)?.statusCode == 200)
        }.resume()
    }
}
