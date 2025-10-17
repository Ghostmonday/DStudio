import Foundation
import SwiftUI

// MARK: - MODULE 4: Cinematic Taxonomy Module
class CinematicTaxonomyModule: ObservableObject {
    @Published var isProcessing = false
    @Published var taxonomy: CinematicTaxonomy?
    @Published var errorMessage: String?
    
    private let service: AIServiceProtocol
    
    init(service: AIServiceProtocol = DeepSeekService()) {
        self.service = service
    }
    
    func analyzeCinematic(scene: String) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            taxonomy = nil
        }
        
        let systemPrompt = """
        You are a cinematography expert. Analyze the scene and provide detailed cinematic taxonomy:
        
        - shot_type: (e.g., "Close-up", "Wide shot", "Medium shot", "Extreme close-up")
        - camera_angle: (e.g., "Eye level", "Low angle", "High angle", "Dutch angle")
        - framing: (e.g., "Rule of thirds", "Center frame", "Symmetrical")
        - lighting: (e.g., "Natural light", "Dramatic chiaroscuro", "Soft diffused", "Golden hour")
        - color_palette: (e.g., "Warm tones", "Cool blues", "Desaturated", "High contrast")
        - lens_type: (e.g., "Wide angle 24mm", "Standard 50mm", "Telephoto 85mm")
        - camera_movement: (e.g., "Static", "Dolly in", "Pan right", "Handheld", "Steadicam tracking")
        - emotional_tone: (e.g., "Tense", "Melancholic", "Triumphant", "Mysterious")
        - visual_style: (e.g., "Film noir", "Naturalistic", "Surreal", "Documentary")
        - action_cues: Array of key actions/beats in the scene
        
        Return ONLY valid JSON in this exact format:
        {
            "shot_type": "...",
            "camera_angle": "...",
            "framing": "...",
            "lighting": "...",
            "color_palette": "...",
            "lens_type": "...",
            "camera_movement": "...",
            "emotional_tone": "...",
            "visual_style": "...",
            "action_cues": ["...", "..."]
        }
        """
        
        let userPrompt = "Analyze this scene cinematically:\n\n\(scene)"
        
        do {
            let response = try await service.sendRequest(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.3,
                maxTokens: 1500
            )
            
            let jsonData = extractJSON(from: response)
            let decoder = JSONDecoder()
            let cinematicTaxonomy = try decoder.decode(CinematicTaxonomy.self, from: jsonData)
            
            await MainActor.run {
                taxonomy = cinematicTaxonomy
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
