import SwiftUI

// MARK: - STUDIO TAB - Show Processing Results with Export
struct StudioView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: DirectorStudioPipeline
    @State private var showExportSheet = false
    @State private var exportFormat: ExportFormat = .screenplay
    @State private var showShareSheet = false
    @State private var exportedContent = ""
    
    enum ExportFormat: String, CaseIterable {
        case screenplay = "Screenplay (.txt)"
        case json = "JSON Data (.json)"
        case promptList = "Prompt List (.txt)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let project = appState.currentProject, !pipeline.segmentationModule.segments.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Project Header with Export Button
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.title)
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        if let analysis = project.analysis {
                                            HStack(spacing: 16) {
                                                Label("\(analysis.characterCount) characters", systemImage: "person.2")
                                                Label("\(analysis.sceneCount) scenes", systemImage: "film")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { showExportSheet = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Export")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            
                            // Scene Segments
                            ForEach(pipeline.segmentationModule.segments) { segment in
                                SceneCard(segment: segment)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Scenes Yet",
                        systemImage: "film.stack",
                        description: Text("Create a story in the Create tab to get started")
                    )
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Studio")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(
                    project: appState.currentProject,
                    selectedFormat: $exportFormat,
                    showShareSheet: $showShareSheet,
                    exportedContent: $exportedContent
                )
            }
            #if os(iOS)
            .sheet(isPresented: $showShareSheet) {
                if let project = appState.currentProject {
                    ShareSheet(activityItems: [exportedContent])
                }
            }
            #endif
        }
    }
}
