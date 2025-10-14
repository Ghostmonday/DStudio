import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .purple.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "film.stack.fill",
                    title: "Welcome to DirectorStudio",
                    description: "Transform your stories into cinematic video prompts with AI"
                ).tag(0)
                
                OnboardingPage(
                    icon: "wand.and.stars",
                    title: "Intelligent Rewording",
                    description: "Modernize language, improve grammar, and restyle your narrative"
                ).tag(1)
                
                OnboardingPage(
                    icon: "camera.aperture",
                    title: "Cinematic Taxonomy",
                    description: "Automatically add camera angles, lighting, and shot types"
                ).tag(2)
                
                OnboardingPage(
                    icon: "rectangle.split.3x1",
                    title: "Smart Segmentation",
                    description: "Break your story into AI-ready video prompts",
                    isLast: true,
                    action: { hasSeenOnboarding = true }
                ).tag(3)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            #endif
        }
    }
}
