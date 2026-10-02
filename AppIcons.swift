import SwiftUI
import UIKit

/// Zentrales Icon-Handling ohne harte Asset-Abhängigkeit.
/// Wenn `duck.png` als Image Set `duck` in Assets existiert, wird es benutzt,
/// sonst gibt es einen SF-Symbol-Fallback (kein leeres Bild mehr).
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
                // Fallback: Ente als SF Symbol, funktioniert immer
                ZStack {
                    Color.blue.opacity(0.15)
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.25))
    }
}

/// Eigenes TikTok-Icon für Credits — bewusst NICHT das App-/Duck-Icon.
/// Schwarzer Kreis + weiße Note, sieht wie TikTok aus ohne Asset-Datei.
struct TikTokIcon: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: size, height: size)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
