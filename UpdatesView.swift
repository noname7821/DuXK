import SwiftUI

struct UpdatesView: View {
    @EnvironmentObject var service: JailbreakService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(service.firmwares) { fw in
                        FirmwareCard(fw: fw)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patch News")
                            .font(.headline)
                            .padding(.horizontal)
                        ForEach(service.updates) { item in
                            NavigationLink(destination: NewsDetailView(item: item)) {
                                NewsRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .padding(.top, 12)
            }
            .navigationTitle("Updates & Patches")
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FirmwareCard: View {
    var fw: FirmwareInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(fw.console.rawValue) \(fw.version)")
                    .font(.headline)
                Spacer()
                Badge(text: fw.isPatched ? "PATCHED" : "JAILBREAKABLE", color: fw.isPatched ? .red : .green)
            }
            Text(fw.date)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(fw.notes)
                .font(.subheadline)
            Text(fw.jailbreakStatus)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(fw.isPatched ? .red : .green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 1)
    }
}
