import SwiftUI

// MARK: - CREATE TAB - Pipeline Integration (Phase 2)
struct CreateView: View {
    @EnvironmentObject var appState: AppState
    @State private var projectTitle = ""
    @State private var storyInput = ""
    @State private var showPipelineSheet = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showPipelineSheet) {
            PipelineProgressSheet()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            
            Text("AI Story Processor")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Transform your story into cinematic video prompts")
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
        }
    }
    
    // MARK: - Story Input Section
    private var storyInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Story")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $storyInput)
                .frame(minHeight: 200)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .font(.body)
            
            Text("\(storyInput.count) characters")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Pipeline Configuration Section
    private var pipelineConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pipeline Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Text("Advanced pipeline system coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Individual step toggles and real-time progress will be available here.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Process Button
    private var processButton: some View {
        Button(action: {
            showPipelineSheet = true
            Task {
                await processStory()
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
        .disabled(storyInput.isEmpty || !DeepSeekConfig.hasValidAPIKey())
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - API Key Warning
    private var apiKeyWarning: some View {
        Group {
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
            }
        }
    }
    
    // MARK: - Story Processing
    private func processStory() async {
        let finalTitle = projectTitle.isEmpty ? "Untitled Project" : projectTitle
        
        // Create a simple project for now (advanced pipeline coming soon)
        let newProject = Project(
            id: UUID(),
            title: finalTitle,
            originalStory: storyInput,
            rewordedStory: nil,
            analysis: nil,
            segments: [],
            continuityAnchors: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await MainActor.run {
            appState.projects.append(newProject)
            appState.currentProject = newProject
        }
    }
}


#Preview {
    CreateView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}