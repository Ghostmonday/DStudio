import SwiftUI
import AuthenticationServices

// MARK: - Claim Included Clip Sheet
public struct ClaimIncludedClipSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService()
    @StateObject private var firstClipService = FirstClipGrantService()
    @StateObject private var creditWallet = CreditWallet()
    @State private var showingSuccessAlert = false
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Your Purchase Includes 1 Clip")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Sign in with Apple to claim your included clip credit and start creating amazing videos.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Sign In with Apple Button
                VStack(spacing: 16) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if firstClipService.isClaiming {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Claiming your clip...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = firstClipService.claimError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Skip Option
                Button("Skip for now") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Claim Your Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clip Claimed!", isPresented: $showingSuccessAlert) {
                Button("Start Creating") {
                    dismiss()
                }
            } message: {
                Text("Your included clip has been added to your account. You now have \(creditWallet.balance) credits!")
            }
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                firstClipService.claimError = "Failed to get Apple ID token"
                return
            }
            
            Task {
                let success = await firstClipService.claimIfEligible(siwaToken: idTokenString)
                if success {
                    await creditWallet.refresh()
                    showingSuccessAlert = true
                }
            }
            
        case .failure(let error):
            firstClipService.claimError = error.localizedDescription
        }
    }
}

#Preview {
    ClaimIncludedClipSheet()
}
