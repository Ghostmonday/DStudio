import SwiftUI

// MARK: - CREATE TAB - Adaptive Layout
struct CreateView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @State private var projectTitle = ""
    @State private var storyInput = ""
    @State private var selectedRewordType: RewordingType?
    @State private var showPipelineSheet = false
    
    // Module toggle states - default all ON
    @State private var isTransformEnabled = true
    @State private var isCinematicEnabled = true
    @State private var isBreakdownEnabled = true
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
            
            // AI Module Toggles
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Modules")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                   Text("Choose which AI features to use") // BugScan: prompt engine UI noop
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Module Toggles
                VStack(spacing: 12) {
                    ModuleToggle(
                        title: "Transform Your Words",
                        icon: "wand.and.stars",
                        description: "Modernize, refine grammar, or restyle your narrative",
                        tooltip: "Uses AI to enhance your writing style and grammar",
                        isEnabled: $isTransformEnabled
                    )
                    .padding(.horizontal)
                    
                    // Show transformation options only if enabled
                    if isTransformEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Transformation Type")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 36) // Align with toggle content
                            
                            Picker("Type", selection: $selectedRewordType) {
                                Text("None").tag(nil as RewordingType?)
                                Divider()
                                ForEach(RewordingType.allCases) { type in
                                    Text(type.rawValue).tag(type as RewordingType?)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.purple)
                            .padding(.horizontal, 36)
                        }
                    }
                    
                    ModuleToggle(
                        title: "Cinematic Taxonomy",
                        icon: "camera.aperture",
                        description: "Add camera angles, lighting, and shot types",
                        tooltip: "Analyzes scenes for optimal cinematography and visual composition",
                        isEnabled: $isCinematicEnabled
                    )
                    .padding(.horizontal)
                    
                    ModuleToggle(
                        title: "Prompt Breakdown",
                        icon: "rectangle.split.3x1",
                        description: "Break story into AI-ready video prompts",
                        tooltip: "Segments your story into 15-second video clips for generation",
                        isEnabled: $isBreakdownEnabled
                    )
                    .padding(.horizontal)
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
                        enableTransform: isTransformEnabled,
                        enableCinematic: isCinematicEnabled,
                        enableBreakdown: isBreakdownEnabled
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
                // Dynamic status message based on enabled modules
                let enabledModules = [isTransformEnabled, isCinematicEnabled, isBreakdownEnabled].filter { $0 }.count
                Text(enabledModules > 0 ? "This will run \(enabledModules) AI module\(enabledModules == 1 ? "" : "s")" : "No AI modules enabled")
                    .font(.caption)
                    .foregroundColor(enabledModules > 0 ? .gray : .orange)
            }
        }
    }
}
