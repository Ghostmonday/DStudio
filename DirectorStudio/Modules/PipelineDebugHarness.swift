//
//  PipelineDebugHarness.swift
//  DirectorStudio
//
//  Debug and testing harness for pipeline development
//  Provides tools for testing chaotic inputs and monitoring execution
//

import Foundation
import OSLog

// MARK: - Debug Harness

@MainActor
public final class PipelineDebugHarness {
    private let logger = Logger(subsystem: "com.directorstudio.debug", category: "harness")
    private var manager: PipelineManager
    
    public init() {
        self.manager = PipelineManager(config: .default)
    }
    
    // MARK: - Test Scenarios
    
    public func runAllTests() async {
        logger.info("🚀 Starting comprehensive pipeline tests")
        
        await testNormalStory()
        await testChaoticDreamNarrative()
        await testStreamOfConsciousness()
        await testFragmentedJournalEntry()
        await testMinimalInput()
        await testLongFormNarrative()
        await testDialogueHeavyStory()
        await testNonStandardPunctuation()
        
        logger.info("✅ All tests completed")
    }
    
    // MARK: - Individual Test Cases
    
    public func testNormalStory() async {
        logger.info("📖 Testing normal story")
        
        let story = """
        The old lighthouse stood at the edge of the cliff, its beam sweeping across 
        the dark waters below. Captain Sarah Hayes had been its keeper for fifteen years, 
        and she knew every crack in its weathered walls.
        
        Tonight was different though. The storm approaching from the east was unlike 
        anything she'd seen before. The waves were already reaching heights that made 
        her stomach turn.
        
        She checked her supplies one last time and lit the lamp. Whatever was coming, 
        she would be ready.
        """
        
        await executeTest(
            name: "Normal Story",
            story: story,
            config: .default
        )
    }
    
    public func testChaoticDreamNarrative() async {
        logger.info("💭 Testing chaotic dream narrative")
        
        let story = """
        Dear diary, I had a dream I went to school with no pants, but I knew it was 
        a dream even if I was sitting in mom's car while she's yelling THIS IS NOT 
        A DREAM, haha who is she kidding…
        
        But then like the car turned into a boat? And we were sailing through the 
        hallways of my school which makes no sense but also made perfect sense in 
        the dream logic you know?
        
        The principal was there dressed as a pirate. Or maybe he was always a pirate? 
        Hard to say. Dreams are weird.
        """
        
        await executeTest(
            name: "Chaotic Dream",
            story: story,
            config: .default,
            expectChaos: true
        )
    }
    
    public func testStreamOfConsciousness() async {
        logger.info("🌊 Testing stream of consciousness")
        
        let story = """
        thinking about pizza maybe or chinese no wait thai food sounds good but i 
        should probably eat healthier mom would be proud if i ate a salad haha who 
        am i kidding pizza it is definitely pizza with extra cheese and maybe some 
        wings too why not live a little right except my jeans are getting tight 
        maybe i should go to the gym tomorrow but tomorrows wednesday and wednesdays 
        are busy wait is tomorrow wednesday or thursday i always forget
        """
        
        await executeTest(
            name: "Stream of Consciousness",
            story: story,
            config: .quickProcess,
            expectChaos: true
        )
    }
    
    public func testFragmentedJournalEntry() async {
        logger.info("📝 Testing fragmented journal entry")
        
        let story = """
        Monday. Ugh.
        
        Coffee. Needed.
        
        Boss angry. Whatever.
        
        Lunch was good though. Thai place. Spicy.
        
        Met Sarah. Cute. Smiled at me.
        
        Maybe ask her out? Probably not. Too nervous.
        
        Home now. Netflix. Sleep soon.
        
        Tomorrow will be better. Maybe.
        """
        
        await executeTest(
            name: "Fragmented Journal",
            story: story,
            config: .segmentationOnly,
            expectChaos: true
        )
    }
    
    public func testMinimalInput() async {
        logger.info("🎯 Testing minimal input")
        
        let story = "Hello world."
        
        await executeTest(
            name: "Minimal Input",
            story: story,
            config: .quickProcess
        )
    }
    
    public func testLongFormNarrative() async {
        logger.info("📚 Testing long-form narrative")
        
        let story = String(repeating: """
        The journey began at dawn. The sun rose slowly over the mountains, 
        painting the sky in shades of orange and pink. Our hero set forth on 
        the winding path, knowing full well the dangers that lay ahead.
        
        """, count: 20)
        
        await executeTest(
            name: "Long-Form Narrative",
            story: story,
            config: .default
        )
    }
    
    public func testDialogueHeavyStory() async {
        logger.info("💬 Testing dialogue-heavy story")
        
        let story = """
        "Are you sure about this?" asked Tom.
        
        "Absolutely," replied Sarah. "What could go wrong?"
        
        "Everything," Tom muttered. "Everything could go wrong."
        
        "You worry too much."
        
        "And you don't worry enough."
        
        They stared at each other for a moment, then both burst out laughing.
        
        "Okay, let's do it," Tom finally said.
        """
        
        await executeTest(
            name: "Dialogue Heavy",
            story: story,
            config: .fullProcess
        )
    }
    
    public func testNonStandardPunctuation() async {
        logger.info("⁉️ Testing non-standard punctuation")
        
        let story = """
        WAIT!!!!! This is AMAZING!!!! I can't believe it worked?!?!?!
        
        Like... seriously... this is... WOW.
        
        Mom said "calm down" but HOW CAN I CALM DOWN when this is happening?!
        
        Best. Day. Ever.
        
        (okay maybe I'm exaggerating a little)
        """
        
        await executeTest(
            name: "Non-Standard Punctuation",
            story: story,
            config: .default,
            expectChaos: true
        )
    }
    
    // MARK: - Test Execution
    
    private func executeTest(
        name: String,
        story: String,
        config: PipelineConfig,
        expectChaos: Bool = false
    ) async {
        logger.info("▶️ Executing test: \(name)")
        
        manager.updateConfig(config)
        
        let input = PipelineInput(
            story: story,
            rewordType: .none,
            projectTitle: name
        )
        
        let startTime = Date()
        
        do {
            let output = try await manager.execute(input: input)
            let duration = Date().timeIntervalSince(startTime)
            
            logger.info("✅ Test '\(name)' passed in \(String(format: "%.2f", duration))s")
            logTestResults(output: output, expectChaos: expectChaos)
            
        } catch {
            logger.error("❌ Test '\(name)' failed: \(error.localizedDescription)")
        }
        
        // Small delay between tests
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    private func logTestResults(output: PipelineOutput, expectChaos: Bool) {
        logger.debug("""
        Results:
          - Segments: \(output.segments.count)
          - Characters: \(output.analysis?.characters.count ?? 0)
          - Locations: \(output.analysis?.locations.count ?? 0)
          - Confidence: \(String(format: "%.2f", output.analysis?.confidence ?? 0.0))
          - Method: \(output.analysis?.extractionMethod.rawValue ?? "Unknown")
        """)
        
        if expectChaos {
            logger.debug("  ✓ Chaotic input handled gracefully")
        }
    }
}

// MARK: - Test Story Generator

public struct TestStoryGenerator {
    
    public static func generateRandomStory(complexity: StoryComplexity = .medium) -> String {
        switch complexity {
        case .simple:
            return generateSimpleStory()
        case .medium:
            return generateMediumStory()
        case .complex:
            return generateComplexStory()
        case .chaotic:
            return generateChaoticStory()
        }
    }
    
    private static func generateSimpleStory() -> String {
        let templates = [
            "A cat sat on a mat. It was happy.",
            "The sun shone brightly. Birds sang cheerfully.",
            "She walked to the store. She bought milk."
        ]
        return templates.randomElement()!
    }
    
    private static func generateMediumStory() -> String {
        """
        The old house at the end of the street had been empty for years. 
        Local kids told stories about it being haunted, but Sarah didn't believe in ghosts.
        
        One autumn afternoon, she decided to explore it. The front door creaked open 
        at her touch. Inside, dust motes danced in the fading sunlight.
        
        As she walked through the rooms, she found old photographs and forgotten 
        memories. The house wasn't haunted - it was just lonely.
        """
    }
    
    private static func generateComplexStory() -> String {
        """
        Dr. Elizabeth Chen stood before the quantum computer, her life's work humming 
        softly in the climate-controlled room. After fifteen years of research, countless 
        failures, and more sleepless nights than she could count, they were finally ready 
        for the first test.
        
        "All systems nominal," her assistant, Marcus, called out from the control station. 
        His voice carried a mix of excitement and nervousness that mirrored her own feelings.
        
        The experiment would either revolutionize computing as they knew it or prove that 
        her theories were fundamentally flawed. There was no middle ground.
        
        Elizabeth took a deep breath. "Initialize the quantum entanglement protocol."
        
        The room filled with a subtle vibration as the system powered up. Lights flickered 
        across the console. Data streams began flowing across multiple monitors.
        
        Then, something unexpected happened. The quantum state didn't collapse as predicted. 
        Instead, it stabilized in a configuration that shouldn't have been possible according 
        to current theory.
        
        "Marcus," Elizabeth whispered, "are you seeing this?"
        
        "I... I don't understand. This is reading as if..." he paused, checking and 
        rechecking his instruments. "Elizabeth, I think we've just discovered something 
        completely new."
        """
    }
    
    private static func generateChaoticStory() -> String {
        """
        okay so like i was at the mall right and OMG you won't believe what happened!!!
        
        So theres this store right and im looking at shoes (cute ones btw) when suddenly
        this guy walks past and hes wearing THE EXACT SAME SHIRT as me!!!! like what 
        are the odds?!?!
        
        wait no that's not the crazy part... so then i see my ex?!?! with HER?!?! 
        and im like nope nope nope gotta leave NOW
        
        but then i remembered mom told me to get milk so i had to stay and try to 
        avoid them which was super awkward because the grocery store is right there
        
        long story short i hid behind the cereal aisle for like 20 minutes haha
        
        also i forgot to get the milk. mom's gonna be mad lol
        
        anyway how was your day???
        """
    }
}

public enum StoryComplexity {
    case simple
    case medium
    case complex
    case chaotic
}

// MARK: - Performance Monitor

public actor PerformanceMonitor {
    private var measurements: [String: [TimeInterval]] = [:]
    
    public func recordExecution(step: String, duration: TimeInterval) {
        if measurements[step] == nil {
            measurements[step] = []
        }
        measurements[step]?.append(duration)
    }
    
    public func getStatistics() -> [String: Statistics] {
        var stats: [String: Statistics] = [:]
        
        for (step, durations) in measurements {
            let avg = durations.reduce(0, +) / Double(durations.count)
            let min = durations.min() ?? 0
            let max = durations.max() ?? 0
            
            stats[step] = Statistics(
                average: avg,
                minimum: min,
                maximum: max,
                count: durations.count
            )
        }
        
        return stats
    }
    
    public func reset() {
        measurements.removeAll()
    }
}

public struct Statistics {
    public let average: TimeInterval
    public let minimum: TimeInterval
    public let maximum: TimeInterval
    public let count: Int
    
    public var summary: String {
        """
        Average: \(String(format: "%.2f", average))s
        Min: \(String(format: "%.2f", minimum))s
        Max: \(String(format: "%.2f", maximum))s
        Count: \(count)
        """
    }
}

// MARK: - Example Usage

#if DEBUG
@MainActor
public func runDebugTests() async {
    let harness = PipelineDebugHarness()
    await harness.runAllTests()
}

public func generateTestStories() {
    print("=== Generated Test Stories ===\n")
    
    for complexity in [StoryComplexity.simple, .medium, .complex, .chaotic] {
        print("\(complexity):")
        print(TestStoryGenerator.generateRandomStory(complexity: complexity))
        print("\n---\n")
    }
}
#endif
