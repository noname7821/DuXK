import SwiftUI

struct WelcomeView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Image("duck")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(radius: 8)
                        .padding(.top, 32)

                    Text("Welcome")
                        .font(.title).bold()

                    Text("Thanks for using DuXK.")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
                        Text("I'm a Duck, quack quack!")
                            .font(.body).bold()
                        Text("I will notify you when a new PS4 or PS5 jailbreak is released, is in progress, or when a system update patches something important.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("New jailbreak alerts", systemImage: "bell.badge.fill")
                        Label("Latest firmware + patch notes", systemImage: "arrow.down.circle.fill")
                        Label("Full details inside the app + notifications", systemImage: "app.badge.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)

                    Text("Disclaimer: DuXK and its team only share public news and links. We are not responsible for what you do with your console. Modifying your console may void warranty or violate terms. Use at your own risk.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            VStack(spacing: 10) {
                Button(action: onAccept) {
                    Text("Accept & Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .background(Color(.systemBackground).shadow(radius: 4))
        }
        .background(Color(.systemBackground))
    }
}
