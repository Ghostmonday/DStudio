import Foundation

// MARK: - Enhanced Models with Export
struct Project: Identifiable, Codable {
    // BugScan: session persistence noop touch for analysis
    let id: UUID
    var title: String
    var originalStory: String
    var rewordedStory: String?
    var analysis: StoryAnalysisCache?
    var segments: [PromptSegment]
    var continuityAnchors: [ContinuityAnchorCache]
    var createdAt: Date
    var updatedAt: Date
    
    static var demoProject: Project {
        Project(
            id: UUID(),
            title: "City Awakens - Demo",
            originalStory: "The sun rises over a bustling metropolis. Sarah, a young filmmaker, stands on a rooftop with her camera. She captures the golden light dancing across skyscraper windows as the city comes alive below her. In this moment of stillness before the chaos, she realizes this footage will become the opening of her breakthrough documentary.",
            segments: [],
            continuityAnchors: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // Export as screenplay format
    func exportAsScreenplay() -> String {
        var screenplay = """
        \(title.uppercased())
        
        Written with DirectorStudio
        Created: \(createdAt.formatted(date: .abbreviated, time: .omitted))
        Updated: \(updatedAt.formatted(date: .abbreviated, time: .omitted))
        
        ═══════════════════════════════════════════════════
        
        """
        
        if let analysis = analysis {
            screenplay += """
            
            STORY ANALYSIS
            Characters: \(analysis.characterCount)
            Locations: \(analysis.locationCount)
            Scenes: \(analysis.sceneCount)
            
            ═══════════════════════════════════════════════════
            
            """
        }
        
        if !continuityAnchors.isEmpty {
            screenplay += "\nCHARACTER CONTINUITY\n\n"
            for anchor in continuityAnchors {
                screenplay += """
                \(anchor.characterName.uppercased())
                \(anchor.visualDescription)
                
                """
            }
            screenplay += "═══════════════════════════════════════════════════\n\n"
        }
        
        screenplay += "ORIGINAL STORY\n\n\(originalStory)\n\n"
        
        if let reworded = rewordedStory {
            screenplay += """
            ═══════════════════════════════════════════════════
            
            TRANSFORMED VERSION
            
            \(reworded)
            
            """
        }
        
        if !segments.isEmpty {
            screenplay += """
            ═══════════════════════════════════════════════════
            
            SCENE BREAKDOWN
            Total Segments: \(segments.count)
            Total Duration: \(segments.reduce(0) { $0 + $1.duration })s
            
            """
            
            for segment in segments {
                screenplay += """
                
                ───────────────────────────────────────────────────
                SCENE \(segment.index) [\(segment.duration)s]
                ───────────────────────────────────────────────────
                
                \(segment.content)
                
                """
                
                if let tags = segment.cinematicTags {
                    screenplay += """
                    
                    CINEMATIC DIRECTION:
                    • Shot Type: \(tags.shotType)
                    • Camera Angle: \(tags.cameraAngle)
                    • Lighting: \(tags.lighting)
                    • Mood: \(tags.emotionalTone)
                    
                    """
                }
            }
        }
        
        screenplay += """
        
        ═══════════════════════════════════════════════════
        END OF SCREENPLAY
        ═══════════════════════════════════════════════════
        """
        
        return screenplay
    }
    
    // Export as JSON
    func exportAsJSON() -> String {
        if let data = try? JSONEncoder().encode(self),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    // Export segments as simple prompt list
    func exportAsPromptList() -> String {
        var output = "\(title)\n\n"
        output += "AI Video Prompts\n"
        output += "Generated: \(Date().formatted())\n\n"
        
        for segment in segments {
            output += "Prompt \(segment.index):\n"
            output += "\(segment.content)\n"
            if let tags = segment.cinematicTags {
                output += "[\(tags.shotType) | \(tags.lighting) | \(tags.emotionalTone)]\n"
            }
            output += "\n"
        }
        
        return output
    }
}

struct StoryAnalysisCache: Codable {
    let characterCount: Int
    let locationCount: Int
    let sceneCount: Int
}

struct ContinuityAnchorCache: Identifiable, Codable {
    let id: UUID
    let characterName: String
    let visualDescription: String
}
