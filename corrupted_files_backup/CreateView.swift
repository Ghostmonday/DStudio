import SwiftUI

// MARK: - CREATE TAB - Pipeline Integration
struct CreateView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    
    @State private var projectTitle = ""
    @State private var storyInput = ""
    @State private var selectedTier: StoryTier = .medium
    @State private var selectedVideoDuration: VideoDuration = .twenty
    @State private var showPipelineSheet = false
    @State private var isProcessing = false
    @State private var showCompletionAlert = false
    @State private var processingComplete = false
    @State private var processingError: String?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    enum StoryTier: String, CaseIterable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
        
        var characterLimit: Int {
            switch self {
            case .short: return 500
            case .medium: return 2000
            case .long: return 5000
            }
        }
        
        var price: Double {
            switch self {
            case .short: return 8.08
            case .medium: return 8.16
            case .long: return 8.48
            }
        }
    }
    
    enum VideoDuration: String, CaseIterable {
        case twenty = "20s"
        case thirty = "30s"
        case sixty = "60s"
        
        var seconds: Int {
            switch self {
            case .twenty: return 20
            case .thirty: return 30
            case .sixty: return 60
            }
        }
        
        var price: Double {
            switch self {
            case .twenty: return 1.12
            case .thirty: return 1.68
            case .sixty: return 3.36
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Project Title Input
                        projectTitleSection
                        
                        // Story Input
                        storyInputSection
                        
                        // Pipeline Configuration
                        pipelineConfigurationSection
                        
                        // Process Button
                        processButton
                        
                        // API Key Warning
                        apiKeyWarning
                    }
                    .padding()
                }
            }
            .navigationTitle("Create")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .alert("Processing Complete", isPresented: $showCompletionAlert) {
                Button("View in Studio") {
                    // Switch to Studio tab
                    processingComplete = true
                }
                Button("OK") { }
            } message: {
                Text("Your story has been processed into \(appState.currentProject?.segments.count ?? 0) cinematic scenes!")
            }
            .alert("Processing Error", isPresented: .constant(processingError != nil)) {
                Button("OK") {
                    processingError = nil
                }
            } message: {
                Text(processingError ?? "")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            
            Text("Transform Your Story")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Turn your narrative into stunning cinematic video prompts")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Project Title Section
    private var projectTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Title")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("Enter project title...", text: $projectTitle)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .font(.body)
        }
    }
    
    // MARK: - Story Input Section
    private var storyInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Story")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(storyInput.count) characters")
                    .font(.caption)
                    .foregroundColor(storyInput.count > selectedTier.characterLimit ? .red : .gray)
            }
            
            TextEditor(text: $storyInput)
                .frame(minHeight: 200)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .font(.body)
            
            if storyInput.count > selectedTier.characterLimit {
                Text("⚠️ Story exceeds \(selectedTier.rawValue) tier limit. Consider upgrading or trimming.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Pipeline Configuration Section
    private var pipelineConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Processing Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            // Story Tier Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Story Processing Tier")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    ForEach(StoryTier.allCases, id: \.self) { tier in
                        Button(action: { selectedTier = tier }) {
                            VStack(spacing: 8) {
                                Text(tier.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("\(tier.characterLimit) chars")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Text("$\(String(format: "%.2f", tier.price))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTier == tier
                                    ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTier == tier ? Color.purple : Color.clear, lineWidth: 2)
                            )
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            
            // Video Duration Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Video Duration per Scene")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    ForEach(VideoDuration.allCases, id: \.self) { duration in
                        Button(action: { selectedVideoDuration = duration }) {
                            VStack(spacing: 8) {
                                Text(duration.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("$\(String(format: "%.2f", duration.price))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedVideoDuration == duration
                                    ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedVideoDuration == duration ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            
            // Cost Breakdown
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Estimated Cost")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Story Processing:")
                        Text("Video Generation:")
                        Divider().background(Color.gray)
                        Text("Total:")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.2f", selectedTier.price))")
                        Text("$\(String(format: "%.2f", selectedVideoDuration.price))")
                        Divider().background(Color.gray)
                        Text("$\(String(format: "%.2f", selectedTier.price + selectedVideoDuration.price))")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Process Button
    private var processButton: some View {
        Button(action: processStory) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Processing...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Process Story")
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: canProcess ? [.purple, .pink] : [.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(!canProcess || isProcessing)
    }
    
    // MARK: - API Key Warning
    private var apiKeyWarning: some View {
        Group {
            if !hasValidAPIKey {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("API Key Required")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    Text("Please configure your API key in Settings to use AI features.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canProcess: Bool {
        return !projectTitle.isEmpty
            && !storyInput.isEmpty
            && storyInput.count <= selectedTier.characterLimit
            && hasValidAPIKey
    }
    
    private var hasValidAPIKey: Bool {
        // Check if API key is configured
        // This should check your actual API key configuration
        return true // Replace with actual check
    }
    
    // MARK: - Actions
    
    private func processStory() {
        guard canProcess else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Create new project
                let project = Project(
                    id: UUID(),
                    title: projectTitle,
                    story: storyInput,
                    createdAt: Date()
                )
                
                // Track story processing cost
                CostMetricsManager.shared.trackStoryProcessing(
                    sceneId: project.id.uuidString,
                    characters: storyInput.count,
                    tier: selectedTier.rawValue.lowercased(),
                    inputTokens: 0, // Will be updated when actual API call is made
                    outputTokens: 0
                )
                
                // Process through pipeline
                let segments = try await pipeline.processStory(
                    story: storyInput,
                    projectId: project.id.uuidString
                )
                
                // Update project with segments
                var updatedProject = project
                updatedProject.segments = segments
                
                // Set as current project
                await MainActor.run {
                    appState.currentProject = updatedProject
                    isProcessing = false
                    showCompletionAlert = true
                    
                    // Clear form
                    projectTitle = ""
                    storyInput = ""
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    processingError = "Processing failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    CreateView()
        .environmentObject(AppState())
        .environmentObject(DirectorStudioPipeline())
        .preferredColorScheme(.dark)
}