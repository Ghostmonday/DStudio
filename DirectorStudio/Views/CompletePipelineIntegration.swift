//
//  CompletePipelineIntegration.swift
//  DirectorStudio
//
//  Complete Integration: UI → Pipeline → Storage → Sync
//  App Store Feature-Ready Implementation
//

import SwiftUI
import Combine

// MARK: - Main App Coordinator

@MainActor
public class DirectorStudioCoordinator: ObservableObject {
    
    // MARK: - Dependencies
    
    private let storage = LocalStorageManager.shared
    private let syncEngine = SupabaseSyncEngine.shared
    private let pipelineManager: PipelineManager
    
    // MARK: - Published State
    
    @Published public var currentProject: Project?
    @Published public var sceneControlConfig = SceneControlConfig()
    @Published public var isGenerating: Bool = false
    @Published public var generationProgress: Double = 0.0
    @Published public var credits: Int = 0
    @Published public var showingSyncStatus: Bool = false
    
    // MARK: - Internal State
    
    private var cancellables = Set<AnyCancellable>()
    private var reviewContinuation: CheckedContinuation<ShotListReviewDecision, Never>?
    
    // MARK: - Initialization
    
    public init() {
        self.pipelineManager = PipelineManager()
        
        setupPipelineReviewGates()
        setupObservers()
        
        Task {
            await loadCredits()
            await loadCurrentProject()
        }
    }
    
    // MARK: - Setup
    
    private func setupPipelineReviewGates() {
        // Shot list review gate
        pipelineManager.shotListReviewGate = ShotListReviewGate { [weak self] item in
            guard let self = self else {
                return .rejected(reason: "Coordinator unavailable")
            }
            
            return await withCheckedContinuation { continuation in
                self.reviewContinuation = continuation
                // UI will call respondToShotListReview() with decision
            }
        }
    }
    
    private func setupObservers() {
        // Observe sync state
        syncEngine.$syncState
            .sink { [weak self] state in
                self?.showingSyncStatus = (state == .syncing)
            }
            .store(in: &cancellables)
        
        // Observe storage ready state
        storage.$isReady
            .filter { $0 }
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCurrentProject()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Project Management
    
    public func createNewProject(title: String, script: String) async throws {
        // Create screenplay
        let screenplay = Screenplay(
            id: UUID(),
            title: title,
            content: script,
            version: 1,
            sections: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save locally
        try await storage.saveScreenplay(screenplay)
        
        // Create project
        let project = Project(
            id: UUID(),
            title: title,
            screenplayId: screenplay.id,
            scenes: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        currentProject = project
        
        // Trigger sync
        await syncEngine.syncNow()
    }
    
    public func loadCurrentProject() async {
        do {
            let screenplays = try await storage.loadAllScreenplays()
            
            guard let latest = screenplays.first else {
                return
            }
            
            // Load associated scenes
            let scenes = try await storage.loadSceneDrafts(for: latest.id.uuidString)
            
            currentProject = Project(
                id: UUID(),
                title: latest.title,
                screenplayId: latest.id,
                scenes: scenes,
                createdAt: latest.createdAt,
                updatedAt: latest.updatedAt
            )
            
        } catch {
            print("❌ Failed to load project: \(error)")
        }
    }
    
    // MARK: - Scene Generation Pipeline
    
    public func generateScenes() async {
        guard let project = currentProject else { return }
        guard let screenplay = try? await storage.loadScreenplay(id: project.screenplayId) else {
            return
        }
        
        isGenerating = true
        generationProgress = 0.0
        
        do {
            // Build pipeline config from UI settings
            let pipelineConfig = buildPipelineConfig()
            
            // Create pipeline input
            let input = PipelineInput(story: screenplay.content)
            
            // Run pipeline
            let output = try await pipelineManager.run(input: input, config: pipelineConfig)
            
            // Convert output to scene drafts
            var scenes: [SceneDraft] = []
            
            for (index, segment) in output.segments.enumerated() {
                let draft = SceneDraft(
                    id: UUID(),
                    projectId: project.id.uuidString,
                    orderIndex: index,
                    promptText: segment.enrichedPrompt,
                    duration: segment.estimatedDuration,
                    sceneType: segment.sceneType?.rawValue,
                    shotType: segment.suggestedShotType?.rawValue,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                scenes.append(draft)
                
                // Save each draft
                try await storage.saveSceneDraft(draft)
                
                // Update progress
                generationProgress = Double(index + 1) / Double(output.segments.count)
            }
            
            // Update current project
            currentProject?.scenes = scenes
            
            // Trigger sync
            await syncEngine.syncNow()
            
            isGenerating = false
            
        } catch {
            print("❌ Scene generation failed: \(error)")
            isGenerating = false
        }
    }
    
    private func buildPipelineConfig() -> PipelineConfig {
        var config = PipelineConfig()
        
        // Map UI controls to pipeline
        if sceneControlConfig.automaticMode {
            config.userControls.generationMode = .automatic
            config.userControls.segmentationStrategy = .automatic
            config.userControls.durationStrategy = .scriptBased
        } else {
            config.userControls.generationMode = .semiAutomatic
            config.userControls.segmentationStrategy = .manual(count: sceneControlConfig.targetSceneCount)
            config.userControls.durationStrategy = .fixed(seconds: Int(sceneControlConfig.targetDurationPerScene))
            config.userControls.maxShots = sceneControlConfig.targetSceneCount
        }
        
        // Budget limits
        if let maxBudget = sceneControlConfig.maxBudget {
            config.userControls.maxCostPerProject = Decimal(maxBudget)
        }
        
        // Review gates
        config.userControls.requireShotListApproval = !sceneControlConfig.automaticMode
        config.userControls.allowEditBeforeGeneration = true
        
        return config
    }
    
    // MARK: - Review Gate Response
    
    public func respondToShotListReview(decision: ShotListReviewDecision) {
        reviewContinuation?.resume(returning: decision)
        reviewContinuation = nil
    }
    
    // MARK: - Video Generation
    
    public func generateVideo(for scene: SceneDraft) async throws {
        // Check credits
        guard credits >= Int(scene.duration * sceneControlConfig.estimatedCostPerSecond) else {
            throw GenerationError.insufficientCredits
        }
        
        // Submit job to backend
        let jobId = try await syncEngine.submitClipJob(prompt: scene.promptText)
        
        // Create video clip metadata
        let clip = VideoClipMetadata(
            id: UUID(),
            projectId: scene.projectId,
            jobId: jobId,
            orderIndex: scene.orderIndex,
            status: .queued,
            localURL: nil,
            remoteURL: nil,
            duration: scene.duration,
            thumbnailData: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save locally
        try await storage.saveVideoClip(clip)
        
        // Start polling for completion
        Task {
            await pollJobStatus(jobId: jobId, clipId: clip.id)
        }
        
        // Deduct credits
        try await syncEngine.consumeCredits(amount: Int(scene.duration * sceneControlConfig.estimatedCostPerSecond))
        await loadCredits()
    }
    
    private func pollJobStatus(jobId: String, clipId: UUID) async {
        while true {
            do {
                let status = try await syncEngine.checkJobStatus(jobId: jobId)
                
                switch status.status {
                case "completed":
                    if let urlString = status.downloadURL,
                       let url = URL(string: urlString) {
                        try await storage.updateVideoClipStatus(
                            id: clipId,
                            status: .completed,
                            remoteURL: url
                        )
                    }
                    return
                    
                case "failed":
                    try await storage.updateVideoClipStatus(id: clipId, status: .failed)
                    return
                    
                case "processing":
                    try await storage.updateVideoClipStatus(id: clipId, status: .processing)
                    
                default:
                    break
                }
                
                // Wait 5 seconds before next poll
                try await Task.sleep(nanoseconds: 5_000_000_000)
                
            } catch {
                print("❌ Failed to poll job status: \(error)")
                return
            }
        }
    }
    
    // MARK: - Credits Management
    
    public func loadCredits() async {
        do {
            credits = try await syncEngine.syncCredits()
        } catch {
            print("❌ Failed to load credits: \(error)")
        }
    }
    
    // MARK: - Scene Management
    
    public func updateScene(_ scene: SceneDraft) async throws {
        try await storage.saveSceneDraft(scene)
        
        // Update in current project
        if let index = currentProject?.scenes.firstIndex(where: { $0.id == scene.id }) {
            currentProject?.scenes[index] = scene
        }
        
        // Trigger sync
        await syncEngine.syncNow()
    }
    
    public func deleteScene(_ scene: SceneDraft) async throws {
        try await storage.deleteSceneDraft(scene.id)
        
        // Remove from current project
        currentProject?.scenes.removeAll { $0.id == scene.id }
        
        // Trigger sync
        await syncEngine.syncNow()
    }
    
    public func reorderScenes(_ scenes: [SceneDraft]) async throws {
        // Update order indices
        for (index, scene) in scenes.enumerated() {
            var updated = scene
            updated.orderIndex = index
            try await storage.saveSceneDraft(updated)
        }
        
        // Update current project
        currentProject?.scenes = scenes
        
        // Trigger sync
        await syncEngine.syncNow()
    }
}

// MARK: - Project Model

public struct Project: Identifiable {
    public let id: UUID
    public let title: String
    public let screenplayId: UUID
    public var scenes: [SceneDraft]
    public let createdAt: Date
    public let updatedAt: Date
}

// MARK: - Generation Error

public enum GenerationError: LocalizedError {
    case insufficientCredits
    case networkError
    case pipelineError(String)
    
    public var errorDescription: String? {
        switch self {
        case .insufficientCredits:
            return "Insufficient credits to generate video"
        case .networkError:
            return "Network connection error"
        case .pipelineError(let message):
            return "Pipeline error: \(message)"
        }
    }
}

// MARK: - Main App View

public struct DirectorStudioApp: View {
    @StateObject private var coordinator = DirectorStudioCoordinator()
    @State private var showingSceneControl = false
    @State private var showingNewProject = false
    
    public var body: some View {
        NavigationStack {
            if let project = coordinator.currentProject {
                ProjectView(project: project, coordinator: coordinator)
            } else {
                WelcomeView(showingNewProject: $showingNewProject)
            }
        }
        .sheet(isPresented: $showingSceneControl) {
            SceneControlSheet(config: $coordinator.sceneControlConfig)
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet(coordinator: coordinator)
        }
        .overlay(alignment: .top) {
            if coordinator.showingSyncStatus {
                SyncStatusBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .environmentObject(coordinator)
    }
}

// MARK: - Project View

struct ProjectView: View {
    let project: Project
    @ObservedObject var coordinator: DirectorStudioCoordinator
    @State private var showingSceneControl = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                projectHeader
                
                // Scenes
                if project.scenes.isEmpty {
                    emptyState
                } else {
                    scenesGrid
                }
            }
            .padding()
        }
        .navigationTitle(project.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingSceneControl = true
                    } label: {
                        Label("Scene Settings", systemImage: "slider.horizontal.3")
                    }
                    
                    Button {
                        Task {
                            await coordinator.generateScenes()
                        }
                    } label: {
                        Label("Generate Scenes", systemImage: "sparkles")
                    }
                    .disabled(coordinator.isGenerating)
                    
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
        VStack(spacing: 12) {
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
    
    private var emptyState: some View {
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
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private var scenesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 300), spacing: 16)
        ], spacing: 16) {
            ForEach(project.scenes) { scene in
                SceneCard(scene: scene, coordinator: coordinator)
            }
        }
    }
}

// MARK: - Scene Card

struct SceneCard: View {
    let scene: SceneDraft
    @ObservedObject var coordinator: DirectorStudioCoordinator
    @State private var isGenerating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scene \(scene.orderIndex + 1)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(scene.duration))s")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(scene.promptText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                if let sceneType = scene.sceneType {
                    Label(sceneType, systemImage: "film")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task {
                        isGenerating = true
                        try? await coordinator.generateVideo(for: scene)
                        isGenerating = false
                    }
                } label: {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Label("Generate", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// MARK: - Supporting Views

struct WelcomeView: View {
    @Binding var showingNewProject: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "film.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("DirectorStudio")
                    .font(.largeTitle.bold())
                
                Text("Professional AI Filmmaking")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                showingNewProject = true
            } label: {
                Label("New Project", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .padding()
    }
}

struct NewProjectSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var coordinator: DirectorStudioCoordinator
    
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

struct SyncStatusBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Syncing...")
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .shadow(radius: 10)
    }
}
