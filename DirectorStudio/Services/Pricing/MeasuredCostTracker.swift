//
//  MeasuredCostTracker.swift
//  DirectorStudio
//
//  Cost tracker that uses MEASURED costs (not assumptions)
//  Initialize with data from ActualUsageMeasurement
//  Version: 3.1.0 (CORRECTED)
//

import Foundation
import OSLog

// MARK: - Measured Cost Tracker

/// Cost tracker initialized with MEASURED costs from calibration
/// DO NOT use hardcoded costs - initialize with ActualUsageMeasurement results
public actor MeasuredCostTracker {
    
    // MEASURED costs (from calibration)
    private let measuredCostPer1KChars: Double
    private let measuredTokensPerChar: Double
    
    // DECIDED pricing
    private let pricePerCredit: Double
    private let charsPerCredit: Int
    
    // Usage tracking
    private var charactersProcessed: Int = 0
    private var actualTokensUsed: (input: Int, output: Int) = (0, 0)
    
    private let logger = Logger(subsystem: "com.directorstudio.pricing", category: "measured_cost_tracker")
    
    // MARK: - Initialization
    
    /// Initialize with MEASURED costs from calibration
    /// - Parameters:
    ///   - measuredCostPer1KChars: Cost per 1,000 characters (from UsagePatternAnalyzer)
    ///   - measuredTokensPerChar: Average tokens per character (from UsagePatternAnalyzer)
    ///   - pricePerCredit: YOUR pricing decision (e.g., $0.005)
    ///   - charsPerCredit: Characters per credit (e.g., 1000)
    public init(
        measuredCostPer1KChars: Double,
        measuredTokensPerChar: Double,
        pricePerCredit: Double,
        charsPerCredit: Int = 1000
    ) {
        self.measuredCostPer1KChars = measuredCostPer1KChars
        self.measuredTokensPerChar = measuredTokensPerChar
        self.pricePerCredit = pricePerCredit
        self.charsPerCredit = charsPerCredit
        
        logger.info("""
        ✅ MeasuredCostTracker initialized:
           Measured Cost: $\(String(format: "%.6f", measuredCostPer1KChars)) per 1K chars
           Token Ratio: \(String(format: "%.3f", measuredTokensPerChar)) tokens/char
           Price: $\(String(format: "%.4f", pricePerCredit)) per credit
           Credit Unit: \(charsPerCredit) characters
        """)
    }
    
    /// Convenience initializer from UsagePattern
    public convenience init(
        from pattern: UsagePattern,
        pricePerCredit: Double,
        charsPerCredit: Int = 1000
    ) {
        self.init(
            measuredCostPer1KChars: pattern.avgCostPer1000Chars,
            measuredTokensPerChar: pattern.avgTokensPerCharacter,
            pricePerCredit: pricePerCredit,
            charsPerCredit: charsPerCredit
        )
    }
    
    // MARK: - Track Usage
    
    public func trackProcessing(
        characterCount: Int,
        actualInputTokens: Int = 0,
        actualOutputTokens: Int = 0
    ) {
        charactersProcessed += characterCount
        
        if actualInputTokens > 0 || actualOutputTokens > 0 {
            actualTokensUsed.input += actualInputTokens
            actualTokensUsed.output += actualOutputTokens
        }
        
        let estimatedCost = calculateCost(characterCount: characterCount)
        
        logger.debug("""
        📊 Processing tracked:
           Characters: \(characterCount)
           Estimated Cost: $\(String(format: "%.6f", estimatedCost))
           Actual Tokens: \(actualInputTokens) in / \(actualOutputTokens) out
        """)
    }
    
    // MARK: - Calculations
    
    public func calculateCost(characterCount: Int) -> Double {
        let blocks = Double(characterCount) / 1000.0
        return blocks * measuredCostPer1KChars
    }
    
    public func calculateCreditsRequired(characterCount: Int) -> Int {
        return Int(ceil(Double(characterCount) / Double(charsPerCredit)))
    }
    
    public func calculateUserPrice(characterCount: Int) -> Double {
        let credits = calculateCreditsRequired(characterCount: characterCount)
        return Double(credits) * pricePerCredit
    }
    
    public func calculateProfit(characterCount: Int) -> Double {
        return calculateUserPrice(characterCount: characterCount) - 
               calculateCost(characterCount: characterCount)
    }
    
    public func calculateMarginPercent(characterCount: Int) -> Double {
        let price = calculateUserPrice(characterCount: characterCount)
        let profit = calculateProfit(characterCount: characterCount)
        return (profit / price) * 100.0
    }
    
    // MARK: - Get Summary
    
    public func getSummary() -> CostSummary {
        let totalCost = calculateCost(characterCount: charactersProcessed)
        let totalCredits = calculateCreditsRequired(characterCount: charactersProcessed)
        let totalPrice = calculateUserPrice(characterCount: charactersProcessed)
        let totalProfit = totalPrice - totalCost
        let marginPercent = charactersProcessed > 0 ? (totalProfit / totalPrice) * 100.0 : 0.0
        
        // Calculate actual token cost if we have token data
        var actualTokenCost: Double = 0.0
        if actualTokensUsed.input > 0 || actualTokensUsed.output > 0 {
            actualTokenCost = (Double(actualTokensUsed.input) / 1_000_000.0 * 0.14) +
                             (Double(actualTokensUsed.output) / 1_000_000.0 * 0.28)
        }
        
        return CostSummary(
            charactersProcessed: charactersProcessed,
            creditsRequired: totalCredits,
            estimatedCost: totalCost,
            actualTokenCost: actualTokenCost,
            userPrice: totalPrice,
            profit: totalProfit,
            marginPercent: marginPercent,
            tokensUsed: actualTokensUsed,
            measuredCostPer1K: measuredCostPer1KChars,
            pricePerCredit: pricePerCredit
        )
    }
    
    public func logSummary() {
        let summary = getSummary()
        
        logger.info("""
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        💰 COST SUMMARY (MEASURED DATA)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        📝 USAGE:
           Characters Processed: \(summary.charactersProcessed.formatted())
           Credits Required:     \(summary.creditsRequired)
        
        💵 COSTS:
           Estimated Cost:       $\(String(format: "%.6f", summary.estimatedCost))
           Actual Token Cost:    $\(String(format: "%.6f", summary.actualTokenCost))
           Cost per 1K chars:    $\(String(format: "%.6f", summary.measuredCostPer1K))
        
        💰 REVENUE:
           User Price:           $\(String(format: "%.4f", summary.userPrice))
           Price per Credit:     $\(String(format: "%.4f", summary.pricePerCredit))
        
        📊 PROFIT:
           Profit:               $\(String(format: "%.6f", summary.profit))
           Margin:               \(String(format: "%.1f", summary.marginPercent))%
        
        🤖 TOKENS:
           Input:                \(summary.tokensUsed.input.formatted())
           Output:               \(summary.tokensUsed.output.formatted())
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }
    
    public func reset() {
        charactersProcessed = 0
        actualTokensUsed = (0, 0)
        logger.info("🔄 Cost tracker reset")
    }
}

// MARK: - Cost Summary

public struct CostSummary: Sendable {
    public let charactersProcessed: Int
    public let creditsRequired: Int
    public let estimatedCost: Double
    public let actualTokenCost: Double
    public let userPrice: Double
    public let profit: Double
    public let marginPercent: Double
    public let tokensUsed: (input: Int, output: Int)
    public let measuredCostPer1K: Double
    public let pricePerCredit: Double
    
    public var isProfitable: Bool {
        marginPercent >= 50.0
    }
    
    public var warningLevel: WarningLevel {
        if marginPercent < 25.0 {
            return .critical
        } else if marginPercent < 50.0 {
            return .warning
        } else {
            return .healthy
        }
    }
    
    public enum WarningLevel: String, Sendable {
        case healthy = "✅ Healthy"
        case warning = "⚠️ Warning"
        case critical = "🚨 Critical"
    }
}

// MARK: - Example Usage

/*
 
 CORRECT USAGE:
 
 // Step 1: Run calibration first
 let calibrator = CostCalibrationTool()
 await calibrator.calibrateWithSampleStories(sampleStories)
 
 // Step 2: Get measured pattern
 let analyzer = UsagePatternAnalyzer()
 let pattern = await analyzer.analyzePatterns()
 
 // Step 3: Create tracker with MEASURED data
 let tracker = MeasuredCostTracker(
     from: pattern,
     pricePerCredit: 0.005  // YOUR decision based on pattern
 )
 
 // Step 4: Track real usage
 await tracker.trackProcessing(
     characterCount: story.count,
     actualInputTokens: apiResponse.inputTokens,
     actualOutputTokens: apiResponse.outputTokens
 )
 
 // Step 5: Get summary
 let summary = await tracker.getSummary()
 print("Profit margin: \(summary.marginPercent)%")
 
 */
