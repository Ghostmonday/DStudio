import SwiftUI

// MARK: - STUDIO TAB - Video Generation Interface
struct StudioView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    
    // Safe service initializations
    @StateObject private var soraService = SoraService(apiKey: "placeholder")
    @StateObject private var creditWallet = CreditWallet()
    
    @State private var showExportSheet = false
    @State private var exportFormat: ExportFormat = .screenplay
    @State private var showShareSheet = false
    @State private var exportedContent = ""
    @State private var showPaywallSheet = false
    @State private var showClaimSheet = false
    @State private var showGenerationAlert = false
    @State private var generationAlertMessage = ""
    @State private var shareTelemetry = false
    
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
                            projectHeaderSection(project: project)
                            
                            // Segments Section
                            segmentsSection(project: project)
                            
                            // Credits Section
                            creditsSection
                        }
                        .padding()
                    }
                } else {
                    // No Project State
                    emptyStateView
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
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [exportedContent])
            }
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
        }
    }
    
    // MARK: - Project Header Section
    
    private func projectHeaderSection(project: Project) -> some View {
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
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Segments Section
    
    private func segmentsSection(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenes")
                .font(.headline)
                .foregroundColor(.white)
            
            if project.segments.isEmpty {
                // Empty state for no segments
                VStack(spacing: 12) {
                    Image(systemName: "film")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No segments available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Process a story in the Create tab to generate scenes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            } else {
                // Segments list
                LazyVStack(spacing: 12) {
                    ForEach(project.segments, id: \.id) { segment in
                        SceneCardWithVideoGeneration(
                            segment: segment,
                            soraService: soraService
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Credits")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Top Up") {
                    showPaywallSheet = true
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("\(creditWallet.balance) credits remaining")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Usage breakdown
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Story Processing:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("~500 credits/story")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Video Generation:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("14 credits/20s clip")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "film")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Create a new project in the Create tab to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Scene Card with Video Generation
struct SceneCardWithVideoGeneration: View {
    let segment: PromptSegment
    @ObservedObject var soraService: SoraService
    @State private var isGenerating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var generatedVideoURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Scene Header
            sceneHeader
            
            // Scene Content
            Text(segment.content)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            
            // Cinematic Tags
            if let tags = segment.cinematicTags {
                cinematicTagsView(tags: tags)
            }
            
            // Video Generation Button
            videoGenerationButton
            
            // Video Preview
            if let videoURL = generatedVideoURL {
                videoPreviewSection(url: videoURL)
            }
            
            // Generation Progress
            if isGenerating && !soraService.generationProgress.isEmpty {
                Text(soraService.generationProgress)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .alert("Generation Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Scene Header
    
    private var sceneHeader: some View {
        HStack {
            Text("Scene \(segment.index)")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 8) {
                // Duration badge
                Text("\(segment.duration)s")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.purple)
                
                // Generation status badge
                if generatedVideoURL != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Cinematic Tags View
    
    private func cinematicTagsView(tags: CinematicTaxonomy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Tag(text: tags.shotType, icon: "camera")
                Tag(text: tags.lighting, icon: "light.max")
                Tag(text: tags.emotionalTone, icon: "sparkles")
                Tag(text: tags.cameraMovement, icon: "arrow.triangle.2.circlepath")
            }
        }
    }
    
    // MARK: - Video Generation Button
    
    private var videoGenerationButton: some View {
        Button(action: generateVideo) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: generatedVideoURL != nil ? "arrow.clockwise" : "play.circle.fill")
                }
                
                Text(isGenerating ? "Generating..." : (generatedVideoURL != nil ? "Regenerate Video" : "Generate Video"))
                
                Spacer()
                
                if !isGenerating {
                    Text("$1.12")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .foregroundColor(.white)
        }
        .disabled(isGenerating)
        .padding()
        .background(
            LinearGradient(
                colors: isGenerating ? [.gray, .gray] : [.purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
    
    // MARK: - Video Preview Section
    
    private func videoPreviewSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated Video")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Video player or preview
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                    
                    ProgressView("Loading video...")
                        .foregroundColor(.white)
                }
            }
            
            // Download/Share buttons
            HStack(spacing: 12) {
                Button(action: { /* Download */ }) {
                    Label("Download", systemImage: "arrow.down.circle")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Button(action: { /* Share */ }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Generate Video Action
    
    private func generateVideo() {
        isGenerating = true
        
        // Track video generation cost
        CostMetricsManager.shared.trackVideoGeneration(
            sceneId: segment.id.uuidString,
            durationSeconds: segment.duration,
            userSelectedTier: "20sec"
        )
        
        Task {
            do {
                // Start video generation
                if let taskId = try await soraService.generate(prompt: segment.content) {
                    // Poll for completion
                    if let url = try await soraService.pollForCompletion(taskId: taskId) {
                        await MainActor.run {
                            generatedVideoURL = url
                            soraService.previewURL = url
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Generation failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
}






// MARK: - Sheet Views


#Preview {
    StudioView()
        .environmentObject(AppState())
        .environmentObject(DirectorStudioPipeline())
}