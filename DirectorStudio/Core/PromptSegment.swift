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
    
    // New properties for continuity engine
    let location: String
    let props: [String]
    let tone: String
    
    enum CodingKeys: String, CodingKey {
        case index, duration, content, characters, setting, action
        case continuityNotes = "continuity_notes"
        case location, props, tone
    }
    
    // Convert to SceneModel for continuity validation
    func toSceneModel() -> SceneModel {
        return SceneModel(
            id: index,
            location: location,
            characters: characters,
            props: props,
            prompt: content,
            tone: tone
        )
    }
}

// MARK: - Scene Model for Continuity Engine
struct SceneModel: Codable, Identifiable, Equatable {
    let id: Int
    let location: String
    let characters: [String]
    let props: [String]
    let prompt: String
    let tone: String
    
    static func == (lhs: SceneModel, rhs: SceneModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.location == rhs.location &&
               lhs.characters == rhs.characters &&
               lhs.props == rhs.props &&
               lhs.prompt == rhs.prompt &&
               lhs.tone == rhs.tone
    }
}
