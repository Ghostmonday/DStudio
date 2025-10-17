import Foundation
import SwiftUI

// MARK: - Credit Wallet Actor
@MainActor
class CreditWallet: ObservableObject {
    @Published var balance: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let ledgerAPI = LedgerAPI.shared
    private let keychain = KeychainService.shared
    
    init() {
        loadBalanceFromKeychain()
    }
    
    // MARK: - Balance Management
    func refresh() async {
        guard let authToken = getAuthToken() else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // For now, we'll simulate a balance check
            // In a real implementation, you'd call a backend endpoint to get current balance
            let simulatedBalance = UserDefaults.standard.integer(forKey: "credit_balance")
            balance = simulatedBalance
            saveBalanceToKeychain(simulatedBalance)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func consume(amount: Int) async throws -> Int {
        guard let authToken = getAuthToken() else {
            throw CreditWalletError.notAuthenticated
        }
        
        guard balance >= amount else {
            throw CreditWalletError.insufficientCredits
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let response = try await ledgerAPI.consumeCredit(authToken: authToken, amount: amount)
            
            if response.success {
                balance = response.remaining
                saveBalanceToKeychain(response.remaining)
                return response.remaining
            } else {
                throw CreditWalletError.consumeFailed(response.error ?? "Unknown error")
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func addCredits(_ amount: Int) {
        balance += amount
        saveBalanceToKeychain(balance)
    }
    
    // MARK: - Keychain Operations
    private func loadBalanceFromKeychain() {
        if let storedBalance = UserDefaults.standard.object(forKey: "credit_balance") as? Int {
            balance = storedBalance
        }
    }
    
    private func saveBalanceToKeychain(_ balance: Int) {
        UserDefaults.standard.set(balance, forKey: "credit_balance")
    }
    
    private func getAuthToken() -> String? {
        // In a real implementation, this would get the token from AuthService
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

// MARK: - Error Types
enum CreditWalletError: Error, LocalizedError {
    case notAuthenticated
    case insufficientCredits
    case consumeFailed(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .insufficientCredits:
            return "Insufficient credits"
        case .consumeFailed(let message):
            return "Failed to consume credits: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
