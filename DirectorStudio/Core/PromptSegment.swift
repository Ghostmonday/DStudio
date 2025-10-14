import Foundation

// MARK: - Prompt Segment Model
struct PromptSegment: Codable, Identifiable {
    let id = UUID()
    let index: Int
    let duration: Int // Target duration in seconds
    let content: String
    let characters: [String]
    let setting: String
    let action: String
    let continuityNotes: String
    var cinematicTags: CinematicTaxonomy?
    
    enum CodingKeys: String, CodingKey {
        case index, duration, content, characters, setting, action
        case continuityNotes = "continuity_notes"
    }
}
