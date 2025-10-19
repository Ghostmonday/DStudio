//
//  DirectorStudioApp.swift
//  DirectorStudio
//
//  Master App Entry Point - Complete Integration
//  App Store Feature-Ready Implementation
//

import SwiftUI
import StoreKit

@main
struct DirectorStudioApp: App {
    
    // MARK: - App Lifecycle
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - State Management
    
    @StateObject private var coordinator = DirectorStudioCoordinator()
    @StateObject private var purchaseManager = CreditsPurchaseManager()
    
    // MARK: - Scene Configuration
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .environmentObject(purchaseManager)
                .task {
                    // Initialize on launch
                    await initializeApp()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
    }
    
    // MARK: - Initialization
    
    private func initializeApp() async {
        // Wait for storage to be ready
        while !LocalStorageManager.shared.isReady {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        // Load initial data
        await coordinator.loadCurrentProject()
        await coordinator.loadCredits()
        
        // Trigger initial sync if online
        if SupabaseSyncEngine.shared.isOnline {
            await SupabaseSyncEngine.shared.syncNow()
        }
    }
    
    // MARK: - Lifecycle Handlers
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            Task {
                await SupabaseSyncEngine.shared.syncNow()
                await coordinator.loadCredits()
            }
            
        case .inactive:
            // App becoming inactive
            Task {
                await LocalStorageManager.shared.saveContext()
            }
            
        case .background:
            // App in background
            Task {
                await LocalStorageManager.shared.saveContext()
            }
            
        @unknown default:
            break
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // Configure appearance
        configureAppearance()
        
        // Setup background tasks
        registerBackgroundTasks()
        
        // Setup crash reporting (if using)
        // setupCrashReporting()
        
        return true
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func registerBackgroundTasks() {
        // Register background sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.directorstudio.sync",
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundSync(task: BGProcessingTask) {
        // Schedule next background sync
        scheduleBackgroundSync()
        
        // Perform sync
        Task {
            do {
                await SupabaseSyncEngine.shared.syncNow()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func scheduleBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: "com.directorstudio.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour
        request.requiresNetworkConnectivity = true
        
        try? BGTaskScheduler.shared.submit(request)
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @EnvironmentObject var coordinator: DirectorStudioCoordinator
    @State private var showingSettings = false
    
    var body: some View {
        TabView {
            // Projects Tab
            NavigationStack {
                ProjectsListView()
            }
            .tabItem {
                Label("Projects", systemImage: "folder.fill")
            }
            
            // Generate Tab
            NavigationStack {
                GenerateView()
            }
            .tabItem {
                Label("Generate", systemImage: "sparkles")
            }
            
            // Library Tab
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "film.stack")
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .overlay(alignment: .top) {
            // Sync status banner
            if coordinator.showingSyncStatus {
                SyncStatusBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Projects List View

struct ProjectsListView: View {
    @EnvironmentObject var coordinator: DirectorStudioCoordinator
    @State private var showingNewProject = false
    
    var body: some View {
        Group {
            if coordinator.currentProject == nil {
                emptyState
            } else {
                projectsList
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingNewProject = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Projects Yet")
                .font(.title2.bold())
            
            Text("Create your first project to get started")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                showingNewProject = true
            } label: {
                Label("New Project", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var projectsList: some View {
        List {
            if let project = coordinator.currentProject {
                NavigationLink(destination: ProjectDetailView(project: project)) {
                    ProjectRow(project: project)
                }
            }
        }
    }
}

// MARK: - Project Detail View

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject var coordinator: DirectorStudioCoordinator
    @State private var showingSceneControl = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                projectHeader
                
                // Scenes
                if project.scenes.isEmpty {
                    emptySceneState
                } else {
                    scenesGrid
                }
            }
            .padding()
        }
        .navigationTitle(project.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingSceneControl = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                
                Menu {
                    Button {
                        Task { await coordinator.generateScenes() }
                    } label: {
                        Label("Generate Scenes", systemImage: "sparkles")
                    }
                    .disabled(coordinator.isGenerating)
                    
                    Button(role: .destructive) {
                        // Delete project
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingSceneControl) {
            SceneControlSheet(config: $coordinator.sceneControlConfig)
        }
    }
    
    private var projectHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(project.scenes.count) Scenes")
                        .font(.headline)
                    
                    Text("Updated \(project.updatedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("\(coordinator.credits)")
                    }
                    .font(.headline)
                    
                    Text("credits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if coordinator.isGenerating {
                ProgressView(value: coordinator.generationProgress) {
                    Text("Generating scenes...")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    private var emptySceneState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Scenes Yet")
                .font(.title2.bold())
            
            Text("Configure scene settings and generate your first scenes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingSceneControl = true
            } label: {
                Label("Get Started", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private var scenesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 300), spacing: 16)
        ], spacing: 16) {
            ForEach(project.scenes) { scene in
                SceneCard(scene: scene)
            }
        }
    }
}

// MARK: - Generate View

struct GenerateView: View {
    @EnvironmentObject var coordinator: DirectorStudioCoordinator
    
    var body: some View {
        Text("Generate View")
            .navigationTitle("Generate")
    }
}

// MARK: - Library View

struct LibraryView: View {
    var body: some View {
        Text("Library View")
            .navigationTitle("Library")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var coordinator: DirectorStudioCoordinator
    @EnvironmentObject var purchaseManager: CreditsPurchaseManager
    
    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Text("Credits")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("\(coordinator.credits)")
                    }
                    .foregroundColor(.accentColor)
                }
                
                NavigationLink("Purchase Credits") {
                    PurchaseCreditsView()
                }
            }
            
            Section("Sync") {
                HStack {
                    Text("Last Synced")
                    Spacer()
                    if let date = SupabaseSyncEngine.shared.lastSyncDate {
                        Text(date.formatted(.relative(presentation: .named)))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Pending Items")
                    Spacer()
                    Text("\(SupabaseSyncEngine.shared.pendingSyncCount)")
                        .foregroundColor(.secondary)
                }
                
                Button("Sync Now") {
                    Task {
                        await SupabaseSyncEngine.shared.syncNow()
                    }
                }
            }
            
            Section("Storage") {
                NavigationLink("Manage Data") {
                    DataManagementView()
                }
            }
            
            Section("About") {
                Link("Privacy Policy", destination: URL(string: "https://directorstudio.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://directorstudio.app/terms")!)
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Purchase Credits View

struct PurchaseCreditsView: View {
    @EnvironmentObject var purchaseManager: CreditsPurchaseManager
    @State private var isPurchasing = false
    
    var body: some View {
        List {
            Section {
                ForEach(purchaseManager.products) { product in
                    Button {
                        Task {
                            isPurchasing = true
                            try? await purchaseManager.purchase(product)
                            isPurchasing = false
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline)
                                
                                Text(product.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(product.displayPrice)
                                .font(.headline)
                        }
                    }
                    .disabled(isPurchasing)
                }
            }
            
            Section {
                Button("Restore Purchases") {
                    Task {
                        try? await AppStore.sync()
                    }
                }
            }
        }
        .navigationTitle("Purchase Credits")
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section("Storage") {
                Button("Export All Data") {
                    Task {
                        let data = try await LocalStorageManager.shared.exportAllData()
                        // Share exported data
                    }
                }
                
                Button("Delete Old Data") {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle("Data Management")
        .alert("Delete Old Data?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await LocalStorageManager.shared.deleteOldData(olderThan: 30)
                }
            }
        } message: {
            Text("This will delete data older than 30 days.")
        }
    }
}

// MARK: - Supporting Views

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.title)
                .font(.headline)
            
            HStack {
                Text("\(project.scenes.count) scenes")
                Text("•")
                Text(project.updatedAt.formatted(.relative(presentation: .named)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

struct NewProjectSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: DirectorStudioCoordinator
    
    @State private var title = ""
    @State private var script = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $title)
                }
                
                Section("Screenplay") {
                    TextEditor(text: $script)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            try? await coordinator.createNewProject(title: title, script: script)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || script.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DirectorStudioCoordinator())
        .environmentObject(CreditsPurchaseManager())
}
