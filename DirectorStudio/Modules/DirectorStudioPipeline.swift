//
//  DirectorStudioPipeline.swift
//  DirectorStudio
//
//

import Foundation

@MainActor
public class DirectorStudioPipeline: ObservableObject {
    @Published public var isRunning: Bool = false
    @Published public var currentStep: Int = 0
    @Published public var errorMessage: String?
    
    public init() {
        // Initialize with default values
    }
    
    /// Simplified pipeline method
    public func runFullPipeline(
        story: String,
        rewordType: String?,
        projectTitle: String,
        enableTransform: Bool = true,
        enableCinematic: Bool = true,
        enableBreakdown: Bool = true
    ) async {
        await MainActor.run {
            self.isRunning = true
            self.currentStep = 1
        }
        
        // Simulate processing
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            self.isRunning = false
            self.currentStep = 0
        }
    }
}
