import Foundation

// MARK: - Prompt Segment Model
public struct PromptSegment: Codable, Identifiable {
    public let id = UUID()
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
    
    public init(index: Int, duration: Int, content: String, characters: [String], setting: String, action: String, continuityNotes: String, location: String, props: [String], tone: String) {
        self.index = index
        self.duration = duration
        self.content = content
        self.characters = characters
        self.setting = setting
        self.action = action
        self.continuityNotes = continuityNotes
        self.location = location
        self.props = props
        self.tone = tone
    }
    
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
