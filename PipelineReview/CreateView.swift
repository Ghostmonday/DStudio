import SwiftUI

// MARK: - Step Status Enum
enum StepStatus {
    case pending
    case running
    case completed
    case failed(String)
    case skipped
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .skipped: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .running: return "arrow.clockwise"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
}

// MARK: - CREATE TAB - Adaptive Layout
struct CreateView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @State private var projectTitle = ""
    @State private var storyInput = ""
    @State private var selectedRewordType: RewordingType?
    @State private var showPipelineSheet = false
    
    // Individual step toggle states - all configurable
    @State private var isRewordingEnabled = true
    @State private var isStoryAnalysisEnabled = true
    @State private var isSegmentationEnabled = true
    @State private var isCinematicEnabled = true
    @State private var isContinuityEnabled = true
    @State private var isPackagingEnabled = true
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cinematic gradient
                LinearGradient(
                    colors: [.black, Color.purple.opacity(0.2), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: horizontalSizeClass == .regular ? 32 : 28) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "film.stack")
                                .font(.system(size: horizontalSizeClass == .regular ? 64 : 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Your Story Begins Here")
                                .font(horizontalSizeClass == .regular ? .largeTitle : .title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Write, transform, and bring your vision to life")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 32)
                        
                        // Adaptive content width
                        contentView
                            .frame(maxWidth: horizontalSizeClass == .regular ? 800 : .infinity)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Create")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showPipelineSheet) {
                PipelineProgressSheet()
            }
        }
    }
    
    var contentView: some View {
        VStack(spacing: horizontalSizeClass == .regular ? 24 : 20) {
            // Project Title Input
            VStack(alignment: .leading, spacing: 12) {
                Label("Project Title", systemImage: "tag.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter project name", text: $projectTitle)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            // Story Input
            VStack(alignment: .leading, spacing: 12) {
                Label("Your Story", systemImage: "text.quote")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $storyInput)
                    .frame(height: horizontalSizeClass == .regular ? 240 : 180)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            // Individual Pipeline Steps
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pipeline Steps")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Control each step individually - no black box")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Individual Step Controls
                VStack(spacing: 16) {
                    // Step 1: Rewording
                    IndividualStepView(
                        stepNumber: 1,
                        title: "Rewording",
                        icon: "wand.and.stars",
                        description: "Transform your writing style",
                        isEnabled: $isRewordingEnabled
                    )
                    
                    // Step 2: Story Analysis
                    IndividualStepView(
                        stepNumber: 2,
                        title: "Story Analysis",
                        icon: "doc.text.magnifyingglass",
                        description: "Extract characters, locations, scenes",
                        isEnabled: $isStoryAnalysisEnabled
                    )
                    
                    // Step 3: Segmentation
                    IndividualStepView(
                        stepNumber: 3,
                        title: "Prompt Segmentation",
                        icon: "rectangle.split.3x1",
                        description: "Break into video-ready segments",
                        isEnabled: $isSegmentationEnabled
                    )
                    
                    // Step 4: Cinematic Analysis
                    IndividualStepView(
                        stepNumber: 4,
                        title: "Cinematic Taxonomy",
                        icon: "camera.aperture",
                        description: "Add camera angles and lighting",
                        isEnabled: $isCinematicEnabled
                    )
                    
                    // Step 5: Continuity Anchors
                    IndividualStepView(
                        stepNumber: 5,
                        title: "Continuity Anchors",
                        icon: "link",
                        description: "Generate visual continuity markers",
                        isEnabled: $isContinuityEnabled
                    )
                    
                    // Step 6: Packaging
                    IndividualStepView(
                        stepNumber: 6,
                        title: "Final Packaging",
                        icon: "shippingbox",
                        description: "Package everything for export",
                        isEnabled: $isPackagingEnabled
                    )
                }
            }
            
            // Run Pipeline Button
            Button(action: {
                showPipelineSheet = true
                Task {
                    await pipeline.runFullPipeline(
                        story: storyInput,
                        rewordType: selectedRewordType,
                        projectTitle: projectTitle.isEmpty ? "Untitled Project" : projectTitle,
                        enableTransform: isRewordingEnabled,
                        enableCinematic: isCinematicEnabled,
                        enableBreakdown: isSegmentationEnabled
                    )
                    
                    // Save to app state
                    if pipeline.completedSteps.count == 6 {
                        let newProject = Project(
                            id: UUID(),
                            title: projectTitle.isEmpty ? "Untitled Project" : projectTitle,
                            originalStory: storyInput,
                            rewordedStory: pipeline.rewordingModule.result.isEmpty ? nil : pipeline.rewordingModule.result,
                            analysis: StoryAnalysisCache(
                                characterCount: pipeline.storyAnalyzer.analysis?.characters.count ?? 0,
                                locationCount: pipeline.storyAnalyzer.analysis?.locations.count ?? 0,
                                sceneCount: pipeline.storyAnalyzer.analysis?.scenes.count ?? 0
                            ),
                            segments: pipeline.segmentationModule.segments,
                            continuityAnchors: pipeline.continuityModule.anchors.map {
                                ContinuityAnchorCache(
                                    id: UUID(),
                                    characterName: $0.characterName,
                                    visualDescription: $0.visualDescription
                                )
                            },
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        
                        await MainActor.run {
                            appState.projects.append(newProject)
                            appState.currentProject = newProject
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                    Text("Process with AI")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .purple.opacity(0.5), radius: 10)
            }
            .disabled(storyInput.isEmpty || pipeline.isRunning || !DeepSeekConfig.hasValidAPIKey())
            .padding(.horizontal)
            .padding(.top, 8)
            
            if !DeepSeekConfig.hasValidAPIKey() {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("API Key Required")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    Text("Please configure your DeepSeek API key in Settings to use AI features.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if !storyInput.isEmpty && !pipeline.isRunning {
                // Dynamic status message based on enabled steps
                let enabledSteps = [isRewordingEnabled, isStoryAnalysisEnabled, isSegmentationEnabled, isCinematicEnabled, isContinuityEnabled, isPackagingEnabled].filter { $0 }.count
                Text(enabledSteps > 0 ? "This will run \(enabledSteps) pipeline step\(enabledSteps == 1 ? "" : "s")" : "No pipeline steps enabled")
                    .font(.caption)
                    .foregroundColor(enabledSteps > 0 ? .gray : .orange)
            }
        }
    }
}
