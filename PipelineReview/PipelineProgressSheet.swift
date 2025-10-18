import SwiftUI

// MARK: - Pipeline Progress Sheet
struct PipelineProgressSheet: View {
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if pipeline.isRunning {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.purple)
                            .padding()
                        
                        Text("Processing your story...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 16) {
                        PipelineStepView(
                            number: 1,
                            title: "Rewording",
                            isActive: pipeline.currentStep == 1,
                            isComplete: pipeline.completedSteps.contains(1)
                        )
                        
                        PipelineStepView(
                            number: 2,
                            title: "Story Analysis",
                            isActive: pipeline.currentStep == 2,
                            isComplete: pipeline.completedSteps.contains(2)
                        )
                        
                        PipelineStepView(
                            number: 3,
                            title: "Prompt Segmentation",
                            isActive: pipeline.currentStep == 3,
                            isComplete: pipeline.completedSteps.contains(3)
                        )
                        
                        PipelineStepView(
                            number: 4,
                            title: "Cinematic Taxonomy",
                            isActive: pipeline.currentStep == 4,
                            isComplete: pipeline.completedSteps.contains(4)
                        )
                        
                        PipelineStepView(
                            number: 5,
                            title: "Continuity Anchors",
                            isActive: pipeline.currentStep == 5,
                            isComplete: pipeline.completedSteps.contains(5)
                        )
                        
                        PipelineStepView(
                            number: 6,
                            title: "Package Screenplay",
                            isActive: pipeline.currentStep == 6,
                            isComplete: pipeline.completedSteps.contains(6)
                        )
                    }
                    .padding()
                    
                    if pipeline.completedSteps.count == 6 {
                        Button("View in Studio") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                    
                    if let error = pipeline.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
            }
            .navigationTitle("AI Processing")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if !pipeline.isRunning {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
