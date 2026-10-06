import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("duxk.accepted") var accepted = false
    @State private var showWelcome = false

    var body: some View {
        Group {
            if !accepted {
                HomePlaceholder()
                    .onAppear { showWelcome = true }
                    .fullScreenCover(isPresented: $showWelcome) {
                        WelcomeView(
                            onAccept: {
                                accepted = true
                                showWelcome = false
                                NotificationManager.shared.requestPermission()
                                JailbreakService.shared.refresh()
                            },
                            onDecline: {
                                // Decline = App sofort beenden, kein Lock-Screen.
                                exit(0)
                            }
                        )
                    }
            } else {
                MainTabs()
            }
        }
    }
}

struct MainTabs: View {
    @StateObject private var service = JailbreakService.shared
    @StateObject private var notifs = NotificationManager.shared
    @StateObject private var remote = RemoteConfig.shared

    var body: some View {
        TabView {
            SetupView()
                .tabItem {
                    Image(systemName: "link")
                    Text("Setup")
                }

            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(Color.blue)
        .environmentObject(service)
        .environmentObject(notifs)
        .environmentObject(remote)
        .onAppear { remote.check() }
        .alert(isPresented: $remote.updateAvailable) {
            Alert(
                title: Text("New update available"),
                message: Text("Version \(remote.latestVersion) ist da (du hast \(remote.appVersion))."),
                primaryButton: .default(Text("Update")) { remote.openReleases() },
                secondaryButton: .cancel(Text("Später")) { remote.snooze() }
            )
        }
        .fullScreenCover(isPresented: $remote.shutdownActive) {
            ShutdownView()
        }
    }
}

struct ShutdownView: View {
    @EnvironmentObject var remote: RemoteConfig

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            DuckAvatar(size: 110, cornerRadius: 26)
                .shadow(radius: 8)
            Text("DuXK")
                .font(.system(size: 28, weight: .bold))
            Text("Sorry, DuXK got shut down.")
                .font(.headline)
                .multilineTextAlignment(.center)
            if remote.hasValidDiscord, let url = URL(string: remote.discordInvite) {
                Link(destination: url) {
                    Text("Any other infos can you find in our Discord Server.")
                        .font(.body)
                        .foregroundColor(.blue)
                        .underline(true, color: .blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                Text("Any other infos can you find in our Discord Server.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct HomePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            DuckAvatar(size: 60, cornerRadius: 15)
            Text("DuXK")
                .font(.system(size: 28, weight: .bold))
        }
    }
}
