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
                        
                        Text("Step \(pipeline.currentStep) of 6")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            Text("Processing Complete!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
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