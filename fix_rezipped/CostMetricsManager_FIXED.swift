//
//  CostMetricsManager.swift
//  DirectorStudio
//
//  Complete cost tracking for video generation and story processing
//

import Foundation
import OSLog

/// Manages cost tracking and metrics for all DirectorStudio operations
public class CostMetricsManager {
    public static let shared = CostMetricsManager()
    
    private let logger = Logger(subsystem: "com.directorstudio.cost", category: "metrics")
    
    // Cost tracking storage
    private var totalRevenue: Double = 0.0
    private var totalAPICost: Double = 0.0
    private var scenesProcessed: Int = 0
    
    private init() {
        loadCostData()
    }
    
    // MARK: - Video Generation Tracking
    
    /// Tracks video generation costs
    public func trackVideoGeneration(
        sceneId: String,
        durationSeconds: Int,
        userSelectedTier: String
    ) {
        let userCharge = calculateVideoCharge(tier: userSelectedTier)
        let apiCost = calculateVideoAPICost(durationSeconds: durationSeconds)
        
        totalRevenue += userCharge
        totalAPICost += apiCost
        scenesProcessed += 1
        
        saveCostData()
        
        logger.info("""
        🎬 Video Generation Tracked:
           Scene: \(sceneId)
           Duration: \(durationSeconds)s
           Tier: \(userSelectedTier)
           User Charge: $\(String(format: "%.2f", userCharge))
           API Cost: $\(String(format: "%.4f", apiCost))
           Margin: \(String(format: "%.1f", self.calculateMargin(charge: userCharge, cost: apiCost)))%
        """)
    }
    
    /// Tracks story processing costs
    public func trackStoryProcessing(
        sceneId: String,
        characters: Int,
        tier: String,
        inputTokens: Int,
        outputTokens: Int
    ) {
        let userCharge = calculateStoryCharge(tier: tier)
        let apiCost = calculateClaudeAPICost(inputTokens: inputTokens, outputTokens: outputTokens)
        
        totalRevenue += userCharge
        totalAPICost += apiCost
        
        saveCostData()
        
        logger.info("""
        📝 Story Processing Tracked:
           Scene: \(sceneId)
           Characters: \(characters)
           Tier: \(tier)
           Tokens: \(inputTokens) in / \(outputTokens) out
           User Charge: $\(String(format: "%.2f", userCharge))
           API Cost: $\(String(format: "%.6f", apiCost))
           Margin: \(String(format: "%.1f", self.calculateMargin(charge: userCharge, cost: apiCost)))%
        """)
    }
    
    // MARK: - Cost Calculations
    
    private func calculateStoryCharge(tier: String) -> Double {
        switch tier.lowercased() {
        case "short": return 8.08
        case "medium": return 8.16
        case "long": return 8.48
        default: return 8.16
        }
    }
    
    private func calculateVideoCharge(tier: String) -> Double {
        switch tier.lowercased() {
        case "20sec": return 1.12
        case "30sec": return 1.68
        case "60sec": return 3.36
        default: return 1.12
        }
    }
    
    private func calculateClaudeAPICost(inputTokens: Int, outputTokens: Int) -> Double {
        let inputCost = Double(inputTokens) * 0.000003  // $3 per 1M tokens
        let outputCost = Double(outputTokens) * 0.000015 // $15 per 1M tokens
        return inputCost + outputCost
    }
    
    private func calculateVideoAPICost(durationSeconds: Int) -> Double {
        return Double(durationSeconds) * 0.05 // $0.05 per second (adjust for your provider)
    }
    
    private func calculateMargin(charge: Double, cost: Double) -> Double {
        guard charge > 0 else { return 0 }
        return ((charge - cost) / charge) * 100.0
    }
    
    // MARK: - Statistics
    
    public func getStatistics() -> CostStatistics {
        let profit = totalRevenue - totalAPICost
        let margin = totalRevenue > 0 ? (profit / totalRevenue) * 100.0 : 0.0
        
        return CostStatistics(
            totalRevenue: totalRevenue,
            totalCost: totalAPICost,
            totalProfit: profit,
            profitMargin: margin,
            scenesProcessed: scenesProcessed,
            avgCostPerScene: scenesProcessed > 0 ? totalAPICost / Double(scenesProcessed) : 0.0
        )
    }
    
    public func printSummary() {
        let stats = getStatistics()
        
        logger.info("""
        
        ═══════════════════════════════════════════════════════════
        📊 DirectorStudio Cost Summary
        ═══════════════════════════════════════════════════════════
        Total Revenue:     $\(String(format: "%.2f", stats.totalRevenue))
        Total Costs:       $\(String(format: "%.2f", stats.totalCost))
        Net Profit:        $\(String(format: "%.2f", stats.totalProfit))
        Profit Margin:     \(String(format: "%.1f", stats.profitMargin))%
        Scenes Processed:  \(stats.scenesProcessed)
        Avg Cost/Scene:    $\(String(format: "%.2f", stats.avgCostPerScene))
        ═══════════════════════════════════════════════════════════
        """)
    }
    
    public func reset() {
        totalRevenue = 0.0
        totalAPICost = 0.0
        scenesProcessed = 0
        saveCostData()
        logger.info("💰 Cost metrics reset")
    }
    
    // MARK: - Persistence
    
    private func loadCostData() {
        totalRevenue = UserDefaults.standard.double(forKey: "DirectorStudio.totalRevenue")
        totalAPICost = UserDefaults.standard.double(forKey: "DirectorStudio.totalAPICost")
        scenesProcessed = UserDefaults.standard.integer(forKey: "DirectorStudio.scenesProcessed")
    }
    
    private func saveCostData() {
        UserDefaults.standard.set(totalRevenue, forKey: "DirectorStudio.totalRevenue")
        UserDefaults.standard.set(totalAPICost, forKey: "DirectorStudio.totalAPICost")
        UserDefaults.standard.set(scenesProcessed, forKey: "DirectorStudio.scenesProcessed")
    }
}

// MARK: - Cost Statistics

public struct CostStatistics {
    public let totalRevenue: Double
    public let totalCost: Double
    public let totalProfit: Double
    public let profitMargin: Double
    public let scenesProcessed: Int
    public let avgCostPerScene: Double
}
