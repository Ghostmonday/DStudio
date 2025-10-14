import Foundation
import SwiftUI

// MARK: - MODULE 1: Rewording Module
enum RewordingType: String, CaseIterable, Identifiable {
    case modernizeOldEnglish = "Modernize Old English"
    case improveGrammar = "Improve Grammar"
    case casualTone = "Casual Tone"
    case formalTone = "Formal Tone"
    case poeticStyle = "Poetic Style"
    case fasterPacing = "Faster Pacing"
    case cinematicMood = "Cinematic Mood"
    
    var id: String { rawValue }
    
    var systemPrompt: String {
        switch self {
        case .modernizeOldEnglish:
            return "You are an expert at modernizing archaic or old English text into contemporary, natural language while preserving the original meaning and tone. Make it accessible to modern readers."
        case .improveGrammar:
            return "You are a professional editor specializing in grammar improvement. Fix grammatical errors, improve sentence structure, and enhance clarity without changing the core meaning or voice."
        case .casualTone:
            return "You are a skilled writer who can transform text into a casual, conversational tone. Make it feel natural, approachable, and relatable while keeping the essential message intact."
        case .formalTone:
            return "You are an expert at transforming text into formal, professional language. Elevate the sophistication and polish while maintaining the original meaning."
        case .poeticStyle:
            return "You are a poet who can transform narrative text into poetic, evocative language with vivid imagery and rhythmic flow while preserving the story."
        case .fasterPacing:
            return "You are an editor specializing in pacing. Rewrite the text to be more dynamic, urgent, and fast-paced. Use shorter sentences, active voice, and punchy language."
        case .cinematicMood:
            return "You are a screenwriter who can transform text into cinematic prose with visual richness, atmospheric detail, and dramatic tension suitable for film."
        }
    }
}

class RewordingModule: ObservableObject {
    @Published var isProcessing = false
    @Published var result: String = ""
    @Published var errorMessage: String?
    
    private let service: AIServiceProtocol
    
    init(service: AIServiceProtocol = DeepSeekService()) {
        self.service = service
    }
    
    func reword(text: String, type: RewordingType) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            result = ""
        }
        
        do {
            let userPrompt = "Rewrite the following text:\n\n\(text)"
            let response = try await service.sendRequest(
                systemPrompt: type.systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.7,
                maxTokens: 3000
            )
            
            await MainActor.run {
                result = response
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
}
