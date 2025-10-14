import SwiftUI

// MARK: - CREATE TAB - Adaptive Layout
struct CreateView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @State private var projectTitle = ""
    @State private var storyInput = ""
    @State private var selectedRewordType: RewordingType?
    @State private var showPipelineSheet = false
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
            
            // Module 1: Rewording Options
            ModuleCard(
                title: "Transform Your Words",
                icon: "wand.and.stars",
                description: "Modernize, refine grammar, or restyle your narrative"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transformation Type")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Picker("Type", selection: $selectedRewordType) {
                        Text("None").tag(nil as RewordingType?)
                        Divider()
                        ForEach(RewordingType.allCases) { type in
                            Text(type.rawValue).tag(type as RewordingType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.purple)
                }
            }
            
            // Module 2 & 3: Coming Soon Preview
            ModuleCard(
                title: "Cinematic Taxonomy",
                icon: "camera.aperture",
                description: "Add camera angles, lighting, and shot types",
                comingSoon: false
            ) {
                Text("Automatically analyzes each scene")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ModuleCard(
                title: "Prompt Breakdown",
                icon: "rectangle.split.3x1",
                description: "Break story into AI-ready video prompts",
                comingSoon: false
            ) {
                Text("Segments your story into 15s scenes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Run Pipeline Button
            Button(action: {
                showPipelineSheet = true
                Task {
                    await pipeline.runFullPipeline(
                        story: storyInput,
                        rewordType: selectedRewordType,
                        projectTitle: projectTitle.isEmpty ? "Untitled Project" : projectTitle
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
            .disabled(storyInput.isEmpty || pipeline.isRunning)
            .padding(.horizontal)
            .padding(.top, 8)
            
            if !storyInput.isEmpty && !pipeline.isRunning {
                Text("This will run all 6 AI modules")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
