import Foundation
import SwiftUI

// MARK: - MODULE 3: Prompt Segmentation Module
class PromptSegmentationModule: ObservableObject {
    @Published var isProcessing = false
    @Published var segments: [PromptSegment] = []
    @Published var errorMessage: String?
    
    private let service: AIServiceProtocol
    
    init(service: AIServiceProtocol = DeepSeekService()) {
        self.service = service
    }
    
    func segment(story: String, targetDuration: Int = 15) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            segments = []
        }
        
        let systemPrompt = """
        You are an expert at breaking stories into short video prompt segments. Each segment should be \(targetDuration) seconds of content.
        
        Break the story into logical beats/scenes. For each segment provide:
        - Index number
        - Duration (target \(targetDuration)s)
        - Content (the actual prompt text for video generation)
        - Characters present
        - Setting description
        - Main action
        - Continuity notes (to maintain consistency across segments)
        
        Return ONLY valid JSON array:
        [
            {
                "index": 1,
                "duration": \(targetDuration),
                "content": "...",
                "characters": ["..."],
                "setting": "...",
                "action": "...",
                "continuity_notes": "..."
            }
        ]
        """
        
        let userPrompt = "Break this story into video prompt segments:\n\n\(story)"
        
        do {
            let response = try await service.sendRequest(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.4,
                maxTokens: 4000
            )
            
            let jsonData = extractJSON(from: response)
            let decoder = JSONDecoder()
            let promptSegments = try decoder.decode([PromptSegment].self, from: jsonData)
            
            await MainActor.run {
                segments = promptSegments
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
