// Home screen
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var service: JailbreakService
    @State private var showJailbreaks = false
    @State private var showUpdates = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header card
                    HStack(spacing: 14) {
                        Image("duck")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All set")
                                .font(.headline)
                            Text(newsCountText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if service.isLoading {
                            ProgressView()
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(18)
                    .padding(.horizontal)

                    // Main buttons
                    VStack(spacing: 12) {
                        HomeButton(
                            icon: "lock.open.fill",
                            title: "Show Latest Jailbreaks",
                            subtitle: "PS4 & PS5 exploits, status and guides",
                            color: .blue
                        ) { showJailbreaks = true }

                        HomeButton(
                            icon: "arrow.down.circle.fill",
                            title: "Show Latest System Updates & Patches",
                            subtitle: "Firmware notes, what got patched",
                            color: .green
                        ) { showUpdates = true }
                    }
                    .padding(.horizontal)

                    // Recent list preview
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent News")
                                .font(.headline)
                            Spacer()
                            if let d = service.lastUpdated {
                                Text("Updated \(timeAgo(d))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        ForEach(service.news.prefix(4)) { item in
                            NavigationLink(destination: NewsDetailView(item: item)) {
                                NewsRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 12)
            }
            .navigationTitle("DuXK")
            .navigationBarItems(trailing: refreshButton)
            .background(
                NavigationLink(destination: NewsListView(title: "Latest Jailbreaks", items: service.jailbreaks), isActive: $showJailbreaks) { EmptyView() }
            )
            .background(
                NavigationLink(destination: UpdatesView(), isActive: $showUpdates) { EmptyView() }
            )
            .onAppear { service.refresh() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    var newsCountText: String {
        let n = service.news.filter { $0.isNew }.count
        if n == 0 { return "New info will appear here + as notification." }
        return "\(n) new update\(n == 1 ? "" : "s") available."
    }

    var refreshButton: some View {
        Button(action: { service.refresh() }) {
            Image(systemName: "arrow.clockwise")
        }
    }

    func timeAgo(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
    }
}

// Big card button
struct HomeButton: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .cornerRadius(14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// Row + list + detail
struct NewsRow: View {
    var item: NewsItem
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Badge(text: item.console.rawValue, color: item.console == .ps4 ? .blue : .purple)
                    Badge(text: item.type.rawValue, color: item.type == .jailbreak ? .green : .orange)
                    if item.isNew {
                        Badge(text: "NEW", color: .red)
                    }
                }
                Text(item.title)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text("\(item.firmware) • \(prettyDate(item.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 1)
        .padding(.horizontal)
    }

    func prettyDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        if let d = f.date(from: iso) {
            let out = DateFormatter()
            out.dateStyle = .medium
            return out.string(from: d)
        }
        return iso
    }
}

struct Badge: View {
    var text: String
    var color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct NewsListView: View {
    var title: String
    var items: [NewsItem]
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink(destination: NewsDetailView(item: item)) {
                        NewsRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
                if items.isEmpty {
                    Text("No entries yet.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .navigationTitle(title)
        .background(Color(.systemGroupedBackground))
    }
}

struct NewsDetailView: View {
    var item: NewsItem
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Badge(text: item.console.rawValue, color: .blue)
                    Badge(text: item.type.rawValue, color: .green)
                    Badge(text: item.firmware, color: .orange)
                    if item.isNew { Badge(text: "NEW", color: .red) }
                }
                Text(item.title)
                    .font(.title2).bold()
                Text(item.body)
                    .font(.body)
                    .foregroundColor(.primary)
                Link("Open Source →", destination: URL(string: item.url) ?? URL(string: "https://wololo.net")!)
                    .font(.headline)
                    .padding(.top, 4)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}
