import Foundation
import SwiftUI
import os.log

// MARK: - MODULE 3: Prompt Segmentation Module
class PromptSegmentationModule: ObservableObject {
    @Published var isProcessing = false
    @Published var segments: [PromptSegment] = []
    @Published var errorMessage: String?
    @Published var debugMessage: String?
    
    private let service: AIServiceProtocol
    private let logger = Logger(subsystem: "net.neuraldraft.DirectorStudio", category: "Segmentation")
    
    // Configuration
    private let minimumCharacterCount = 300
    
    init(service: AIServiceProtocol = DeepSeekService()) {
        self.service = service
    }
    
    func segment(story: String, targetDuration: Int = 15) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            debugMessage = nil
            segments = []
        }
        
        // Check if input is too short for segmentation
        let trimmedStory = story.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedStory.count < minimumCharacterCount {
            logger.info("📏 Short input detected (\(trimmedStory.count) chars) - skipping segmentation")
            
            // Create a single segment from the short input
            let singleSegment = createSingleSegment(from: trimmedStory, targetDuration: targetDuration)
            
            await MainActor.run {
                segments = [singleSegment]
                debugMessage = "Short input detected (\(trimmedStory.count) chars)—segmenting skipped. Using as-is."
                isProcessing = false
            }
            
            logger.info("✅ Created single segment for short input")
            return
        }
        
        // Proceed with normal segmentation for longer inputs
        logger.info("📝 Processing input of \(trimmedStory.count) characters - proceeding with segmentation")
        
        let systemPrompt = """
        You are an expert at breaking stories into short video prompt segments. Each segment should be \(targetDuration) seconds of content.
        
        Break the story into logical beats/scenes. For each segment provide:
        - Index number
        - Duration (target \(targetDuration)s)
        - Content (the actual prompt text for video generation)
        - Characters present
        - Setting description
        - Main action
        - Continuity notes (to maintain consistency across segments)
        
        Return ONLY valid JSON array:
        [
            {
                "index": 1,
                "duration": \(targetDuration),
                "content": "...",
                "characters": ["..."],
                "setting": "...",
                "action": "...",
                "continuity_notes": "..."
            }
        ]
        """
        
        let userPrompt = "Break this story into video prompt segments:\n\n\(trimmedStory)"
        
        do {
            let response = try await service.sendRequest(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                temperature: 0.4,
                maxTokens: 4000
            )
            
            let jsonData = extractJSON(from: response)
            let decoder = JSONDecoder()
            let promptSegments = try decoder.decode([PromptSegment].self, from: jsonData)
            
            await MainActor.run {
                segments = promptSegments
                debugMessage = nil
                isProcessing = false
            }
            
            logger.info("✅ Successfully segmented into \(promptSegments.count) segments")
        } catch {
            logger.error("❌ Segmentation failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
    
    private func extractJSON(from response: String) -> Data {
        if let jsonStart = response.firstIndex(of: "["),
           let jsonEnd = response.lastIndex(of: "]") {
            let jsonString = String(response[jsonStart...jsonEnd])
            return jsonString.data(using: .utf8) ?? Data()
        }
        return response.data(using: .utf8) ?? Data()
    }
    
    /// Creates a single PromptSegment from short input text
    private func createSingleSegment(from text: String, targetDuration: Int) -> PromptSegment {
        // Extract basic information from the text
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Simple character extraction (look for capitalized words that might be names)
        let potentialCharacters = words.filter { word in
            word.count > 2 && 
            word.first?.isUppercase == true && 
            !word.contains(where: { $0.isPunctuation })
        }.prefix(3) // Limit to 3 characters max
        
        // Create a basic setting from the text
        let setting = extractSetting(from: text)
        
        // Extract action from the text
        let action = extractAction(from: text)
        
        return PromptSegment(
            index: 1,
            duration: targetDuration,
            content: text,
            characters: Array(potentialCharacters),
            setting: setting,
            action: action,
            continuityNotes: "Single segment - no continuity constraints",
            location: setting,
            props: [],
            tone: "neutral"
        )
    }
    
    /// Extracts a basic setting from the text
    private func extractSetting(from text: String) -> String {
        let lowercaseText = text.lowercased()
        
        // Look for common setting indicators
        if lowercaseText.contains("kitchen") { return "Kitchen" }
        if lowercaseText.contains("bedroom") { return "Bedroom" }
        if lowercaseText.contains("living room") || lowercaseText.contains("lounge") { return "Living Room" }
        if lowercaseText.contains("office") { return "Office" }
        if lowercaseText.contains("car") || lowercaseText.contains("vehicle") { return "Vehicle" }
        if lowercaseText.contains("street") || lowercaseText.contains("outside") { return "Street" }
        if lowercaseText.contains("park") { return "Park" }
        if lowercaseText.contains("beach") { return "Beach" }
        if lowercaseText.contains("forest") || lowercaseText.contains("woods") { return "Forest" }
        if lowercaseText.contains("mountain") { return "Mountain" }
        
        // Default to a generic setting
        return "Interior Scene"
    }
    
    /// Extracts a basic action from the text
    private func extractAction(from text: String) -> String {
        let lowercaseText = text.lowercased()
        
        // Look for common action words
        if lowercaseText.contains("walk") || lowercaseText.contains("walking") { return "Walking" }
        if lowercaseText.contains("run") || lowercaseText.contains("running") { return "Running" }
        if lowercaseText.contains("sit") || lowercaseText.contains("sitting") { return "Sitting" }
        if lowercaseText.contains("stand") || lowercaseText.contains("standing") { return "Standing" }
        if lowercaseText.contains("talk") || lowercaseText.contains("talking") { return "Talking" }
        if lowercaseText.contains("eat") || lowercaseText.contains("eating") { return "Eating" }
        if lowercaseText.contains("drink") || lowercaseText.contains("drinking") { return "Drinking" }
        if lowercaseText.contains("read") || lowercaseText.contains("reading") { return "Reading" }
        if lowercaseText.contains("write") || lowercaseText.contains("writing") { return "Writing" }
        if lowercaseText.contains("work") || lowercaseText.contains("working") { return "Working" }
        
        // Default to a generic action
        return "General Activity"
    }
}
