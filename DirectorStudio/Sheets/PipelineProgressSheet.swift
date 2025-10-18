import SwiftUI

// MARK: - Pipeline Progress Sheet
struct PipelineProgressSheet: View {
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @Environment(\.dismiss) var dismiss
    @Binding var isProcessing: Bool
    @Binding var processingComplete: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.purple)
                            .padding()
                        
                        Text("Processing your story...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Analyzing story structure and generating segments")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    } else if processingComplete {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            Text("Processing Complete!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your story has been processed and is ready in the Studio tab.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                            
                            Text("Ready to Process")
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
                if processingComplete {
                    Button("Done") { dismiss() }
                } else if !isProcessing {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}