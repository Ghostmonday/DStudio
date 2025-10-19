import SwiftUI

// MARK: - STUDIO TAB - Video Generation Interface
struct StudioView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    
    // Safe service initializations (no problematic context/API key issues)
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
                                    LazyVStack(spacing: 12) {
                                        ForEach(project.segments, id: \.id) { segment in
                                            SceneCardWithVideoGeneration(segment: segment, soraService: soraService)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            
                            // Credits Section
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
                                    
                                    Text("5 credits remaining")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                } else {
                    // No Project State
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

// MARK: - Scene Card with Video Generation
struct SceneCardWithVideoGeneration: View {
    let segment: PromptSegment
    @ObservedObject var soraService: SoraService
    @State private var isGenerating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scene \(segment.index)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(segment.duration)s")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.purple)
            }
            
            Text(segment.content)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            
            if let tags = segment.cinematicTags {
                HStack(spacing: 8) {
                    Tag(text: tags.shotType, icon: "camera")
                    Tag(text: tags.lighting, icon: "light.max")
                    Tag(text: tags.emotionalTone, icon: "sparkles")
                }
            }
            
            // Video Generation Button
            Button(action: generateVideo) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    
                    Text(isGenerating ? "Generating..." : "Generate Video")
                    
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
            
            // Video Preview
            if let previewURL = soraService.previewURL {
                AsyncImage(url: previewURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView("Rendering...")
                        .frame(height: 100)
                }
                .frame(maxHeight: 200)
            }
            
            // Generation Progress
            if soraService.isGenerating && !soraService.generationProgress.isEmpty {
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
    
    private func generateVideo() {
        isGenerating = true
        
        Task {
            do {
                if let taskId = try await soraService.generate(prompt: segment.content) {
                    // Poll for completion
                    if let url = try await soraService.pollForCompletion(taskId: taskId) {
                        soraService.previewURL = url
                    }
                }
            } catch {
                alertMessage = "Generation failed: \(error.localizedDescription)"
                showAlert = true
            }
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
}

#Preview {
    StudioView()
        .environmentObject(AppState())
        .environmentObject(DirectorStudioPipeline())
}