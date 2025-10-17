import SwiftUI

// MARK: - Individual Step View for Create Tab
struct IndividualStepView: View {
    let stepNumber: Int
    let title: String
    let icon: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step Header
            HStack(spacing: 12) {
                // Step Number Badge
                ZStack {
                    Circle()
                        .fill(isEnabled ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isEnabled ? .purple : .gray)
                }
                
                // Step Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Step \(stepNumber): \(title)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Enable/Disable Toggle
                        Toggle("", isOn: $isEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                            .scaleEffect(0.8)
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isEnabled ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
    }
}
