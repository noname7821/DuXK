import SwiftUI
import UIKit

/// App-Avatar (Ente). `duck.jpg` liegt als Bundle-Resource bei,
/// kein Asset-Katalog noetig. Nur falls die Datei fehlt, neutraler Fallback.
struct DuckAvatar: View {
    var size: CGFloat = 56
    var cornerRadius: CGFloat? = nil

    static func hasDuckAsset() -> Bool {
        UIImage(named: "duck") != nil
    }

    var body: some View {
        Group {
            if Self.hasDuckAsset() {
                Image("duck")
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
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.25))
    }
}
