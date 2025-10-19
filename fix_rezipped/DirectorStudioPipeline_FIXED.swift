//
//  DirectorStudioPipeline.swift
//  DirectorStudio
//
//  Complete processing pipeline integrating all modules
//

import Foundation
import SwiftUI

// MARK: - Director Studio Processing Pipeline

@MainActor
class DirectorStudioPipeline: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let storyAnalyzer: StoryAnalyzerModule
    private let segmentation: PromptSegmentationModule
    private let rewording: RewordingModule
    private let packaging: PromptPackagingModule
    
    // MARK: - Initialization
    
    init() {
        self.storyAnalyzer = StoryAnalyzerModule()
        self.segmentation = PromptSegmentationModule()
        self.rewording = RewordingModule()
        self.packaging = PromptPackagingModule()
    }
    
    // MARK: - Main Processing Method
    
    func processStory(story: String, projectId: String) async throws -> [PromptSegment] {
        guard !story.isEmpty else {
            throw ProcessingError.emptyInput
        }
        
        isProcessing = true
        progress = 0.0
        errorMessage = nil
        
        do {
            // Step 1: Analyze Story (20%)
            currentStep = "Analyzing story structure..."
            progress = 0.05
            
            let analysis = try await storyAnalyzer.analyze(story: story)
            progress = 0.2
            
            print("""
            📊 Story Analysis Complete:
               Characters: \(analysis.characterCount)
               Estimated Scenes: \(analysis.sceneCount)
               Complexity: \(analysis.complexity.rawValue)
               Themes: \(analysis.themes.joined(separator: ", "))
            """)
            
            // Step 2: Segment into Scenes (40%)
            currentStep = "Segmenting into \(analysis.sceneCount) scenes..."
            progress = 0.25
            
            var segments = try await segmentation.segment(
                story: story,
                analysis: analysis
            )
            progress = 0.4
            
            print("🎬 Created \(segments.count) scene segments")
            
            // Step 3: Reword for Cinematic Impact (70%)
            currentStep = "Enhancing prompts for cinematic impact..."
            progress = 0.45
            
            segments = try await rewording.reword(segments: segments)
            progress = 0.7
            
            print("✨ Prompts enhanced for video generation")
            
            // Step 4: Package with Cinematic Tags (90%)
            currentStep = "Adding cinematic specifications..."
            progress = 0.75
            
            segments = try await packaging.package(segments: segments)
            progress = 0.9
            
            print("🎥 Cinematic tags added to all scenes")
            
            // Step 5: Track Costs (95%)
            currentStep = "Finalizing..."
            progress = 0.95
            
            trackProcessingCost(
                projectId: projectId,
                story: story,
                segments: segments
            )
            
            // Complete
            progress = 1.0
            currentStep = "Processing complete!"
            isProcessing = false
            
            print("""
            ✅ Pipeline Complete:
               Total Scenes: \(segments.count)
               Total Duration: \(segments.reduce(0) { $0 + $1.duration })s
               Ready for video generation
            """)
            
            return segments
            
        } catch {
            isProcessing = false
            progress = 0.0
            currentStep = "Processing failed"
            errorMessage = error.localizedDescription
            
            print("❌ Pipeline Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Individual Module Access
    
    func analyzeStory(_ story: String) async throws -> StoryAnalysis {
        currentStep = "Analyzing story..."
        return try await storyAnalyzer.analyze(story: story)
    }
    
    func segmentStory(_ story: String, analysis: StoryAnalysis) async throws -> [PromptSegment] {
        currentStep = "Segmenting story..."
        return try await segmentation.segment(story: story, analysis: analysis)
    }
    
    func rewordSegments(_ segments: [PromptSegment]) async throws -> [PromptSegment] {
        currentStep = "Rewording segments..."
        return try await rewording.reword(segments: segments)
    }
    
    func packageSegments(_ segments: [PromptSegment]) async throws -> [PromptSegment] {
        currentStep = "Packaging segments..."
        return try await packaging.package(segments: segments)
    }
    
    // MARK: - Cancel Processing
    
    func cancelProcessing() {
        isProcessing = false
        currentStep = "Processing cancelled"
        progress = 0.0
        print("⏹️ Processing cancelled by user")
    }
    
    // MARK: - Cost Tracking
    
    private func trackProcessingCost(
        projectId: String,
        story: String,
        segments: [PromptSegment]
    ) {
        // Calculate total tokens used (estimated)
        let inputTokens = story.count / 4 // Rough estimate: 1 token ≈ 4 chars
        let outputTokens = segments.reduce(0) { $0 + ($1.content.count / 4) }
        
        // Track the cost
        CostMetricsManager.shared.trackStoryProcessing(
            sceneId: projectId,
            characters: story.count,
            tier: determineTier(characterCount: story.count),
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
    }
    
    private func determineTier(characterCount: Int) -> String {
        if characterCount <= 500 {
            return "short"
        } else if characterCount <= 2000 {
            return "medium"
        } else {
            return "long"
        }
    }
}

// MARK: - Pipeline Configuration

struct PipelineConfig {
    var targetSceneCount: Int?
    var targetDuration: Int
    var styleGuide: StyleGuide
    var optimization: OptimizationLevel
    
    init(
        targetSceneCount: Int? = nil,
        targetDuration: Int = 20,
        styleGuide: StyleGuide = .cinematic,
        optimization: OptimizationLevel = .balanced
    ) {
        self.targetSceneCount = targetSceneCount
        self.targetDuration = targetDuration
        self.styleGuide = styleGuide
        self.optimization = optimization
    }
    
    enum StyleGuide: String, Codable {
        case cinematic = "Cinematic"
        case documentary = "Documentary"
        case artistic = "Artistic"
        case commercial = "Commercial"
    }
    
    enum OptimizationLevel: String, Codable {
        case fast = "Fast"
        case balanced = "Balanced"
        case quality = "Quality"
    }
}
