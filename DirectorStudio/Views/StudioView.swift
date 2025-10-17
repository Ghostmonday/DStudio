import SwiftUI

// MARK: - STUDIO TAB - Show Processing Results with Export
struct StudioView: View {
    // BugScan: Studio tab crash investigation
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @Environment(\.managedObjectContext) private var context
    
    @StateObject private var continuityEngine = ContinuityEngine(context: PersistenceController.shared.container.viewContext)
    @StateObject private var soraService = SoraService(apiKey: APIKeyManager.shared.getAPIKey())
    @StateObject private var creditWallet = CreditWallet()
    @StateObject private var firstClipService = FirstClipGrantService()
    
    @State private var showExportSheet = false
    @State private var exportFormat: ExportFormat = .screenplay
    @State private var showShareSheet = false
    @State private var exportedContent = ""
    @State private var showPaywallSheet = false
    @State private var showClaimSheet = false
    @State private var showGenerationAlert = false
    @State private var generationAlertMessage = ""
    @State private var shareTelemetry = false // BugScan: studio tab crash isolation toggle
    @State private var viewReady = false // defer heavy view work until onAppear
    
    enum ExportFormat: String, CaseIterable {
        case screenplay = "Screenplay (.txt)"
        case json = "JSON Data (.json)"
        case promptList = "Prompt List (.txt)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let project = appState.currentProject {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Project Header with Export Button
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.title)
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        if let analysis = project.analysis {
                                            HStack(spacing: 16) {
                                                Label("\(analysis.characterCount) characters", systemImage: "person.2")
                                                Label("\(analysis.sceneCount) scenes", systemImage: "film")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { showExportSheet = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Export")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            
                            // Credit Balance Display
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                                Text("\(creditWallet.balance) credits")
                                    .font(.headline)
                                Spacer()
                                if creditWallet.balance == 0 && !firstClipService.hasClaimedFirstClip {
                                    Button("Claim Included Clip") {
                                        showClaimSheet = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                } else if creditWallet.balance == 0 {
                                    Button("Buy Credits") {
                                        showPaywallSheet = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Only access pipeline after first onAppear pass
                            if viewReady, let debugMessage = pipeline.segmentationModule.debugMessage, !debugMessage.isEmpty {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(debugMessage)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Scene Segments (render only when ready)
                            if viewReady {
                                let segments = pipeline.segmentationModule.segments
                                if !segments.isEmpty {
                                    ForEach(segments) { segment in
                                        SceneCardWithGeneration(segment: segment)
                                    }
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "film.stack")
                                            .font(.system(size: 48))
                                            .foregroundColor(.gray)
                                        
                                        Text("No segments available")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        
                                        Text("Run the pipeline from the Create tab to generate segments")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                }
                            } else {
                                // Lightweight placeholder to avoid touching pipeline before ready
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Preparing Studio…")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Scenes Yet",
                        systemImage: "film.stack",
                        description: Text("Create a story in the Create tab to get started")
                    )
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Studio")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(
                    project: appState.currentProject,
                    selectedFormat: $exportFormat,
                    showShareSheet: $showShareSheet,
                    exportedContent: $exportedContent
                )
            }
            #if os(iOS)
            .sheet(isPresented: $showShareSheet) {
                if let project = appState.currentProject {
                    ShareSheet(activityItems: [exportedContent])
                }
            }
            #endif
            .sheet(isPresented: $showPaywallSheet) {
                PaywallSheet()
            }
            .sheet(isPresented: $showClaimSheet) {
                ClaimIncludedClipSheet()
            }
            .alert("Generation Error", isPresented: $showGenerationAlert) {
                Button("OK") { }
            } message: {
                Text(generationAlertMessage)
            }
            .task {
                await creditWallet.refresh()
            }
            .onAppear {
                // Defer pipeline-driven UI until after first frame to avoid any race conditions
                DispatchQueue.main.async { viewReady = true }
            }
        }
    }
    
    // MARK: - Scene Card with Generation
    @ViewBuilder
    private func SceneCardWithGeneration(segment: PromptSegment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Original Scene Card
            SceneCard(segment: segment)
            
            // Continuity Validation
            let sceneModel = segment.toSceneModel()
            let validation = continuityEngine.validate(sceneModel)
            let isValid = (validation["ok"] as? Bool) ?? false
            
            HStack {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isValid ? .green : .orange)
                
                Text(isValid ? "Continuity OK" : "Continuity Issues")
                    .font(.caption)
                    .foregroundColor(isValid ? .green : .orange)
                
                Spacer()
                
                // Generate Button
                Button(action: { generateClip(for: sceneModel) }) {
                    HStack(spacing: 4) {
                        if soraService.isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text("Generate Clip")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(soraService.isGenerating || creditWallet.balance == 0)
            }
            
            // Generation Progress
            if soraService.isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(soraService.generationProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Video Preview
            if let previewURL = soraService.previewURL {
                AsyncImage(url: previewURL) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(ProgressView())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Generate Clip
    private func generateClip(for scene: SceneModel) {
        Task {
            do {
                // Check credits
                guard creditWallet.balance > 0 else {
                    if !firstClipService.hasClaimedFirstClip {
                        showClaimSheet = true
                    } else {
                        showPaywallSheet = true
                    }
                    return
                }
                
                // Validate scene
                let validation = continuityEngine.validate(scene)
                guard (validation["ok"] as? Bool) == true else {
                    generationAlertMessage = (validation["issues"] as? [String])?.joined(separator: "\n") ?? "Unknown continuity issue"
                    showGenerationAlert = true
                    return
                }
                
                // Consume credit
                let remaining = try await creditWallet.consume(amount: 1)
                
                // Enhance prompt
                let enhancedPrompt = continuityEngine.enhancePrompt(for: scene)
                
                // Generate video
                if let taskId = try await soraService.generate(prompt: enhancedPrompt) {
                    // Poll for completion
                    if let videoURL = try await soraService.pollForCompletion(taskId: taskId) {
                        soraService.previewURL = videoURL
                        
                        // Update telemetry if opted-in
                        if shareTelemetry {
                            continuityEngine.updateTelemetry(word: "wand", appeared: true) // Example
                        }
                        
                        // Save clip job to Core Data
                        saveClipJob(sceneId: scene.id, taskId: taskId, videoURL: videoURL.absoluteString)
                    }
                }
            } catch {
                generationAlertMessage = "Generation failed: \(error.localizedDescription)"
                showGenerationAlert = true
            }
        }
    }
    
    // MARK: - Save Clip Job
    private func saveClipJob(sceneId: Int, taskId: String, videoURL: String) {
        let clipJob = ClipJob(context: context)
        clipJob.id = UUID()
        clipJob.scene_id = Int32(sceneId)
        clipJob.taskId = taskId
        clipJob.status = "completed"
        clipJob.videoURL = videoURL
        clipJob.createdAt = Date()
        clipJob.updatedAt = Date()
        
        try? context.save()
    }
}
