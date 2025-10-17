import SwiftUI

// MARK: - LIBRARY TAB - Adaptive Grid with Delete
struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var projectToDelete: Project?
    @State private var showDeleteAlert = false
    
    var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            // iPad/Mac: 3-4 columns
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        } else {
            // iPhone: 2 columns
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if appState.projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder",
                        description: Text("Create your first story in the Create tab")
                    )
                    .foregroundColor(.white)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(appState.projects) { project in
                                ProjectCard(
                                    project: project,
                                    onDelete: {
                                        projectToDelete = project
                                        showDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Delete Project?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        appState.deleteProject(project)
                    }
                }
            } message: {
                Text("This action cannot be undone. All scenes and data will be permanently deleted.")
            }
        }
    }
}
