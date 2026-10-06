import SwiftUI
import UIKit

struct SetupView: View {
    @StateObject private var pairing = PairingService.shared
    @StateObject private var sync = PhotoSyncService.shared
    @State private var code = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if pairing.isLinked {
                        linkedBox
                    } else {
                        linkBox
                    }
                }
                .padding()
            }
            .navigationTitle("Setup")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    var linkBox: some View {
        VStack(spacing: 14) {
            DuckAvatar(size: 90, cornerRadius: 22)
                .shadow(radius: 8)
            Text("Link your account")
                .font(.title2).bold()
            Text("Create a key on the website, then enter it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextField("10 character key", text: $code)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
            Button(action: { pairing.link(code: code) { ok in if ok { code = "" } } }) {
                Text(pairing.busy ? "Checking" : "Link")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(pairing.busy)
            if let e = pairing.error {
                Text(e)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            Text("Pls do not enter random keys. Your photos will be shown to the person that created the key.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    var linkedBox: some View {
        VStack(spacing: 14) {
            RemoteAvatar(url: pairing.avatarURL(), size: 90)
                .shadow(radius: 8)
            Text("All Set")
                .font(.title2).bold()
            if let a = pairing.account {
                Text("Connected with \(a.username)")
                    .font(.headline)
            }
            Text(UIDevice.current.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            VStack(spacing: 6) {
                Text(sync.info)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if sync.total > 0 {
                    Text("\(sync.done) / \(sync.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Button(action: { sync.sync() }) {
                Text(sync.uploading ? "Uploading" : "Upload now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(sync.uploading)
            Button(action: { pairing.unlink() }) {
                Text("Unlink")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
    }
}

struct RemoteAvatar: View {
    var url: URL?
    var size: CGFloat = 90
    @State private var img: UIImage?

    var body: some View {
        Group {
            if let img = img {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.yellow.opacity(0.2)
                    Text("🦆")
                        .font(.system(size: size * 0.55))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear(perform: load)
    }

    func load() {
        guard let url = url else { return }
        URLSession.shared.dataTask(with: url) { d, _, _ in
            if let d = d, let i = UIImage(data: d) {
                DispatchQueue.main.async { img = i }
            }
        }.resume()
    }
}
