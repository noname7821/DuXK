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

                TermsClauses(bodyFont: .body)

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
