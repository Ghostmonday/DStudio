import SwiftUI
import AVKit

// MARK: - Clip Preview Card
struct ClipPreviewCard: View {
    let clipJob: ClipJob
    @State private var showingPlayer = false
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.blue)
                
                Text("Scene \(clipJob.wrappedSceneId)")
                    .font(.headline)
                
                Spacer()
                
                StatusBadge(status: clipJob.wrappedStatus)
            }
            
            // Video Preview
            if let videoURL = clipJob.wrappedVideoURL,
               let url = URL(string: videoURL) {
                Button(action: { showingPlayer = true }) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(8)
                            .overlay(
                                // Play button overlay
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            )
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.2)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Placeholder for generating video
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("Generating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // Footer
            HStack {
                Text(clipJob.wrappedCreatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if clipJob.wrappedStatus == "failed" {
                    Button("Retry") {
                        // Retry generation
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingPlayer) {
            if let videoURL = clipJob.wrappedVideoURL,
               let url = URL(string: videoURL) {
                VideoPlayerView(url: url)
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .foregroundColor(statusColor)
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "completed", "success":
            return .green
        case "processing", "pending":
            return .orange
        case "failed", "error":
            return .red
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch status.lowercased() {
        case "completed", "success":
            return "Complete"
        case "processing", "pending":
            return "Processing"
        case "failed", "error":
            return "Failed"
        default:
            return status.capitalized
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: url))
                .navigationTitle("Video Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleClip = ClipJob(context: context)
    sampleClip.id = UUID()
    sampleClip.scene_id = 1
    sampleClip.taskId = "sample_task_123"
    sampleClip.status = "completed"
    sampleClip.videoURL = "https://example.com/video.mp4"
    sampleClip.createdAt = Date()
    sampleClip.updatedAt = Date()
    
    return ClipPreviewCard(clipJob: sampleClip)
        .padding()
}
