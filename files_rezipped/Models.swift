import Foundation
import SwiftUI

// MARK: - Core Data Models

// MARK: - Project Model
struct ProjectModel: Identifiable, Codable {
    let id: UUID
    var title: String
    var story: String
    let createdAt: Date
    var updatedAt: Date
    var segments: [PromptSegment]
    var analysis: StoryAnalysis?
    
    init(
        id: UUID = UUID(),
        title: String,
        story: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        segments: [PromptSegment] = [],
        analysis: StoryAnalysis? = nil
    ) {
        self.id = id
        self.title = title
        self.story = story
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.segments = segments
        self.analysis = analysis
    }
}

// MARK: - Prompt Segment
struct PromptSegment: Identifiable, Codable {
    let id: UUID
    let index: Int
    var content: String
    let duration: Int
    var cinematicTags: CinematicTags?
    var videoURL: URL?
    var generationStatus: GenerationStatus
    
    init(
        id: UUID = UUID(),
        index: Int,
        content: String,
        duration: Int,
        cinematicTags: CinematicTags? = nil,
        videoURL: URL? = nil,
        generationStatus: GenerationStatus = .pending
    ) {
        self.id = id
        self.index = index
        self.content = content
        self.duration = duration
        self.cinematicTags = cinematicTags
        self.videoURL = videoURL
        self.generationStatus = generationStatus
    }
    
    enum GenerationStatus: String, Codable {
        case pending
        case generating
        case complete
        case failed
    }
}

// MARK: - Cinematic Tags
struct CinematicTags: Codable {
    let shotType: String
    let lighting: String
    let emotionalTone: String
    let cameraMovement: String?
    let colorPalette: String?
    let atmosphere: String?
    
    init(
        shotType: String,
        lighting: String,
        emotionalTone: String,
        cameraMovement: String? = nil,
        colorPalette: String? = nil,
        atmosphere: String? = nil
    ) {
        self.shotType = shotType
        self.lighting = lighting
        self.emotionalTone = emotionalTone
        self.cameraMovement = cameraMovement
        self.colorPalette = colorPalette
        self.atmosphere = atmosphere
    }
}

// MARK: - Story Analysis
struct StoryAnalysis: Codable {
    let characterCount: Int
    let sceneCount: Int
    let estimatedDuration: Int
    let complexity: StoryComplexity
    let themes: [String]
    let recommendedTier: String
    
    enum StoryComplexity: String, Codable {
        case simple
        case moderate
        case complex
    }
}

// MARK: - Director Studio Project (Legacy Support)
struct DirectorStudioProject: Identifiable, Codable {
    let id: UUID
    var title: String
    let screenplayId: UUID
    var scenes: [DirectorStudioScene]
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        screenplayId: UUID = UUID(),
        scenes: [DirectorStudioScene] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.screenplayId = screenplayId
        self.scenes = scenes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Director Studio Scene (Legacy Support)
struct DirectorStudioScene: Identifiable, Codable {
    let id: UUID
    let sceneNumber: Int
    var sceneHeading: String
    var action: String
    var dialogue: [DialogueLine]
    var visualPrompt: String?
    var status: SceneStatus
    
    init(
        id: UUID = UUID(),
        sceneNumber: Int,
        sceneHeading: String,
        action: String,
        dialogue: [DialogueLine] = [],
        visualPrompt: String? = nil,
        status: SceneStatus = .draft
    ) {
        self.id = id
        self.sceneNumber = sceneNumber
        self.sceneHeading = sceneHeading
        self.action = action
        self.dialogue = dialogue
        self.visualPrompt = visualPrompt
        self.status = status
    }
    
    enum SceneStatus: String, Codable {
        case draft
        case ready
        case generating
        case complete
    }
}

// MARK: - Dialogue Line
struct DialogueLine: Identifiable, Codable {
    let id: UUID
    let character: String
    let text: String
    let parenthetical: String?
    
    init(
        id: UUID = UUID(),
        character: String,
        text: String,
        parenthetical: String? = nil
    ) {
        self.id = id
        self.character = character
        self.text = text
        self.parenthetical = parenthetical
    }
}

// MARK: - Scene Control Config
struct SceneControlConfig: Codable {
    var targetDuration: Int
    var shotPreference: ShotPreference
    var pacing: Pacing
    
    init(
        targetDuration: Int = 20,
        shotPreference: ShotPreference = .balanced,
        pacing: Pacing = .moderate
    ) {
        self.targetDuration = targetDuration
        self.shotPreference = shotPreference
        self.pacing = pacing
    }
    
    enum ShotPreference: String, Codable, CaseIterable {
        case closeUps = "Close-ups"
        case wideShots = "Wide Shots"
        case balanced = "Balanced"
    }
    
    enum Pacing: String, Codable, CaseIterable {
        case slow = "Slow"
        case moderate = "Moderate"
        case fast = "Fast"
    }
}

// MARK: - Pipeline Processing Result
struct PipelineResult {
    let segments: [PromptSegment]
    let analysis: StoryAnalysis
    let processingTime: TimeInterval
    let success: Bool
    let error: Error?
}

// MARK: - Processing Errors
enum ProcessingError: Error, LocalizedError {
    case emptyInput
    case apiKeyMissing
    case apiCallFailed(String)
    case segmentationFailed
    case analysisfailed
    case rewordingFailed
    case packagingFailed
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Story input cannot be empty"
        case .apiKeyMissing:
            return "API key is not configured"
        case .apiCallFailed(let message):
            return "API call failed: \(message)"
        case .segmentationFailed:
            return "Failed to segment story into scenes"
        case .analysisfailed:
            return "Failed to analyze story"
        case .rewordingFailed:
            return "Failed to reword prompts"
        case .packagingFailed:
            return "Failed to package prompts"
        case .invalidConfiguration:
            return "Invalid pipeline configuration"
        }
    }
}

// MARK: - Tag Component Helper
struct Tag: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.2))
        .foregroundColor(.purple)
        .cornerRadius(6)
    }
}
