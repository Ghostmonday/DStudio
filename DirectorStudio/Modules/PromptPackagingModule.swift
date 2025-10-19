import Foundation

// MARK: - Prompt Packaging Module

class PromptPackagingModule {
    
    // MARK: - Main Packaging Method
    
    func package(segments: [PromptSegment]) async throws -> [PromptSegment] {
        guard !segments.isEmpty else {
            throw ProcessingError.packagingFailed
        }
        
        // Add cinematic tags to each segment
        var packagedSegments: [PromptSegment] = []
        
        for segment in segments {
            var packaged = segment
            
            // Generate cinematic tags based on content
            packaged.cinematicTags = generateCinematicTags(for: segment.content)
            
            packagedSegments.append(packaged)
        }
        
        return packagedSegments
    }
    
    // MARK: - Cinematic Tag Generation
    
    private func generateCinematicTags(for content: String) -> CinematicTags {
        let lowercased = content.lowercased()
        
        // Determine shot type
        let shotType = determineShotType(from: lowercased)
        
        // Determine lighting
        let lighting = determineLighting(from: lowercased)
        
        // Determine emotional tone
        let emotionalTone = determineEmotionalTone(from: lowercased)
        
        // Determine camera movement
        let cameraMovement = determineCameraMovement(from: lowercased)
        
        // Determine color palette
        let colorPalette = determineColorPalette(from: lowercased)
        
        // Determine atmosphere
        let atmosphere = determineAtmosphere(from: lowercased)
        
        return CinematicTags(
            shotType: shotType,
            lighting: lighting,
            emotionalTone: emotionalTone,
            cameraMovement: cameraMovement,
            colorPalette: colorPalette,
            atmosphere: atmosphere
        )
    }
    
    // MARK: - Tag Determination Methods
    
    private func determineShotType(from text: String) -> String {
        let closeUpWords = ["face", "eyes", "detail", "close", "intimate"]
        let wideWords = ["landscape", "city", "panorama", "wide", "vast"]
        let mediumWords = ["standing", "sitting", "walking", "talking"]
        
        if closeUpWords.contains(where: { text.contains($0) }) {
            return "Close-up"
        } else if wideWords.contains(where: { text.contains($0) }) {
            return "Wide Shot"
        } else if mediumWords.contains(where: { text.contains($0) }) {
            return "Medium Shot"
        } else {
            return "Medium Shot" // Default
        }
    }
    
    private func determineLighting(from text: String) -> String {
        let brightWords = ["sun", "bright", "day", "morning", "light"]
        let darkWords = ["night", "dark", "shadow", "dim", "moonlight"]
        let dramaticWords = ["dramatic", "contrast", "spotlight", "silhouette"]
        
        if brightWords.contains(where: { text.contains($0) }) {
            return "Natural Light"
        } else if darkWords.contains(where: { text.contains($0) }) {
            return "Low Light"
        } else if dramaticWords.contains(where: { text.contains($0) }) {
            return "Dramatic"
        } else {
            return "Balanced" // Default
        }
    }
    
    private func determineEmotionalTone(from text: String) -> String {
        let happyWords = ["happy", "joy", "smile", "laugh", "celebrate"]
        let sadWords = ["sad", "cry", "tears", "sorrow", "grief"]
        let tenseWords = ["tense", "anxious", "worry", "fear", "nervous"]
        let calmWords = ["calm", "peaceful", "serene", "quiet", "still"]
        let excitedWords = ["excited", "thrilled", "energetic", "dynamic"]
        
        if happyWords.contains(where: { text.contains($0) }) {
            return "Joyful"
        } else if sadWords.contains(where: { text.contains($0) }) {
            return "Melancholic"
        } else if tenseWords.contains(where: { text.contains($0) }) {
            return "Tense"
        } else if calmWords.contains(where: { text.contains($0) }) {
            return "Serene"
        } else if excitedWords.contains(where: { text.contains($0) }) {
            return "Energetic"
        } else {
            return "Neutral" // Default
        }
    }
    
    private func determineCameraMovement(from text: String) -> String? {
        let panWords = ["across", "sweep", "scan"]
        let trackWords = ["follow", "chase", "pursue"]
        let zoomWords = ["zoom", "focus", "closer"]
        let staticWords = ["still", "steady", "fixed"]
        
        if panWords.contains(where: { text.contains($0) }) {
            return "Pan"
        } else if trackWords.contains(where: { text.contains($0) }) {
            return "Tracking"
        } else if zoomWords.contains(where: { text.contains($0) }) {
            return "Zoom"
        } else if staticWords.contains(where: { text.contains($0) }) {
            return "Static"
        } else {
            return "Subtle Movement"
        }
    }
    
    private func determineColorPalette(from text: String) -> String? {
        let warmWords = ["warm", "orange", "red", "sunset", "fire"]
        let coolWords = ["cool", "blue", "cold", "ice", "winter"]
        let vibrantWords = ["vibrant", "colorful", "bright", "vivid"]
        let mutedWords = ["muted", "gray", "pale", "faded"]
        
        if warmWords.contains(where: { text.contains($0) }) {
            return "Warm Tones"
        } else if coolWords.contains(where: { text.contains($0) }) {
            return "Cool Tones"
        } else if vibrantWords.contains(where: { text.contains($0) }) {
            return "Vibrant"
        } else if mutedWords.contains(where: { text.contains($0) }) {
            return "Muted"
        } else {
            return "Balanced"
        }
    }
    
    private func determineAtmosphere(from text: String) -> String? {
        let mysteriousWords = ["mystery", "unknown", "hidden", "secret"]
        let romanticWords = ["love", "romance", "passion", "intimate"]
        let actionWords = ["action", "fight", "chase", "battle"]
        let peacefulWords = ["peace", "calm", "tranquil", "gentle"]
        
        if mysteriousWords.contains(where: { text.contains($0) }) {
            return "Mysterious"
        } else if romanticWords.contains(where: { text.contains($0) }) {
            return "Romantic"
        } else if actionWords.contains(where: { text.contains($0) }) {
            return "Intense"
        } else if peacefulWords.contains(where: { text.contains($0) }) {
            return "Peaceful"
        } else {
            return "Atmospheric"
        }
    }
    
    // MARK: - Advanced Packaging
    
    func packageWithStyle(
        segments: [PromptSegment],
        style: PackagingStyle
    ) async throws -> [PromptSegment] {
        var styledSegments: [PromptSegment] = []
        
        for segment in segments {
            var styled = segment
            
            // Generate tags with style override
            var tags = generateCinematicTags(for: segment.content)
            
            // Apply style modifications
            switch style {
            case .cinematic:
                tags = applyCinematicStyle(to: tags)
            case .documentary:
                tags = applyDocumentaryStyle(to: tags)
            case .artistic:
                tags = applyArtisticStyle(to: tags)
            case .commercial:
                tags = applyCommercialStyle(to: tags)
            }
            
            styled.cinematicTags = tags
            styledSegments.append(styled)
        }
        
        return styledSegments
    }
    
    // MARK: - Style Application
    
    private func applyCinematicStyle(to tags: CinematicTags) -> CinematicTags {
        CinematicTags(
            shotType: tags.shotType,
            lighting: "Dramatic",
            emotionalTone: tags.emotionalTone,
            cameraMovement: "Smooth Tracking",
            colorPalette: "Film Grade",
            atmosphere: tags.atmosphere
        )
    }
    
    private func applyDocumentaryStyle(to tags: CinematicTags) -> CinematicTags {
        CinematicTags(
            shotType: "Medium Shot",
            lighting: "Natural Light",
            emotionalTone: "Authentic",
            cameraMovement: "Handheld",
            colorPalette: "Realistic",
            atmosphere: "Documentary"
        )
    }
    
    private func applyArtisticStyle(to tags: CinematicTags) -> CinematicTags {
        CinematicTags(
            shotType: tags.shotType,
            lighting: "Creative",
            emotionalTone: "Expressive",
            cameraMovement: "Experimental",
            colorPalette: "Stylized",
            atmosphere: "Artistic"
        )
    }
    
    private func applyCommercialStyle(to tags: CinematicTags) -> CinematicTags {
        CinematicTags(
            shotType: tags.shotType,
            lighting: "Bright",
            emotionalTone: "Energetic",
            cameraMovement: "Dynamic",
            colorPalette: "Vibrant",
            atmosphere: "Commercial"
        )
    }
}

// MARK: - Packaging Style

enum PackagingStyle {
    case cinematic
    case documentary
    case artistic
    case commercial
}
