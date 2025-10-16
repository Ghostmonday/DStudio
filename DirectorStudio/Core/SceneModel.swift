import Foundation

// MARK: - Scene Model
public struct SceneModel: Codable, Identifiable, Equatable {
    public let id: Int
    public let location: String
    public let characters: [String]
    public let props: [String]
    public let prompt: String
    public let tone: String
    
    public init(id: Int, location: String, characters: [String], props: [String], prompt: String, tone: String) {
        self.id = id
        self.location = location
        self.characters = characters
        self.props = props
        self.prompt = prompt
        self.tone = tone
    }
}

// MARK: - Scene Extensions
extension SceneModel {
    /// Creates a SceneModel from a PromptSegment
    public init(from segment: PromptSegment) {
        self.id = segment.index
        self.location = segment.location
        self.characters = segment.characters
        self.props = segment.props
        self.prompt = segment.content
        self.tone = segment.tone
    }
    
    /// Converts to a PromptSegment
    public func toPromptSegment() -> PromptSegment {
        return PromptSegment(
            index: id,
            duration: 0, // Default duration
            content: prompt,
            characters: characters,
            setting: "Unknown Setting",
            action: "Unknown Action",
            continuityNotes: "",
            location: location,
            props: props,
            tone: tone
        )
    }
}
