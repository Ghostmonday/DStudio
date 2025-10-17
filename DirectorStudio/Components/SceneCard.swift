import SwiftUI

struct SceneCard: View {
    let segment: PromptSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scene \(segment.index)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(segment.duration)s")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.purple)
            }
            
            Text(segment.content)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            
            if let tags = segment.cinematicTags {
                HStack(spacing: 8) {
                    Tag(text: tags.shotType, icon: "camera")
                    Tag(text: tags.lighting, icon: "light.max")
                    Tag(text: tags.emotionalTone, icon: "sparkles")
                }
            }
            
            // Coming Soon: Video Generation
            Button(action: {}) {
                HStack {
                    Image(systemName: "play.circle")
                    Text("Generate Video")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .foregroundColor(.gray)
            }
            .disabled(true)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}
