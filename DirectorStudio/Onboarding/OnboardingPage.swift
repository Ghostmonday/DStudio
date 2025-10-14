import SwiftUI

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    var isLast = false
    var action: (() -> Void)?
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: isVisible)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: isVisible)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .opacity(0.85)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            if isLast {
                Button(action: { action?() }) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .shadow(color: Color.pink.opacity(0.4), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isVisible = true
        }
    }
}
