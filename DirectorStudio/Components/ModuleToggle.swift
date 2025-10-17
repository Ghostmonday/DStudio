import SwiftUI

// MARK: - Module Toggle Component
struct ModuleToggle: View {
    let title: String
    let icon: String
    let description: String
    let tooltip: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon and Title
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isEnabled ? .purple : .gray)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(isEnabled ? .white : .gray)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Toggle Switch
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    .labelsHidden()
                    .accessibilityLabel("Toggle \(title)")
            }
            
            // Tooltip/Description
            if isEnabled {
                Text(tooltip)
                    .font(.caption2)
                    .foregroundColor(.purple.opacity(0.8))
                    .padding(.leading, 36) // Align with text content
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? Color.purple.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEnabled ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isEnabled ? [.isSelected] : [])
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        ModuleToggle(
            title: "Transform Your Words",
            icon: "wand.and.stars",
            description: "Modernize, refine grammar, or restyle your narrative",
            tooltip: "Uses AI to enhance your writing style and grammar",
            isEnabled: .constant(true)
        )
        
        ModuleToggle(
            title: "Cinematic Taxonomy",
            icon: "camera.aperture",
            description: "Add camera angles, lighting, and shot types",
            tooltip: "Analyzes scenes for optimal cinematography",
            isEnabled: .constant(false)
        )
        
        ModuleToggle(
            title: "Prompt Breakdown",
            icon: "rectangle.split.3x1",
            description: "Break story into AI-ready video prompts",
            tooltip: "Segments your story into 15-second video clips",
            isEnabled: .constant(true)
        )
    }
    .padding()
    .background(Color.black)
}
