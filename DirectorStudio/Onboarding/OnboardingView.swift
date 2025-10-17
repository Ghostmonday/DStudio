import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @EnvironmentObject var appState: AppState
    @StateObject private var firstClipService = FirstClipGrantService()
    @State private var currentPage = 0
    @State private var showClaimSheet = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "film.stack",
                    title: "Welcome to DirectorStudio",
                    description: "Create professional screenplays and generate AI-powered video clips with continuity validation."
                )
                .tag(0)
                
                // Page 2: Features
                OnboardingPage(
                    icon: "brain.head.profile",
                    title: "AI-Powered Creation",
                    description: "Our AI analyzes your story structure, validates continuity, and generates stunning video clips using Sora AI."
                )
                .tag(1)
                
                // Page 3: Claim Clip
                ClaimClipPage(
                    hasClaimedFirstClip: firstClipService.hasClaimedFirstClip,
                    onClaim: { showClaimSheet = true },
                    onSkip: { hasSeenOnboarding = true }
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
        .sheet(isPresented: $showClaimSheet) {
            ClaimIncludedClipSheet()
        }
    }
}

// MARK: - Claim Clip Page
struct ClaimClipPage: View {
    let hasClaimedFirstClip: Bool
    let onClaim: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("Your Purchase Includes 1 Clip")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Sign in with Apple to claim your included clip credit and start creating amazing videos.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                if !hasClaimedFirstClip {
                    Button(action: onClaim) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign in with Apple")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Clip Already Claimed")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Button("Skip for now") {
                    onSkip()
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
    }
}
