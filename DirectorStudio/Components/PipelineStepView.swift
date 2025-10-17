import SwiftUI

struct PipelineStepView: View {
    let number: Int
    let title: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : isActive ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else if isActive {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Text("\(number)")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(isActive || isComplete ? .primary : .secondary)
            
            Spacer()
        }
    }
}
