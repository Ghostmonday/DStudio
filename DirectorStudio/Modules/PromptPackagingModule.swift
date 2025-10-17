import Foundation
import SwiftUI

// MARK: - Packaged Prompt Models
struct PackagedPrompt: Codable {
    let title: String
    let timestamp: Date
    let segments: [SegmentPackage]
    let metadata: Metadata
    
    struct SegmentPackage: Codable {
        let index: Int
        let prompt: String
        let cinematicTags: CinematicTaxonomy?
        let continuityRefs: [String]
        let duration: Int
    }
    
    struct Metadata: Codable {
        let totalSegments: Int
        let totalDuration: Int
        let characters: [String]
        let locations: [String]
        let exportFormat: String
    }
}

// MARK: - MODULE 6: Prompt Packaging Module
class PromptPackagingModule: ObservableObject {
    // BugScan: export glue noop touch for analysis
    @Published var isProcessing = false
    @Published var packagedPrompt: PackagedPrompt?
    @Published var errorMessage: String?
    @Published var savedToScreenplay = false
    
    func packagePrompts(
        title: String,
        segments: [PromptSegment],
        taxonomies: [CinematicTaxonomy],
        anchors: [ContinuityAnchor]
    ) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            savedToScreenplay = false
        }
        
        // Package all data together
        let segmentPackages = segments.enumerated().map { index, segment in
            PackagedPrompt.SegmentPackage(
                index: segment.index,
                prompt: segment.content,
                cinematicTags: index < taxonomies.count ? taxonomies[index] : nil,
                continuityRefs: anchors.filter { anchor in
                    anchor.sceneReferences.contains(segment.index)
                }.map { $0.characterName },
                duration: segment.duration
            )
        }
        
        let allCharacters = Array(Set(segments.flatMap { $0.characters }))
        let allSettings = Array(Set(segments.map { $0.setting }))
        let totalDuration = segments.reduce(0) { $0 + $1.duration }
        
        let metadata = PackagedPrompt.Metadata(
            totalSegments: segments.count,
            totalDuration: totalDuration,
            characters: allCharacters,
            locations: allSettings,
            exportFormat: "screenplay"
        )
        
        let package = PackagedPrompt(
            title: title,
            timestamp: Date(),
            segments: segmentPackages,
            metadata: metadata
        )
        
        await MainActor.run {
            packagedPrompt = package
            isProcessing = false
        }
        
        // Save to screenplay format
        await saveToScreenplay(package)
    }
    
    private func saveToScreenplay(_ package: PackagedPrompt) async {
        // Generate screenplay format
        var screenplay = """
        \(package.title.uppercased())
        
        Generated: \(package.timestamp.formatted())
        
        CAST:
        \(package.metadata.characters.map { "- \($0)" }.joined(separator: "\n"))
        
        LOCATIONS:
        \(package.metadata.locations.map { "- \($0)" }.joined(separator: "\n"))
        
        TOTAL DURATION: \(package.metadata.totalDuration) seconds
        SEGMENTS: \(package.metadata.totalSegments)
        
        ---
        
        
        """
        
        for segment in package.segments {
            screenplay += """
            
            SEGMENT \(segment.index) [\(segment.duration)s]
            
            \(segment.prompt)
            
            """
            
            if let tags = segment.cinematicTags {
                screenplay += """
                
                CINEMATIC NOTES:
                Shot: \(tags.shotType) | Angle: \(tags.cameraAngle)
                Lighting: \(tags.lighting) | Movement: \(tags.cameraMovement)
                Tone: \(tags.emotionalTone)
                
                """
            }
            
            if !segment.continuityRefs.isEmpty {
                screenplay += """
                CONTINUITY: \(segment.continuityRefs.joined(separator: ", "))
                
                """
            }
            
            screenplay += "---\n\n"
        }
        
        // Save to file (in production, use proper file management)
        do {
            let filename = "\(package.title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).txt"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            try screenplay.write(to: fileURL, atomically: true, encoding: .utf8)
            
            await MainActor.run {
                savedToScreenplay = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save screenplay: \(error.localizedDescription)"
            }
        }
    }
}
