import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    DuckAvatar(size: 48, cornerRadius: 12)
                    Text("Terms of Use")
                        .font(.system(size: 22, weight: .bold))
                }

                Group {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("1. Info Only")
                            .font(.headline)
                        Text("DuXK only shares public news about PS4 and PS5 jailbreaks, system updates and patches. We do not host, develop or distribute exploits, payloads or copyrighted files.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("2. Your Responsibility")
                            .font(.headline)
                        Text("Modifying your console can void warranty, cause PSN bans, data loss or bricks. Everything you do with your console is your own decision and your own risk.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("3. No Liability")
                            .font(.headline)
                        Text("DuXK and its team are not responsible for any damage, ban, data loss or cost caused by following linked info. No warranty, as-is.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("4. External Links")
                            .font(.headline)
                        Text("All links belong to their owners (Wololo, PSXHAX, PSX-Place, GBATemp, PlayStation, GitHub developers). Their terms apply when you open them.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("5. No Affiliation")
                            .font(.headline)
                        Text("DuXK is not affiliated with or endorsed by Sony Interactive Entertainment.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("6. Stay Safe")
                            .font(.headline)
                        Text("Always check multiple trusted sources, stay on low firmware if you want homebrew, and turn off auto-updates. We give no guarantee that any method still works on your firmware.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("7. Minors")
                            .font(.headline)
                        Text("If you are under the age required in your country, only use DuXK with a parent or guardian.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("8. No Misuse")
                            .font(.headline)
                        Text("Do not use information from DuXK for illegal activity. Respect copyright.")
                            .font(.body)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("9. Changes")
                            .font(.headline)
                        Text("We may update these terms on GitHub (TERMS.md). Continued use means you accept them.")
                            .font(.body)
                    }
                }

                Link("Full Terms + License on GitHub →", destination: RemoteConfig.termsURL)
                    .font(.headline)
                    .padding(.top, 4)

                Text("By tapping Accept you confirm you read this and use DuXK at your own risk.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}
