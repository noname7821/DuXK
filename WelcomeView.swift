import SwiftUI

struct WelcomeView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    @State private var canAccept = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    DuckAvatar(size: 110, cornerRadius: 26)
                        .shadow(radius: 8)
                        .padding(.top, 32)

                    Text("Welcome to DuXK")
                        .font(.system(size: 28, weight: .bold))

                    Text("Thanks for using DuXK.")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
                        Text("I'm a Duck, quack quack!")
                            .font(.system(size: 17, weight: .bold))
                        Text("I will notify you when a new PS4 or PS5 jailbreak is released, is in progress, or when a system update patches something important.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)

                    VStack(spacing: 10) {
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Terms of Use — please read everything")
                            .font(.headline)
                        Group {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("1. Info Only")
                                    .font(.headline)
                                Text("DuXK only shares public news about PS4 and PS5 jailbreaks, system updates and patches. We do not host, develop or distribute exploits, payloads or copyrighted files.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("2. Your Responsibility")
                                    .font(.headline)
                                Text("Modifying your console can void warranty, cause PSN bans, data loss or bricks. Everything you do with your console is your own decision and your own risk.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("3. No Liability")
                                    .font(.headline)
                                Text("DuXK and its team are not responsible for any damage, ban, data loss or cost caused by following linked info. No warranty, as-is.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("4. External Links")
                                    .font(.headline)
                                Text("All links belong to their owners (Wololo, PSXHAX, PSX-Place, GBATemp, PlayStation, GitHub developers). Their terms apply when you open them.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("5. No Affiliation")
                                    .font(.headline)
                                Text("DuXK is not affiliated with or endorsed by Sony Interactive Entertainment.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("6. Stay Safe")
                                    .font(.headline)
                                Text("Always check multiple trusted sources, stay on low firmware if you want homebrew, and turn off auto-updates. We give no guarantee that any method still works on your firmware.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("7. Minors")
                                    .font(.headline)
                                Text("If you are under the age required in your country, only use DuXK with a parent or guardian.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("8. No Misuse")
                                    .font(.headline)
                                Text("Do not use information from DuXK for illegal activity. Respect copyright.")
                                    .font(.subheadline)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("9. Changes")
                                    .font(.headline)
                                Text("We may update these terms on GitHub (TERMS.md). Continued use means you accept them.")
                                    .font(.subheadline)
                            }
                        }
                        Link("Full Terms on GitHub →", destination: RemoteConfig.termsURL)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)

                    // Unsichtbarer Marker: erst wenn du ganz unten bist, wird Accept frei.
                    Color.clear
                        .frame(height: 1)
                        .onAppear { canAccept = true }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            VStack(spacing: 10) {
                if !canAccept {
                    Text("Please scroll down and read the Terms to continue.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button(action: onAccept) {
                    Text("Accept & Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAccept ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(!canAccept)
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
