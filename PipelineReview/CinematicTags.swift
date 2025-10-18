import Foundation

// MARK: - Cinematic Taxonomy Model
public struct CinematicTaxonomy: Codable {
    let shotType: String
    let cameraAngle: String
    let framing: String
    let lighting: String
    let colorPalette: String
    let lensType: String
    let cameraMovement: String
    let emotionalTone: String
    let visualStyle: String
    let actionCues: [String]
    
    enum CodingKeys: String, CodingKey {
        case shotType = "shot_type"
        case cameraAngle = "camera_angle"
        case framing
        case lighting
        case colorPalette = "color_palette"
        case lensType = "lens_type"
        case cameraMovement = "camera_movement"
        case emotionalTone = "emotional_tone"
        case visualStyle = "visual_style"
        case actionCues = "action_cues"
    }
}
