import Foundation
import SwiftUI

// MARK: - Continuity Anchor Model
struct ContinuityAnchor: Codable, Identifiable {
    let id = UUID()
    let characterName: String
    let visualDescription: String
    let costumes: [String]
    let props: [String]
    let appearanceNotes: String
    let sceneReferences: [Int]
    
    enum CodingKeys: String, CodingKey {
        case characterName = "character_name"
        case visualDescription = "visual_description"
        case costumes
        case props
        case appearanceNotes = "appearance_notes"
        case sceneReferences = "scene_references"
    }
}

// MARK: - MODULE 5: Continuity Anchor Module
class ContinuityAnchorModule: ObservableObject {
    @Published var isProcessing = false
    @Published var anchors: [ContinuityAnchor] = []
    @Published var errorMessage: String?
    
    private let service: AIServiceProtocol
    
    init(service: AIServiceProtocol = DeepSeekService()) {
        self.service = service
    }
    
    func generateAnchors(story: String) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            anchors = []
        }
        
        let systemPrompt = """
        You are a script supervisor specializing in continuity. Extract continuity anchors for all characters:
        
        For each character, provide:
        - character_name: Full character name
        - visual_description: Detailed physical appearance (height, build, features, hair, etc.)
        - costumes: Array of clothing/costume descriptions worn throughout
        - props: Array of props associated with this character
        - appearance_notes: Any important visual continuity notes
        - scene_references: Array of scene numbers where this character appears
        
        Return ONLY valid JSON array:
        [
            {
                "character_name": "...",
                "visual_description": "...",
                "costumes": ["..."],
                "props": ["..."],
                "appearance_notes": "...",
                "scene_references": [1, 3, 5]
            }
        ]
        """
        
        let userPrompt = "Generate continuity anchors for this story:\n\n\(story)"
        
        do {
            let response = try await service.sendRequest(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.3,
                maxTokens: 3000
            )
            
            let jsonData = extractJSON(from: response)
            let decoder = JSONDecoder()
            let continuityAnchors = try decoder.decode([ContinuityAnchor].self, from: jsonData)
            
            await MainActor.run {
                anchors = continuityAnchors
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
        if let jsonStart = response.firstIndex(of: "["),
           let jsonEnd = response.lastIndex(of: "]") {
            let jsonString = String(response[jsonStart...jsonEnd])
            return jsonString.data(using: .utf8) ?? Data()
        }
        return response.data(using: .utf8) ?? Data()
    }
}
