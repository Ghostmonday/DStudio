import Foundation
import SwiftUI

// MARK: - Story Analysis Models
struct StoryAnalysis: Codable {
    let characters: [Character]
    let locations: [Location]
    let scenes: [Scene]
    let dialogueBlocks: [DialogueBlock]
    
    struct Character: Codable, Identifiable {
        let id = UUID()
        let name: String
        let role: String
        let description: String
        
        enum CodingKeys: String, CodingKey {
            case name, role, description
        }
    }
    
    struct Location: Codable, Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let description: String
        
        enum CodingKeys: String, CodingKey {
            case name, type, description
        }
    }
    
    struct Scene: Codable, Identifiable {
        let id = UUID()
        let sceneNumber: Int
        let setting: String
        let timeOfDay: String
        let summary: String
        
        enum CodingKeys: String, CodingKey {
            case sceneNumber = "scene_number"
            case setting
            case timeOfDay = "time_of_day"
            case summary
        }
    }
    
    struct DialogueBlock: Codable, Identifiable {
        let id = UUID()
        let character: String
        let dialogue: String
        let context: String
        
        enum CodingKeys: String, CodingKey {
            case character, dialogue, context
        }
    }
}

// MARK: - MODULE 2: Story Analyzer Module
class StoryAnalyzerModule: ObservableObject {
    @Published var isProcessing = false
    @Published var analysis: StoryAnalysis?
    @Published var errorMessage: String?
    
    private let service: AIServiceProtocol
    
    init(service: AIServiceProtocol = DeepSeekService()) {
        self.service = service
    }
    
    func analyze(story: String) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            analysis = nil
        }
        
        let systemPrompt = """
        You are an expert story analyst. Extract and identify:
        1. All characters with their roles and brief descriptions
        2. All locations/settings with types and descriptions
        3. Individual scenes with numbers, settings, time of day, and summaries
        4. Dialogue blocks with character names, dialogue, and context
        
        Return ONLY valid JSON in this exact format:
        {
            "characters": [{"name": "...", "role": "...", "description": "..."}],
            "locations": [{"name": "...", "type": "...", "description": "..."}],
            "scenes": [{"scene_number": 1, "setting": "...", "time_of_day": "...", "summary": "..."}],
            "dialogueBlocks": [{"character": "...", "dialogue": "...", "context": "..."}]
        }
        """
        
        let userPrompt = "Analyze this story:\n\n\(story)"
        
        do {
            let response = try await service.sendRequest(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.3,
                maxTokens: 4000
            )
            
            let jsonData = extractJSON(from: response)
            let decoder = JSONDecoder()
            let storyAnalysis = try decoder.decode(StoryAnalysis.self, from: jsonData)
            
            await MainActor.run {
                analysis = storyAnalysis
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    private func extractJSON(from response: String) -> Data {
        if let jsonStart = response.firstIndex(of: "{"),
           let jsonEnd = response.lastIndex(of: "}") {
            let jsonString = String(response[jsonStart...jsonEnd])
            return jsonString.data(using: .utf8) ?? Data()
        }
        return response.data(using: .utf8) ?? Data()
    }
}
