import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    DuckAvatar(size: 48, cornerRadius: 12)
                    Text("Terms of Use")
                        .font(.title2).fontWeight(.bold)
                }

                Group {
                    Text("1. Info Only").fontWeight(.bold) + Text("\nDuXK only shares public news about PS4 and PS5 jailbreaks, system updates and patches. We do not host, develop or distribute exploits, payloads or copyrighted files.")
                    Text("2. Your Responsibility").fontWeight(.bold) + Text("\nModifying your console can void warranty, cause PSN bans, data loss or bricks. Everything you do with your console is your own decision and your own risk.")
                    Text("3. No Liability").fontWeight(.bold) + Text("\nDuXK and its team are not responsible for any damage, ban, data loss or cost caused by following linked info. No warranty, as-is.")
                    Text("4. External Links").fontWeight(.bold) + Text("\nAll links belong to their owners (Wololo, PSXHAX, PSX-Place, GBATemp, PlayStation, GitHub developers). Their terms apply when you open them.")
                    Text("5. No Affiliation").fontWeight(.bold) + Text("\nDuXK is not affiliated with or endorsed by Sony Interactive Entertainment.")
                    Text("6. Stay Safe").fontWeight(.bold) + Text("\nAlways check multiple trusted sources, stay on low firmware if you want homebrew, and turn off auto-updates. We give no guarantee that any method still works on your firmware.")
                    Text("7. Minors").fontWeight(.bold) + Text("\nIf you are under the age required in your country, only use DuXK with a parent or guardian.")
                    Text("8. No Misuse").fontWeight(.bold) + Text("\nDo not use information from DuXK for illegal activity. Respect copyright.")
                    Text("9. Changes").fontWeight(.bold) + Text("\nWe may update these terms on GitHub (TERMS.md). Continued use means you accept them.")
                }
                .font(.body)

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
