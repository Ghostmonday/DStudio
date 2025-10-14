import SwiftUI
import AVKit

// MARK: - App Entry Point with Mac Catalyst Support
@main
struct DirectorStudioApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var pipeline = DirectorStudioPipeline()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(pipeline)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .environmentObject(appState)
                    .environmentObject(pipeline)
            }
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    // New project action
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(macOS)
struct SettingsView: View {
    var body: some View {
        TabView {
            Form {
                Section("API Configuration") {
                    SecureField("DeepSeek API Key", text: .constant(""))
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
        }
        .frame(width: 500, height: 300)
    }
}
#endif
