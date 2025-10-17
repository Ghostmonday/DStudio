import SwiftUI

struct ProjectCard: View {
    let project: Project
    var onDelete: (() -> Void)?
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "film.fill")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                
                Spacer()
                
                if onDelete != nil {
                    Button(action: { showMenu = true }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gray)
                    }
                    .confirmationDialog("Project Options", isPresented: $showMenu) {
                        Button("Delete", role: .destructive) {
                            onDelete?()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            
            Text(project.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text("\(project.segments.count) scenes")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(project.updatedAt, style: .date)
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .frame(height: 180)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}
