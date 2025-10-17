import Foundation
import AuthenticationServices
import Security
import SwiftUI

// MARK: - Auth Service
@MainActor
class AuthService: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var authToken: String?
    @Published var errorMessage: String?
    
    private let service = "com.neuraldraft.directorstudio"
    private let account = "auth_token"
    private let nonceAccount = "siwa_nonce"
    
    override init() {
        super.init()
        loadStoredAuth()
    }
    
    // MARK: - Sign In with Apple
    func signInWithApple() {
        let nonce = generateNonce()
        storeNonce(nonce)
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func signOut() {
        isSignedIn = false
        userEmail = nil
        authToken = nil
        errorMessage = nil
        
        // Clear stored auth
        deleteStoredAuth()
    }
    
    // MARK: - Token Management
    func refreshTokenIfNeeded() async {
        guard let storedToken = authToken else { return }
        
        // Check if token is expired (simple check - in production, decode JWT)
        // For now, we'll refresh on every app launch
        if isTokenExpired(storedToken) {
            await refreshToken()
        }
    }
    
    private func refreshToken() async {
        // In a real implementation, this would call the backend to refresh the token
        // For now, we'll just reload from storage
        loadStoredAuth()
    }
    
    private func isTokenExpired(_ token: String) -> Bool {
        // Simple implementation - in production, decode JWT and check expiry
        // For now, assume tokens expire after 24 hours
        return false
    }
    
    // MARK: - Nonce Management
    private func generateNonce() -> String {
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        var result = ""
        var remainingLength = 32
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    let characterIndex = charset.index(charset.startIndex, offsetBy: Int(random))
                    result.append(charset[characterIndex])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func storeNonce(_ nonce: String) {
        let data = nonce.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: nonceAccount,
            kSecValueData as String: data
        ]
        
        // Delete existing nonce
        SecItemDelete(query as CFDictionary)
        
        // Store new nonce
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getStoredNonce() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: nonceAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let nonce = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return nonce
    }
    
    // MARK: - Auth Storage
    private func storeAuth(token: String, email: String?) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete existing auth
        SecItemDelete(query as CFDictionary)
        
        // Store new auth
        SecItemAdd(query as CFDictionary, nil)
        
        // Store email separately
        if let email = email {
            UserDefaults.standard.set(email, forKey: "user_email")
        }
    }
    
    private func loadStoredAuth() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            authToken = token
            isSignedIn = true
            userEmail = UserDefaults.standard.string(forKey: "user_email")
        }
    }
    
    private func deleteStoredAuth() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "user_email")
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid Apple ID credential"
            return
        }
        
        guard let nonce = getStoredNonce() else {
            errorMessage = "Invalid nonce"
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to fetch identity token"
            return
        }
        
        // Store the credential for later use
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        // In a real implementation, you would send this to your backend
        // For now, we'll simulate a successful auth
        let simulatedToken = "simulated_jwt_token_\(UUID().uuidString)"
        
        storeAuth(token: simulatedToken, email: email)
        authToken = simulatedToken
        userEmail = email
        isSignedIn = true
        errorMessage = nil
        
        // Clear the nonce after use
        let nonceQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: nonceAccount
        ]
        SecItemDelete(nonceQuery as CFDictionary)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
