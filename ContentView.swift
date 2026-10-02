// Main tab routing
import SwiftUI

struct ContentView: View {
    @AppStorage("duxk.accepted") var accepted = false
    @AppStorage("duxk.declined") var declined = false
    @State private var showWelcome = false

    var body: some View {
        Group {
            if declined && !accepted {
                BlockedView(onRetry: {
                    declined = false
                    showWelcome = true
                })
            } else if !accepted {
                // Placeholder behind welcome sheet
                HomePlaceholder()
                    .onAppear { showWelcome = true }
                    .fullScreenCover(isPresented: $showWelcome) {
                        WelcomeView(
                            onAccept: {
                                accepted = true
                                declined = false
                                showWelcome = false
                                NotificationManager.shared.requestPermission()
                                JailbreakService.shared.refresh()
                            },
                            onDecline: {
                                declined = true
                                showWelcome = false
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

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            UpdatesView()
                .tabItem {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Updates")
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
    }
}

struct HomePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tortoise.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("DuXK")
                .font(.title).bold()
        }
    }
}

struct BlockedView: View {
    var onRetry: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🦆")
                .font(.system(size: 60))
            Text("App Locked")
                .font(.title2).bold()
            Text("You need to accept the Terms to use DuXK.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button("Review Terms Again", action: onRetry)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            Spacer()
        }
        .padding()
    }
}
