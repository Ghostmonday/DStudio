import Foundation

// MARK: - Story Analyzer Module

class StoryAnalyzerModule {
    
    // MARK: - Main Analysis Method
    
    func analyze(story: String) async throws -> StoryAnalysis {
        guard !story.isEmpty else {
            throw ProcessingError.emptyInput
        }
        
        // Analyze character count
        let characterCount = story.count
        
        // Estimate scene count (rough heuristic: ~300 chars per scene)
        let estimatedSceneCount = max(1, characterCount / 300)
        
        // Determine complexity
        let complexity = determineComplexity(characterCount: characterCount)
        
        // Extract themes (simple keyword-based for now)
        let themes = extractThemes(from: story)
        
        // Calculate estimated duration (20 seconds per scene)
        let estimatedDuration = estimatedSceneCount * 20
        
        // Recommend tier based on character count
        let recommendedTier = recommendTier(characterCount: characterCount)
        
        return StoryAnalysis(
            characterCount: characterCount,
            sceneCount: estimatedSceneCount,
            estimatedDuration: estimatedDuration,
            complexity: complexity,
            themes: themes,
            recommendedTier: recommendedTier
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineComplexity(characterCount: Int) -> StoryAnalysis.StoryComplexity {
        if characterCount < 500 {
            return .simple
        } else if characterCount < 2000 {
            return .moderate
        } else {
            return .complex
        }
    }
    
    private func extractThemes(from story: String) -> [String] {
        let lowercased = story.lowercased()
        var themes: [String] = []
        
        // Simple keyword detection
        let themeKeywords: [String: [String]] = [
            "Love": ["love", "romance", "heart", "passion"],
            "Adventure": ["adventure", "journey", "quest", "explore"],
            "Mystery": ["mystery", "secret", "discover", "unknown"],
            "Action": ["fight", "battle", "chase", "escape"],
            "Drama": ["conflict", "struggle", "tension", "emotion"],
            "Horror": ["fear", "terror", "horror", "scary"],
            "Comedy": ["funny", "laugh", "humor", "comedy"],
            "Sci-Fi": ["space", "future", "technology", "alien"],
            "Fantasy": ["magic", "fantasy", "wizard", "dragon"]
        ]
        
        for (theme, keywords) in themeKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                themes.append(theme)
            }
        }
        
        // Default theme if none detected
        if themes.isEmpty {
            themes.append("General")
        }
        
        return themes
    }
    
    private func recommendTier(characterCount: Int) -> String {
        if characterCount <= 500 {
            return "short"
        } else if characterCount <= 2000 {
            return "medium"
        } else {
            return "long"
        }
    }
}
