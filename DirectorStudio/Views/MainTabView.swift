import SwiftUI

// MARK: - Main Tab View with Adaptive Layout
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad, Mac - Sidebar navigation
                NavigationSplitView {
                    List {
                        Button(action: { selectedTab = 0 }) {
                            Label("Create", systemImage: "lightbulb.fill")
                        }
                        .foregroundColor(selectedTab == 0 ? .purple : .primary)
                        
                        Button(action: { selectedTab = 1 }) {
                            Label("Studio", systemImage: "film.fill")
                        }
                        .foregroundColor(selectedTab == 1 ? .purple : .primary)
                        
                        Button(action: { selectedTab = 2 }) {
                            Label("Library", systemImage: "square.grid.2x2.fill")
                        }
                        .foregroundColor(selectedTab == 2 ? .purple : .primary)
                        
                        Button(action: { selectedTab = 3 }) {
                            Label("Settings", systemImage: "gear")
                        }
                        .foregroundColor(selectedTab == 3 ? .purple : .primary)
                    }
                    .navigationTitle("DirectorStudio")
                } detail: {
                    selectedTabView
                }
            } else {
                // iPhone - Tab bar
                TabView(selection: $selectedTab) {
                    CreateView()
                        .tabItem {
                            Label("Create", systemImage: "lightbulb.fill")
                        }
                        .tag(0)
                    
                    StudioView()
                        .tabItem {
                            Label("Studio", systemImage: "film.fill")
                        }
                        .tag(1)
                    
                    LibraryView()
                        .tabItem {
                            Label("Library", systemImage: "square.grid.2x2.fill")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(3)
                }
                .tint(.purple)
            }
        }
    }
    
    @ViewBuilder
    var selectedTabView: some View {
        switch selectedTab {
        case 0: CreateView()
        case 1: StudioView()
        case 2: LibraryView()
        case 3: SettingsView()
        default: CreateView()
        }
    }
}
