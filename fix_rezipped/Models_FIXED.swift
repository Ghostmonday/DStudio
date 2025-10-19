import Foundation
import SwiftUI

// MARK: - Core Data Models

// MARK: - Project Model
struct Project: Identifiable, Codable, Equatable {
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
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Export Methods
    
    func exportAsScreenplay() -> String {
        var screenplay = """
        ═══════════════════════════════════════════════════════════
        TITLE: \(title)
        Generated: \(formatDate(Date()))
        ═══════════════════════════════════════════════════════════
        
        ORIGINAL STORY:
        \(story)
        
        """
        
        if !segments.isEmpty {
            screenplay += """
            ═══════════════════════════════════════════════════════════
            CINEMATIC SCENES (\(segments.count) total)
            ═══════════════════════════════════════════════════════════
            
            """
            
            for segment in segments {
                screenplay += """
                
                SCENE \(segment.index)
                Duration: \(segment.duration) seconds
                ───────────────────────────────────────────────────────────
                \(segment.content)
                
                """
                
                if let tags = segment.cinematicTags {
                    screenplay += """
                    CINEMATIC TAGS:
                    • Shot Type: \(tags.shotType)
                    • Lighting: \(tags.lighting)
                    • Emotional Tone: \(tags.emotionalTone)
                    """
                    
                    if let movement = tags.cameraMovement {
                        screenplay += "\n• Camera Movement: \(movement)"
                    }
                    if let palette = tags.colorPalette {
                        screenplay += "\n• Color Palette: \(palette)"
                    }
                    if let atmosphere = tags.atmosphere {
                        screenplay += "\n• Atmosphere: \(atmosphere)"
                    }
                    
                    screenplay += "\n\n"
                }
            }
        }
        
        screenplay += """
        ═══════════════════════════════════════════════════════════
        End of Screenplay
        ═══════════════════════════════════════════════════════════
        """
        
        return screenplay
    }
    
    func exportAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return """
            {
              "error": "Failed to encode project",
              "message": "\(error.localizedDescription)"
            }
            """
        }
    }
    
    func exportAsPromptList() -> String {
        var prompts = """
        ╔═══════════════════════════════════════════════════════════╗
        ║  DirectorStudio Video Generation Prompts                  ║
        ║  Project: \(title.padding(toLength: 50, withPad: " ", startingAt: 0))║
        ╚═══════════════════════════════════════════════════════════╝
        
        Total Scenes: \(segments.count)
        Total Duration: \(segments.reduce(0) { $0 + $1.duration }) seconds
        Generated: \(formatDate(Date()))
        
        """
        
        for (index, segment) in segments.enumerated() {
            prompts += """
            
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            PROMPT \(index + 1) OF \(segments.count)
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            🎬 SCENE CONTENT:
            \(segment.content)
            
            ⏱️  DURATION: \(segment.duration) seconds
            
            """
            
            if let tags = segment.cinematicTags {
                prompts += """
                🎥 CINEMATIC SPECIFICATIONS:
                
                Shot Type:        \(tags.shotType)
                Lighting:         \(tags.lighting)
                Emotional Tone:   \(tags.emotionalTone)
                """
                
                if let movement = tags.cameraMovement {
                    prompts += "\nCamera Movement:  \(movement)"
                }
                if let palette = tags.colorPalette {
                    prompts += "\nColor Palette:    \(palette)"
                }
                if let atmosphere = tags.atmosphere {
                    prompts += "\nAtmosphere:       \(atmosphere)"
                }
                
                prompts += "\n"
            }
            
            if segment.generationStatus == .complete, let videoURL = segment.videoURL {
                prompts += "\n✅ VIDEO GENERATED: \(videoURL.lastPathComponent)\n"
            } else {
                prompts += "\n⏳ STATUS: \(segment.generationStatus.rawValue.capitalized)\n"
            }
        }
        
        prompts += """
        
        ═══════════════════════════════════════════════════════════
        End of Prompt List
        ═══════════════════════════════════════════════════════════
        """
        
        return prompts
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Prompt Segment
struct PromptSegment: Identifiable, Codable, Equatable {
    let id: UUID
    let index: Int
    var content: String
    var duration: Int
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
    
    static func == (lhs: PromptSegment, rhs: PromptSegment) -> Bool {
        lhs.id == rhs.id
    }
    
    enum GenerationStatus: String, Codable {
        case pending = "pending"
        case generating = "generating"
        case complete = "complete"
        case failed = "failed"
    }
}

// MARK: - Cinematic Tags
struct CinematicTags: Codable, Equatable {
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
struct StoryAnalysis: Codable, Equatable {
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

// MARK: - Scene Model (for enhanced features)
struct SceneModel: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let duration: Int
    let thumbnailURL: URL?
    let videoURL: URL?
    let status: SceneStatus
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        duration: Int,
        thumbnailURL: URL? = nil,
        videoURL: URL? = nil,
        status: SceneStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.status = status
    }
    
    enum SceneStatus: String, Codable {
        case pending
        case generating
        case complete
        case failed
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
    case analysisFailed
    case rewordingFailed
    case packagingFailed
    case invalidConfiguration
    case networkError(String)
    
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
        case .analysisFailed:
            return "Failed to analyze story"
        case .rewordingFailed:
            return "Failed to reword prompts"
        case .packagingFailed:
            return "Failed to package prompts"
        case .invalidConfiguration:
            return "Invalid pipeline configuration"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Tag Component (UI Helper)
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
