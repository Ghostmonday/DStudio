//
//  PipelineTests.swift
//  DirectorStudioTests
//
//  Comprehensive unit tests for pipeline system
//

import XCTest
@testable import DirectorStudio

// MARK: - Pipeline Configuration Tests

final class PipelineConfigTests: XCTestCase {
    
    func testDefaultConfiguration() {
        let config = PipelineConfig.default
        
        XCTAssertTrue(config.isRewordingEnabled)
        XCTAssertTrue(config.isStoryAnalysisEnabled)
        XCTAssertTrue(config.isSegmentationEnabled)
        XCTAssertTrue(config.isCinematicTaxonomyEnabled)
        XCTAssertTrue(config.isContinuityEnabled)
        XCTAssertTrue(config.isPackagingEnabled)
        XCTAssertEqual(config.enabledStepsCount, 6)
    }
    
    func testQuickProcessPreset() {
        let config = PipelineConfig.quickProcess
        
        XCTAssertFalse(config.isStoryAnalysisEnabled)
        XCTAssertFalse(config.isCinematicTaxonomyEnabled)
        XCTAssertFalse(config.isContinuityEnabled)
        XCTAssertEqual(config.maxRetries, 1)
        XCTAssertEqual(config.timeoutPerStep, 30.0)
    }
    
    func testConfigValidation() {
        var config = PipelineConfig.default
        config.isPackagingEnabled = false
        
        let warnings = config.validate()
        
        XCTAssertFalse(warnings.isEmpty)
        XCTAssertTrue(warnings.contains { $0.contains("Packaging") })
    }
    
    func testSegmentationOnlyPreset() {
        let config = PipelineConfig.segmentationOnly
        
        XCTAssertTrue(config.isSegmentationEnabled)
        XCTAssertTrue(config.isPackagingEnabled)
        XCTAssertFalse(config.isRewordingEnabled)
        XCTAssertFalse(config.isStoryAnalysisEnabled)
    }
}

// MARK: - Rewording Module Tests

final class RewordingModuleTests: XCTestCase {
    var module: RewordingModule!
    var context: PipelineContext!
    
    override func setUp() {
        super.setUp()
        module = RewordingModule()
        context = PipelineContext(config: .default)
    }
    
    func testBasicRewording() async {
        let input = RewordingInput(
            story: "Once upon a time, there was a kingdom.",
            rewordType: .modernize
        )
        
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            XCTAssertFalse(output.rewordedStory.isEmpty)
            XCTAssertEqual(output.originalLength, input.story.count)
        case .failure(let error):
            XCTFail("Rewording failed: \(error.localizedDescription)")
        }
    }
    
    func testNoRewordingType() async {
        let story = "Test story content"
        let input = RewordingInput(story: story, rewordType: .none)
        
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            XCTAssertEqual(output.rewordedStory, story)
        case .failure:
            XCTFail("Should not fail with .none type")
        }
    }
    
    func testEmptyStoryValidation() {
        let input = RewordingInput(story: "", rewordType: .modernize)
        let warnings = module.validate(input: input)
        
        XCTAssertFalse(warnings.isEmpty)
        XCTAssertTrue(warnings.contains { $0.contains("empty") })
    }
    
    func testVeryLongStory() {
        let longStory = String(repeating: "a", count: 60000)
        let input = RewordingInput(story: longStory, rewordType: .simplify)
        let warnings = module.validate(input: input)
        
        XCTAssertTrue(warnings.contains { $0.contains("long") })
    }
    
    func testChaoticInputDetection() async {
        let chaoticStory = """
        Dear diary, I had a dream I went to school with no pants, 
        but I knew it was a dream even if I was sitting in mom's car 
        while she's yelling THIS IS NOT A DREAM, haha who is she kidding…
        """
        
        let input = RewordingInput(story: chaoticStory, rewordType: .modernize)
        let result = await module.execute(input: input, context: context)
        
        // Should succeed even with chaotic input
        switch result {
        case .success(let output):
            XCTAssertFalse(output.rewordedStory.isEmpty)
        case .failure(let error):
            XCTFail("Should handle chaotic input gracefully: \(error.localizedDescription)")
        }
    }
}

// MARK: - Story Analysis Module Tests

final class StoryAnalysisModuleTests: XCTestCase {
    var module: StoryAnalysisModule!
    var context: PipelineContext!
    
    override func setUp() {
        super.setUp()
        module = StoryAnalysisModule()
        context = PipelineContext(config: .default)
    }
    
    func testBasicAnalysis() async {
        let story = """
        John walked into the coffee shop. The barista, Sarah, greeted him warmly.
        "Good morning!" she said. "The usual?"
        John nodded and sat down by the window.
        """
        
        let input = StoryAnalysisInput(story: story)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            XCTAssertFalse(output.analysis.characters.isEmpty)
            XCTAssertFalse(output.analysis.locations.isEmpty)
        case .failure(let error):
            XCTFail("Analysis failed: \(error.localizedDescription)")
        }
    }
    
    func testChaoticInputAnalysis() async {
        let chaoticStory = """
        wait what is happening i think i saw a dragon but maybe it was a cloud?
        mom says i daydream too much lol but seriously there was fire and everything
        """
        
        let input = StoryAnalysisInput(story: chaoticStory)
        let result = await module.execute(input: input, context: context)
        
        // Should succeed with fallback even for chaotic input
        switch result {
        case .success(let output):
            XCTAssertFalse(output.analysis.characters.isEmpty)
            XCTAssertGreaterThan(output.confidence, 0.0)
        case .failure(let error):
            XCTFail("Should handle chaotic input: \(error.localizedDescription)")
        }
    }
    
    func testEmptyStoryHandling() async {
        let input = StoryAnalysisInput(story: "")
        let result = await module.execute(input: input, context: context)
        
        // Should provide fallback analysis
        switch result {
        case .success(let output):
            XCTAssertNotNil(output.analysis)
        case .failure:
            XCTFail("Should not fail on empty input")
        }
    }
    
    func testValidation() {
        let input = StoryAnalysisInput(story: "Short")
        let warnings = module.validate(input: input)
        
        XCTAssertTrue(warnings.contains { $0.contains("short") })
    }
}

// MARK: - Segmentation Module Tests

final class SegmentationModuleTests: XCTestCase {
    var module: SegmentationModule!
    var context: PipelineContext!
    
    override func setUp() {
        super.setUp()
        module = SegmentationModule()
        context = PipelineContext(config: .default)
    }
    
    func testBasicSegmentation() async {
        let story = """
        The sun rose over the mountains. Birds began their morning songs.
        
        In the valley below, the village slowly came to life. Smoke rose from chimneys.
        
        A young girl stepped outside, breathing in the fresh mountain air.
        """
        
        let input = SegmentationInput(story: story, maxDuration: 15.0)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            XCTAssertGreaterThan(output.segments.count, 0)
            XCTAssertEqual(output.totalSegments, output.segments.count)
            
            // Verify segments are ordered
            for (index, segment) in output.segments.enumerated() {
                XCTAssertEqual(segment.order, index + 1)
            }
        case .failure(let error):
            XCTFail("Segmentation failed: \(error.localizedDescription)")
        }
    }
    
    func testShortStory() async {
        let story = "Hello world."
        let input = SegmentationInput(story: story, maxDuration: 15.0)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            XCTAssertEqual(output.segments.count, 1)
        case .failure:
            XCTFail("Should handle short stories")
        }
    }
    
    func testFragmentedInput() async {
        let story = """
        Wait. What? I think. Maybe. No. Yes. Definitely. Or not. Haha. Seriously though.
        This is. Confusing. Very. Much so. Indeed.
        """
        
        let input = SegmentationInput(story: story, maxDuration: 15.0)
        let result = await module.execute(input: input, context: context)
        
        switch result {
        case .success(let output):
            XCTAssertGreaterThan(output.segments.count, 0)
        case .failure(let error):
            XCTFail("Should handle fragmented input: \(error.localizedDescription)")
        }
    }
    
    func testMaxDurationValidation() {
        let input = SegmentationInput(story: "Test", maxDuration: -1)
        let warnings = module.validate(input: input)
        
        XCTAssertTrue(warnings.contains { $0.contains("positive") })
    }
}

// MARK: - Pipeline Manager Tests

@MainActor
final class PipelineManagerTests: XCTestCase {
    var manager: PipelineManager!
    
    override func setUp() {
        super.setUp()
        manager = PipelineManager(config: .default)
    }
    
    func testInitialization() {
        XCTAssertFalse(manager.isRunning)
        XCTAssertEqual(manager.currentStep, 0)
        XCTAssertEqual(manager.steps.count, 6)
    }
    
    func testFullPipelineExecution() async {
        let input = PipelineInput(
            story: "Test story for pipeline execution",
            rewordType: .none,
            projectTitle: "Test Project"
        )
        
        do {
            let output = try await manager.execute(input: input)
            
            XCTAssertFalse(output.segments.isEmpty)
            XCTAssertEqual(output.projectTitle, "Test Project")
        } catch {
            XCTFail("Pipeline execution failed: \(error.localizedDescription)")
        }
    }
    
    func testPartialPipelineExecution() async {
        var config = PipelineConfig.default
        config.isRewordingEnabled = false
        config.isStoryAnalysisEnabled = false
        config.isCinematicTaxonomyEnabled = false
        config.isContinuityEnabled = false
        
        manager.updateConfig(config)
        
        let input = PipelineInput(
            story: "Simple story",
            rewordType: nil,
            projectTitle: "Partial Test"
        )
        
        do {
            let output = try await manager.execute(input: input)
            XCTAssertNotNil(output)
        } catch {
            XCTFail("Partial pipeline failed: \(error.localizedDescription)")
        }
    }
    
    func testConfigurationUpdate() {
        let newConfig = PipelineConfig.quickProcess
        manager.updateConfig(newConfig)
        
        XCTAssertFalse(manager.config.isStoryAnalysisEnabled)
    }
}

// MARK: - Error Handling Tests

final class ErrorHandlingTests: XCTestCase {
    
    func testPipelineErrorDescriptions() {
        let errors: [PipelineError] = [
            .moduleNotEnabled("TestModule"),
            .validationFailed(module: "Test", warnings: ["Warning 1", "Warning 2"]),
            .timeout(module: "Test", duration: 30.0),
            .chaoticInputDetected(module: "Test", reason: "Fragmented"),
            .jsonParsingFailed(module: "Test", raw: "{invalid}"),
            .retryLimitExceeded(module: "Test", attempts: 3)
        ]
        
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testRecoverableErrors() {
        let recoverableErrors: [PipelineError] = [
            .moduleNotEnabled("Test"),
            .chaoticInputDetected(module: "Test", reason: "Test"),
            .apiError(module: "Test", statusCode: 500, message: "Server error")
        ]
        
        for error in recoverableErrors {
            XCTAssertTrue(error.isRecoverable)
        }
    }
    
    func testNonRecoverableErrors() {
        let nonRecoverableErrors: [PipelineError] = [
            .timeout(module: "Test", duration: 30.0),
            .retryLimitExceeded(module: "Test", attempts: 3)
        ]
        
        for error in nonRecoverableErrors {
            XCTAssertFalse(error.isRecoverable)
        }
    }
}

// MARK: - Integration Tests

@MainActor
final class IntegrationTests: XCTestCase {
    
    func testFullPipelineWithChaoticInput() async {
        let manager = PipelineManager(config: .default)
        
        let chaoticStory = """
        Dear diary, OMG today was so weird. I dreamed I was at school but like
        everyone was wearing costumes?? And mom was there being all "this is real life"
        but I KNEW it was a dream because the walls were melting haha.
        
        Then I woke up and it was actually Monday. Ugh. School again.
        But at least no melting walls this time lol.
        """
        
        let input = PipelineInput(
            story: chaoticStory,
            rewordType: .modernize,
            projectTitle: "Chaotic Dream Story"
        )
        
        do {
            let output = try await manager.execute(input: input)
            
            XCTAssertFalse(output.segments.isEmpty)
            XCTAssertNotNil(output.analysis)
            
            print("✅ Chaotic input processed successfully")
            print("  - Segments: \(output.segments.count)")
            print("  - Characters: \(output.analysis?.characters.count ?? 0)")
            
        } catch {
            XCTFail("Failed to process chaotic input: \(error.localizedDescription)")
        }
    }
    
    func testStreamOfConsciousnessInput() async {
        let manager = PipelineManager(config: .quickProcess)
        
        let streamStory = """
        thinking about pizza maybe or chinese no wait thai food sounds good
        but i should probably eat healthier mom would be proud if i ate a salad
        haha who am i kidding pizza it is definitely pizza with extra cheese
        """
        
        let input = PipelineInput(
            story: streamStory,
            rewordType: .none,
            projectTitle: "Stream of Consciousness"
        )
        
        do {
            let output = try await manager.execute(input: input)
            XCTAssertGreaterThan(output.segments.count, 0)
            
            print("✅ Stream-of-consciousness processed")
            
        } catch {
            XCTFail("Failed to process stream of consciousness: \(error.localizedDescription)")
        }
    }
}
