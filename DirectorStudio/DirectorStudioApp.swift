import SwiftUI
import AVKit
import os.log

// MARK: - App Entry Point with Mac Catalyst Support
@main
struct DirectorStudioApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var pipeline = DirectorStudioPipeline()
    @StateObject private var persistenceController = PersistenceController.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    private let logger = Logger(subsystem: "net.neuraldraft.DirectorStudio", category: "App")
    
    init() {
        // Validate API key configuration on app startup
        logger.info("🚀 DirectorStudio app initializing...")
        let isValid = DeepSeekConfig.validateConfiguration()
        logger.info("🔍 API key validation result: \(isValid ? "SUCCESS" : "FAILED")")
    }
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(pipeline)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .environmentObject(appState)
                    .environmentObject(pipeline)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
            
            #if DEBUG
            CommandGroup(after: .newItem) {
                Divider()
                Button("Print Cost Diagnostics") {
                    CreditWallet.printCostDiagnostics()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
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
