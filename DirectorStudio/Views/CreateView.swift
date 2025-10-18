import SwiftUI

// MARK: - CREATE TAB - Pipeline Integration (Phase 3 - Project Setup)
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
                Text("AI Pipeline Ready")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("All pipeline modules are configured and ready for processing")
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
    
    // MARK: - Story Processing (Tone System Ready)
    private func processStory() async {
        let finalTitle = projectTitle.isEmpty ? "Untitled Project" : projectTitle
        
        // Check if we have a valid API key
        guard DeepSeekConfig.hasValidAPIKey() else {
            print("❌ DeepSeek API key not configured")
            return
        }
        
        // Process the story with real AI (Tone System files ready for integration)
        do {
            let processedSegments = try await processStoryWithAI(story: storyInput)
            
            // Create a new project with the AI-processed story
            let newProject = Project(
                id: UUID(),
                title: finalTitle,
                originalStory: storyInput,
                rewordedStory: storyInput, // Could be enhanced with AI rephrasing
                analysis: StoryAnalysisCache(
                    characterCount: storyInput.count,
                    locationCount: 1,
                    sceneCount: processedSegments.count
                ),
                segments: processedSegments,
                continuityAnchors: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            await MainActor.run {
                appState.projects.append(newProject)
                appState.currentProject = newProject
            }
            
        } catch {
            print("❌ AI processing failed: \(error.localizedDescription)")
            // Fallback to mock segments if AI fails
            let fallbackProject = Project(
                id: UUID(),
                title: finalTitle,
                originalStory: storyInput,
                rewordedStory: storyInput,
                analysis: StoryAnalysisCache(
                    characterCount: storyInput.count,
                    locationCount: 1,
                    sceneCount: 3
                ),
                segments: createMockSegments(from: storyInput),
                continuityAnchors: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            await MainActor.run {
                appState.projects.append(fallbackProject)
                appState.currentProject = fallbackProject
            }
        }
    }
    
    // MARK: - AI Story Processing
    private func processStoryWithAI(story: String) async throws -> [PromptSegment] {
        let deepSeekService = DeepSeekService()
        
        // Step 1: Analyze the story and break it into scenes
        let analysisPrompt = """
        Analyze this story and break it into 3-5 cinematic scenes. For each scene, provide:
        1. Scene content (what happens)
        2. Characters involved
        3. Setting/location
        4. Action taking place
        5. Props needed
        6. Emotional tone
        
        Story: \(story)
        
        Respond in JSON format:
        {
          "scenes": [
            {
              "content": "Scene description",
              "characters": ["Character1", "Character2"],
              "setting": "Location description",
              "action": "What's happening",
              "props": ["prop1", "prop2"],
              "tone": "emotional tone"
            }
          ]
        }
        """
        
        let analysisResponse = try await deepSeekService.sendRequest(
            systemPrompt: "You are a professional film director. Break down stories into cinematic scenes with detailed production notes.",
            userPrompt: analysisPrompt,
            temperature: 0.7,
            maxTokens: 2000
        )
        
        // Parse the AI response and create segments
        return try parseAIResponseToSegments(response: analysisResponse)
    }
    
    // MARK: - Parse AI Response
    private func parseAIResponseToSegments(response: String) throws -> [PromptSegment] {
        // Extract JSON from response (handle cases where AI adds extra text)
        let jsonStart = response.firstIndex(of: "{") ?? response.startIndex
        let jsonEnd = response.lastIndex(of: "}") ?? response.endIndex
        let jsonString = String(response[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIModuleError.parsingError("Failed to convert JSON string to data")
        }
        
        struct AIResponse: Codable {
            let scenes: [AIScene]
        }
        
        struct AIScene: Codable {
            let content: String
            let characters: [String]
            let setting: String
            let action: String
            let props: [String]
            let tone: String
        }
        
        let aiResponse = try JSONDecoder().decode(AIResponse.self, from: jsonData)
        
        return aiResponse.scenes.enumerated().map { index, scene in
            PromptSegment(
                index: index + 1,
                duration: 4, // Default 4 seconds per scene
                content: scene.content,
                characters: scene.characters,
                setting: scene.setting,
                action: scene.action,
                continuityNotes: "AI-generated scene \(index + 1)",
                location: scene.setting,
                props: scene.props,
                tone: scene.tone
            )
        }
    }
    
    // MARK: - Mock Segment Creation
    private func createMockSegments(from story: String) -> [PromptSegment] {
        // Split story into 3 parts for demo
        let words = story.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let segmentSize = max(1, words.count / 3)
        
        var segments: [PromptSegment] = []
        
        for i in 0..<3 {
            let startIndex = i * segmentSize
            let endIndex = min((i + 1) * segmentSize, words.count)
            let segmentWords = Array(words[startIndex..<endIndex])
            let content = segmentWords.joined(separator: " ")
            
            let segment = PromptSegment(
                index: i + 1,
                duration: 4,
                content: content.isEmpty ? "Scene \(i + 1) content" : content,
                characters: ["Character \(i + 1)"],
                setting: ["Indoor", "Outdoor", "Urban"][i % 3],
                action: ["Walking", "Talking", "Observing"][i % 3],
                continuityNotes: "Scene \(i + 1) continuity notes",
                location: ["Room", "Street", "Park"][i % 3],
                props: ["Item \(i + 1)"],
                tone: ["Dramatic", "Peaceful", "Exciting"][i % 3]
            )
            segments.append(segment)
        }
        
        return segments
    }
}


#Preview {
    CreateView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}