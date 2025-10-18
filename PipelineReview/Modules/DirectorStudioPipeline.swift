import Foundation
import SwiftUI
import os.log

// MARK: - Pipeline Coordinator (Runs all modules in sequence)
class DirectorStudioPipeline: ObservableObject {
    // BugScan: scene pipeline noop touch for analysis
    @Published var currentStep = 0
    @Published var isRunning = false
    @Published var completedSteps: Set<Int> = []
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "net.neuraldraft.DirectorStudio", category: "Pipeline")
    
    let rewordingModule: RewordingModule
    let storyAnalyzer: StoryAnalyzerModule
    let segmentationModule: PromptSegmentationModule
    let taxonomyModule: CinematicTaxonomyModule
    let continuityModule: ContinuityAnchorModule
    let packagingModule: PromptPackagingModule
    
    init() {
        let service = DeepSeekService()
        rewordingModule = RewordingModule(service: service)
        storyAnalyzer = StoryAnalyzerModule(service: service)
        segmentationModule = PromptSegmentationModule(service: service)
        taxonomyModule = CinematicTaxonomyModule(service: service)
        continuityModule = ContinuityAnchorModule(service: service)
        packagingModule = PromptPackagingModule()
    }
    
    func runFullPipeline(
        story: String,
        rewordType: RewordingType? = nil,
        projectTitle: String = "Untitled Project",
        enableTransform: Bool = true,
        enableCinematic: Bool = true,
        enableBreakdown: Bool = true
    ) async {
        await MainActor.run {
            isRunning = true
            currentStep = 0
            completedSteps.removeAll()
            errorMessage = nil
        }
        
        var processedStory = story
        
        // Step 1: Rewording (conditional)
        if enableTransform, let rewordType = rewordType {
            logger.info("🔄 Starting rewording step with type: \(rewordType.rawValue)")
            await updateStep(1, "Rewording story...")
            await rewordingModule.reword(text: story, type: rewordType)
            let result = await MainActor.run { rewordingModule.result }
            let errorMessage = await MainActor.run { rewordingModule.errorMessage }
            
            logger.info("📝 Rewording result length: \(result.count)")
            logger.info("❌ Rewording error: \(errorMessage ?? "none")")
            
            if !result.isEmpty {
                logger.info("✅ Rewording successful")
                processedStory = result
                await markStepComplete(1)
            } else {
                logger.error("❌ Rewording failed - empty result")
                await setError("Rewording failed: \(errorMessage ?? "Unknown error")")
                return
            }
        } else {
            logger.info("⏭️ Skipping rewording step (\(enableTransform ? "no type selected" : "module disabled"))")
            await markStepComplete(1)
        }
        
        // Step 2: Story Analysis
        await updateStep(2, "Analyzing story structure...")
        await storyAnalyzer.analyze(story: processedStory)
        if await MainActor.run(body: { storyAnalyzer.analysis }) != nil {
            await markStepComplete(2)
        } else {
            await setError("Story analysis failed")
            return
        }
        
        // Step 3: Prompt Segmentation (conditional)
        var segments: [PromptSegment] = []
        if enableBreakdown {
            await updateStep(3, "Segmenting into prompts...")
            await segmentationModule.segment(story: processedStory)
            segments = await MainActor.run { segmentationModule.segments }
            if !segments.isEmpty {
                await markStepComplete(3)
            } else {
                await setError("Segmentation failed")
                return
            }
        } else {
            logger.info("⏭️ Skipping segmentation step (module disabled)")
            await markStepComplete(3)
        }
        
        // Step 4: Cinematic Taxonomy (conditional)
        var taxonomies: [CinematicTaxonomy] = []
        if enableCinematic && !segments.isEmpty {
            await updateStep(4, "Analyzing cinematography...")
            for segment in segments {
                await taxonomyModule.analyzeCinematic(scene: segment.content)
                if let taxonomy = await MainActor.run(body: { taxonomyModule.taxonomy }) {
                    taxonomies.append(taxonomy)
                }
            }
            
            if taxonomies.count == segments.count {
                await markStepComplete(4)
            } else {
                await setError("Taxonomy analysis incomplete")
                return
            }
        } else {
            logger.info("⏭️ Skipping cinematic taxonomy step (\(enableCinematic ? "no segments" : "module disabled"))")
            await markStepComplete(4)
        }
        
        // Step 5: Continuity Anchors
        await updateStep(5, "Generating continuity anchors...")
        await continuityModule.generateAnchors(story: processedStory)
        let anchors = await MainActor.run { continuityModule.anchors }
        if !anchors.isEmpty {
            await markStepComplete(5)
        } else {
            await setError("Continuity generation failed")
            return
        }
        
        // Step 6: Package & Save
        await updateStep(6, "Packaging screenplay...")
        await packagingModule.packagePrompts(
            title: projectTitle,
            segments: segments,
            taxonomies: taxonomies,
            anchors: anchors
        )
        
        if await MainActor.run(body: { packagingModule.savedToScreenplay }) {
            await markStepComplete(6)
        } else {
            await setError("Packaging failed")
            return
        }
        
        await MainActor.run {
            isRunning = false
        }
    }
    
    private func updateStep(_ step: Int, _ message: String) async {
        await MainActor.run {
            currentStep = step
        }
    }
    
    private func markStepComplete(_ step: Int) async {
        await MainActor.run {
            completedSteps.insert(step)
        }
    }
    
    private func setError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            isRunning = false
        }
    }
}
