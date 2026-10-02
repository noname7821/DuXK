import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var notifs: NotificationManager
    @EnvironmentObject var remote: RemoteConfig
    @AppStorage("duxk.notifs") var notifsOn = true

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $notifsOn) {
                        Label("Jailbreak Alerts", systemImage: "bell.fill")
                    }
                    .onChange(of: notifsOn) { v in
                        if v { notifs.requestPermission() }
                    }
                    Button(action: { notifs.requestPermission() }) {
                        Label("Enable Notifications", systemImage: "bell.badge.fill")
                    }
                    Button(action: { notifs.openSystemSettings() }) {
                        Label("Open System Settings", systemImage: "gearshape.fill")
                    }
                    .foregroundColor(.secondary)
                }

                Section(header: Text("Legal")) {
                    NavigationLink(destination: TermsView()) {
                        Label("Read Terms", systemImage: "doc.text.fill")
                    }
                }

                Section(header: Text("Credits")) {
                    Link(destination: URL(string: "https://www.tiktok.com/@duxk40?is_from_webapp=1&sender_device=pc")!) {
                        HStack(spacing: 12) {
                            DuckAvatar(size: 48, cornerRadius: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("duxk40")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Our Official TikTok account!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Sources"), footer: Text("DuXK checks these sites for new jailbreak and firmware info.")) {
                    ForEach(JailbreakService.shared.sources, id: \.name) { s in
                        Link(destination: URL(string: s.url)!) {
                            HStack {
                                Text(s.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("App")) {
                    if remote.updateAvailable {
                        Button(action: { remote.openReleases() }) {
                            HStack {
                                Label("Update available", systemImage: "arrow.down.circle.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(remote.latestVersion)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(remote.appVersion)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Support")
                        Spacer()
                        Text("iOS 14.0+ • All devices")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
