import Foundation

// MARK: - Prompt Segmentation Module

class PromptSegmentationModule {
    
    // MARK: - Main Segmentation Method
    
    func segment(story: String, analysis: StoryAnalysis) async throws -> [PromptSegment] {
        guard !story.isEmpty else {
            throw ProcessingError.segmentationFailed
        }
        
        // Use the analysis to guide segmentation
        let targetSceneCount = analysis.sceneCount
        
        // Split story into logical segments
        let segments = splitIntoSegments(
            story: story,
            targetCount: targetSceneCount
        )
        
        // Convert to PromptSegments
        var promptSegments: [PromptSegment] = []
        
        for (index, segment) in segments.enumerated() {
            let promptSegment = PromptSegment(
                index: index + 1,
                content: segment,
                duration: 20, // Default 20 seconds per scene
                cinematicTags: nil, // Will be added by packaging module
                videoURL: nil,
                generationStatus: .pending
            )
            promptSegments.append(promptSegment)
        }
        
        return promptSegments
    }
    
    // MARK: - Helper Methods
    
    private func splitIntoSegments(story: String, targetCount: Int) -> [String] {
        // Split by natural breaks (paragraphs, sentences, etc.)
        let paragraphs = story.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        
        if paragraphs.count >= targetCount {
            // We have enough paragraphs
            return Array(paragraphs.prefix(targetCount))
        } else {
            // Need to split paragraphs further
            var segments: [String] = []
            
            for paragraph in paragraphs {
                let sentences = splitIntoSentences(paragraph)
                segments.append(contentsOf: sentences)
                
                if segments.count >= targetCount {
                    break
                }
            }
            
            return Array(segments.prefix(targetCount))
        }
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting (can be enhanced with NLP)
        let delimiters = CharacterSet(charactersIn: ".!?")
        var sentences: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            
            if delimiters.contains(char.unicodeScalars.first!) {
                let trimmed = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                currentSentence = ""
            }
        }
        
        // Add remaining text
        let trimmed = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sentences.append(trimmed)
        }
        
        return sentences
    }
    
    // MARK: - Advanced Segmentation
    
    func segmentWithContext(
        story: String,
        analysis: StoryAnalysis,
        config: SegmentationConfig
    ) async throws -> [PromptSegment] {
        // More sophisticated segmentation with configuration
        let baseSegments = try await segment(story: story, analysis: analysis)
        
        // Apply configuration
        var configuredSegments = baseSegments
        
        if let maxDuration = config.maxSceneDuration {
            configuredSegments = configuredSegments.map { segment in
                var modified = segment
                modified.duration = min(segment.duration, maxDuration)
                return modified
            }
        }
        
        if let minDuration = config.minSceneDuration {
            configuredSegments = configuredSegments.map { segment in
                var modified = segment
                modified.duration = max(segment.duration, minDuration)
                return modified
            }
        }
        
        return configuredSegments
    }
}

// MARK: - Segmentation Configuration

struct SegmentationConfig {
    var maxSceneDuration: Int?
    var minSceneDuration: Int?
    var preferNaturalBreaks: Bool
    var balanceSceneLengths: Bool
    
    init(
        maxSceneDuration: Int? = nil,
        minSceneDuration: Int? = nil,
        preferNaturalBreaks: Bool = true,
        balanceSceneLengths: Bool = true
    ) {
        self.maxSceneDuration = maxSceneDuration
        self.minSceneDuration = minSceneDuration
        self.preferNaturalBreaks = preferNaturalBreaks
        self.balanceSceneLengths = balanceSceneLengths
    }
}
