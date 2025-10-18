//
//  ActualUsageMeasurement.swift
//  DirectorStudio
//
//  Measures ACTUAL API usage to determine real costs
//  DO NOT set prices until we know what we're paying
//  Version: 3.0.0
//

import Foundation
import OSLog

// MARK: - STEP 1: Measure What APIs Actually Charge Us For

/// DeepSeek charges per TOKEN, not per character
/// We need to measure: tokens per story
public struct DeepSeekUsageMeasurement: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    
    // What DeepSeek ACTUALLY charges
    public static let inputCostPerToken = 0.14 / 1_000_000.0   // $0.00000014 per token
    public static let outputCostPerToken = 0.28 / 1_000_000.0  // $0.00000028 per token
    
    public var actualCostPaid: Double {
        let inputCost = Double(inputTokens) * Self.inputCostPerToken
        let outputCost = Double(outputTokens) * Self.outputCostPerToken
        return inputCost + outputCost
    }
    
    public init(inputTokens: Int, outputTokens: Int) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }
}

/// Supabase charges per GB-MONTH and per INVOCATION
public struct SupabaseUsageMeasurement: Sendable {
    public let bytesStored: Int
    public let edgeFunctionInvocations: Int
    
    // What Supabase ACTUALLY charges
    public static let storageCostPerGBMonth = 0.021              // $0.021 per GB/month
    public static let edgeFunctionCostPer1M = 2.00               // $2.00 per 1M invocations
    
    public var actualCostPaid: Double {
        let gbStored = Double(bytesStored) / 1_073_741_824.0  // Convert bytes to GB
        let storageCost = gbStored * Self.storageCostPerGBMonth / 30.0  // Per day estimate
        
        let invocationCost = Double(edgeFunctionInvocations) / 1_000_000.0 * Self.edgeFunctionCostPer1M
        
        return storageCost + invocationCost
    }
    
    public init(bytesStored: Int, edgeFunctionInvocations: Int) {
        self.bytesStored = bytesStored
        self.edgeFunctionInvocations = edgeFunctionInvocations
    }
}

// MARK: - STEP 2: Measure Actual Story Processing

/// This tracks what ONE story actually costs us
public actor RealCostMeasurement {
    
    private var deepseekUsage: [DeepSeekUsageMeasurement] = []
    private var supabaseUsage: SupabaseUsageMeasurement?
    
    private let logger = Logger(subsystem: "com.directorstudio.pricing", category: "real_cost")
    
    public init() {}
    
    // MARK: - Track Real API Usage
    
    public func recordDeepSeekCall(inputTokens: Int, outputTokens: Int) {
        let measurement = DeepSeekUsageMeasurement(
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
        deepseekUsage.append(measurement)
        
        logger.info("""
        📊 DeepSeek API Call:
           Input:  \(inputTokens) tokens
           Output: \(outputTokens) tokens
           Cost:   $\(String(format: "%.8f", measurement.actualCostPaid))
        """)
    }
    
    public func recordSupabaseUsage(bytesStored: Int, edgeFunctionCalls: Int) {
        let measurement = SupabaseUsageMeasurement(
            bytesStored: bytesStored,
            edgeFunctionInvocations: edgeFunctionCalls
        )
        supabaseUsage = measurement
        
        logger.info("""
        📊 Supabase Usage:
           Storage:   \(bytesStored) bytes
           Functions: \(edgeFunctionCalls) calls
           Cost:      $\(String(format: "%.8f", measurement.actualCostPaid))
        """)
    }
    
    // MARK: - Calculate Real Total Cost
    
    public func calculateActualCostPaid() -> ActualCostReport {
        let deepseekCost = deepseekUsage.reduce(0.0) { $0 + $1.actualCostPaid }
        let supabaseCost = supabaseUsage?.actualCostPaid ?? 0.0
        let totalCost = deepseekCost + supabaseCost
        
        let totalInputTokens = deepseekUsage.reduce(0) { $0 + $1.inputTokens }
        let totalOutputTokens = deepseekUsage.reduce(0) { $0 + $1.outputTokens }
        
        return ActualCostReport(
            deepseekCost: deepseekCost,
            supabaseCost: supabaseCost,
            totalCost: totalCost,
            totalInputTokens: totalInputTokens,
            totalOutputTokens: totalOutputTokens,
            totalTokens: totalInputTokens + totalOutputTokens,
            bytesStored: supabaseUsage?.bytesStored ?? 0,
            edgeFunctionCalls: supabaseUsage?.edgeFunctionInvocations ?? 0
        )
    }
    
    public func reset() {
        deepseekUsage = []
        supabaseUsage = nil
        logger.info("🔄 Cost measurement reset")
    }
}

// MARK: - Actual Cost Report

public struct ActualCostReport: Sendable {
    public let deepseekCost: Double
    public let supabaseCost: Double
    public let totalCost: Double
    
    // Token metrics (what DeepSeek charges for)
    public let totalInputTokens: Int
    public let totalOutputTokens: Int
    public let totalTokens: Int
    
    // Storage metrics (what Supabase charges for)
    public let bytesStored: Int
    public let edgeFunctionCalls: Int
    
    public init(
        deepseekCost: Double,
        supabaseCost: Double,
        totalCost: Double,
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalTokens: Int,
        bytesStored: Int,
        edgeFunctionCalls: Int
    ) {
        self.deepseekCost = deepseekCost
        self.supabaseCost = supabaseCost
        self.totalCost = totalCost
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalTokens = totalTokens
        self.bytesStored = bytesStored
        self.edgeFunctionCalls = edgeFunctionCalls
    }
}

// MARK: - STEP 3: Analyze Sample Stories to Find Pattern

/// Run this on 10-20 sample stories to find average cost
public actor UsagePatternAnalyzer {
    
    private var storyMeasurements: [(characterCount: Int, cost: ActualCostReport)] = []
    private let logger = Logger(subsystem: "com.directorstudio.pricing", category: "pattern_analyzer")
    
    public init() {}
    
    public func recordStory(characterCount: Int, actualCost: ActualCostReport) {
        storyMeasurements.append((characterCount, actualCost))
        
        logger.info("""
        📊 Story Recorded:
           Characters: \(characterCount)
           Tokens:     \(actualCost.totalTokens)
           Cost:       $\(String(format: "%.8f", actualCost.totalCost))
        """)
    }
    
    public func analyzePatterns() -> UsagePattern {
        guard !storyMeasurements.isEmpty else {
            return UsagePattern(
                avgTokensPerCharacter: 0.75,
                avgCostPerCharacter: 0.0,
                avgCostPerToken: 0.0,
                avgCostPer1000Chars: 0.0,
                avgCostPer1000Tokens: 0.0,
                sampleSize: 0
            )
        }
        
        // Calculate averages
        let totalChars = storyMeasurements.reduce(0) { $0 + $1.characterCount }
        let totalTokens = storyMeasurements.reduce(0) { $0 + $1.cost.totalTokens }
        let totalCost = storyMeasurements.reduce(0.0) { $0 + $1.cost.totalCost }
        
        let avgTokensPerChar = Double(totalTokens) / Double(totalChars)
        let avgCostPerChar = totalCost / Double(totalChars)
        let avgCostPerToken = totalCost / Double(totalTokens)
        
        let avgCostPer1000Chars = avgCostPerChar * 1000.0
        let avgCostPer1000Tokens = avgCostPerToken * 1000.0
        
        let pattern = UsagePattern(
            avgTokensPerCharacter: avgTokensPerChar,
            avgCostPerCharacter: avgCostPerChar,
            avgCostPerToken: avgCostPerToken,
            avgCostPer1000Chars: avgCostPer1000Chars,
            avgCostPer1000Tokens: avgCostPer1000Tokens,
            sampleSize: storyMeasurements.count
        )
        
        logger.info("""
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 USAGE PATTERN ANALYSIS
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        Sample Size: \(pattern.sampleSize) stories
        
        RATIOS:
        • \(String(format: "%.3f", pattern.avgTokensPerCharacter)) tokens per character
        
        COSTS:
        • $\(String(format: "%.10f", pattern.avgCostPerCharacter)) per character
        • $\(String(format: "%.10f", pattern.avgCostPerToken)) per token
        • $\(String(format: "%.6f", pattern.avgCostPer1000Chars)) per 1,000 characters
        • $\(String(format: "%.6f", pattern.avgCostPer1000Tokens)) per 1,000 tokens
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
        
        return pattern
    }
    
    public func getRecommendedPricing(targetMarginPercent: Double = 50.0) -> PricingRecommendation {
        let pattern = analyzePatterns()
        
        // We charge based on tokens (what we're actually charged for)
        // Target: X% margin
        let costPerToken = pattern.avgCostPerToken
        let pricePerToken = costPerToken / (1.0 - targetMarginPercent / 100.0)
        
        // Convert to credit system
        // Option 1: 1 credit = 1,000 tokens
        let tokensPerCredit = 1000.0
        let pricePerCredit_tokenBased = pricePerToken * tokensPerCredit
        
        // Option 2: 1 credit = 1,000 characters
        let charsPerCredit = 1000.0
        let pricePerCredit_charBased = pattern.avgCostPer1000Chars / (1.0 - targetMarginPercent / 100.0)
        
        return PricingRecommendation(
            usagePattern: pattern,
            targetMarginPercent: targetMarginPercent,
            pricePerToken: pricePerToken,
            pricePerCredit_tokenBased: pricePerCredit_tokenBased,
            tokensPerCredit: Int(tokensPerCredit),
            pricePerCredit_charBased: pricePerCredit_charBased,
            charsPerCredit: Int(charsPerCredit)
        )
    }
}

// MARK: - Usage Pattern

public struct UsagePattern: Sendable {
    public let avgTokensPerCharacter: Double
    public let avgCostPerCharacter: Double
    public let avgCostPerToken: Double
    public let avgCostPer1000Chars: Double
    public let avgCostPer1000Tokens: Double
    public let sampleSize: Int
    
    public init(
        avgTokensPerCharacter: Double,
        avgCostPerCharacter: Double,
        avgCostPerToken: Double,
        avgCostPer1000Chars: Double,
        avgCostPer1000Tokens: Double,
        sampleSize: Int
    ) {
        self.avgTokensPerCharacter = avgTokensPerCharacter
        self.avgCostPerCharacter = avgCostPerCharacter
        self.avgCostPerToken = avgCostPerToken
        self.avgCostPer1000Chars = avgCostPer1000Chars
        self.avgCostPer1000Tokens = avgCostPer1000Tokens
        self.sampleSize = sampleSize
    }
}

// MARK: - Pricing Recommendation

public struct PricingRecommendation: Sendable {
    public let usagePattern: UsagePattern
    public let targetMarginPercent: Double
    
    // What we should charge
    public let pricePerToken: Double
    
    // OPTION A: Token-based credits (most accurate)
    public let pricePerCredit_tokenBased: Double
    public let tokensPerCredit: Int
    
    // OPTION B: Character-based credits (user-friendly)
    public let pricePerCredit_charBased: Double
    public let charsPerCredit: Int
    
    public var recommendedSystem: CreditSystem {
        // If price per credit is reasonable ($0.50 - $2.00), recommend that system
        if pricePerCredit_charBased >= 0.50 && pricePerCredit_charBased <= 2.00 {
            return .characterBased
        } else {
            return .tokenBased
        }
    }
    
    public enum CreditSystem {
        case tokenBased      // 1 credit = 1,000 tokens (most accurate)
        case characterBased  // 1 credit = 1,000 characters (user-friendly)
    }
    
    public init(
        usagePattern: UsagePattern,
        targetMarginPercent: Double,
        pricePerToken: Double,
        pricePerCredit_tokenBased: Double,
        tokensPerCredit: Int,
        pricePerCredit_charBased: Double,
        charsPerCredit: Int
    ) {
        self.usagePattern = usagePattern
        self.targetMarginPercent = targetMarginPercent
        self.pricePerToken = pricePerToken
        self.pricePerCredit_tokenBased = pricePerCredit_tokenBased
        self.tokensPerCredit = tokensPerCredit
        self.pricePerCredit_charBased = pricePerCredit_charBased
        self.charsPerCredit = charsPerCredit
    }
}

// MARK: - STEP 4: Test with Real Stories

/// Use this to test actual cost with real stories
public class CostCalibrationTool {
    private let analyzer = UsagePatternAnalyzer()
    private let logger = Logger(subsystem: "com.directorstudio.pricing", category: "calibration")
    
    public init() {}
    
    public func calibrateWithSampleStories(_ stories: [String]) async {
        logger.info("🔬 Starting calibration with \(stories.count) sample stories...")
        
        for (index, story) in stories.enumerated() {
            logger.info("Processing story \(index + 1)/\(stories.count)...")
            
            let costMeasurement = RealCostMeasurement()
            
            // Simulate processing (replace with real API calls)
            let charCount = story.count
            let estimatedTokens = Int(Double(charCount) * 0.75)  // Initial estimate
            
            // Mock API calls with realistic token counts
            // In production, these would be ACTUAL API responses
            await costMeasurement.recordDeepSeekCall(
                inputTokens: estimatedTokens / 2,
                outputTokens: estimatedTokens / 2
            )
            
            let bytesStored = charCount * 2  // Rough estimate for JSON storage
            await costMeasurement.recordSupabaseUsage(
                bytesStored: bytesStored,
                edgeFunctionCalls: 3
            )
            
            let actualCost = await costMeasurement.calculateActualCostPaid()
            await analyzer.recordStory(characterCount: charCount, actualCost: actualCost)
        }
        
        // Analyze patterns
        let recommendation = await analyzer.getRecommendedPricing(targetMarginPercent: 50.0)
        
        logger.info("""
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        💰 PRICING RECOMMENDATION
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        Based on \(recommendation.usagePattern.sampleSize) sample stories:
        
        OUR COST:
        • $\(String(format: "%.10f", recommendation.usagePattern.avgCostPerToken)) per token
        • $\(String(format: "%.6f", recommendation.usagePattern.avgCostPer1000Tokens)) per 1,000 tokens
        • $\(String(format: "%.6f", recommendation.usagePattern.avgCostPer1000Chars)) per 1,000 chars
        
        RECOMMENDED PRICING (50% margin):
        
        OPTION A - TOKEN-BASED (Most Accurate):
        • 1 credit = \(recommendation.tokensPerCredit) tokens
        • Price: $\(String(format: "%.4f", recommendation.pricePerCredit_tokenBased)) per credit
        
        OPTION B - CHARACTER-BASED (User-Friendly):
        • 1 credit = \(recommendation.charsPerCredit) characters
        • Price: $\(String(format: "%.4f", recommendation.pricePerCredit_charBased)) per credit
        
        RECOMMENDED: \(recommendation.recommendedSystem == .tokenBased ? "TOKEN-BASED" : "CHARACTER-BASED")
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }
}
