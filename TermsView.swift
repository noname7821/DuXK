// Terms screen
import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Terms of Use")
                    .font(.title2).bold()

                Group {
                    Text("1. Info Only").bold() + Text("\nDuXK only shares public news about PS4 and PS5 jailbreaks, system updates and patches. We do not host exploits.")
                    Text("2. Your Responsibility").bold() + Text("\nModifying your console can void warranty, cause bans, data loss or bricks. You act at your own risk.")
                    Text("3. No Liability").bold() + Text("\nDuXK and its team are not responsible for any damage, ban or loss caused by following linked info.")
                    Text("4. Stay Safe").bold() + Text("\nAlways check multiple trusted sources, stay on low firmware if you want homebrew, and turn off auto-updates.")
                    Text("5. External Links").bold() + Text("\nAll links belong to their owners (Wololo, PSXHAX, PlayStation, GitHub devs). Their terms apply.")
                }
                .font(.body)

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
