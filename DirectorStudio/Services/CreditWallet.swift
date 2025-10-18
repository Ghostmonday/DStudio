import Foundation
import SwiftUI

// MARK: - Credit Wallet Actor
@MainActor
class CreditWallet: ObservableObject {
    @Published var balance: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Updated pricing baseline: $0.08 per credit
    public static let costPerCredit = 0.08 // USD per credit
    
    private let ledgerAPI = LedgerAPI.shared
    private let keychain = KeychainService.shared
    
    init() {
        loadBalanceFromKeychain()
        // TEMPORARY: Set initial balance for testing
        if balance == 0 {
            balance = 5
            saveBalanceToKeychain(balance)
        }
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
        // TEMPORARY: Bypass credit check for testing
        print("🧪 TESTING MODE: Bypassing credit check")
        balance = max(balance, 1) // Ensure we have at least 1 credit
        balance -= amount
        saveBalanceToKeychain(balance)
        return balance
    }
    
    func addCredits(_ amount: Int) {
        balance += amount
        saveBalanceToKeychain(balance)
    }
    
    // MARK: - Pricing Calculations
    
    /// Calculate the cost in USD for a given number of credits
    func calculateCost(credits: Int) -> Double {
        return Double(credits) * Self.costPerCredit
    }
    
    /// Calculate how many credits are needed for a story based on character count
    /// Using the measurement-based approach: 1 credit = 1,000 characters
    func calculateCreditsForStory(characterCount: Int) -> Int {
        return Int(ceil(Double(characterCount) / 1000.0))
    }
    
    /// Calculate the total cost for processing a story
    func calculateStoryCost(characterCount: Int) -> Double {
        let credits = calculateCreditsForStory(characterCount: characterCount)
        return calculateCost(credits: credits)
    }
    
    /// Get pricing information for display
    func getPricingInfo() -> PricingInfo {
        return PricingInfo(
            costPerCredit: Self.costPerCredit,
            creditsPer1000Chars: 1,
            exampleCosts: [
                (chars: 500, cost: calculateStoryCost(characterCount: 500)),
                (chars: 2000, cost: calculateStoryCost(characterCount: 2000)),
                (chars: 5000, cost: calculateStoryCost(characterCount: 5000))
            ]
        )
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

// MARK: - Pricing Information
public struct PricingInfo: Sendable {
    public let costPerCredit: Double
    public let creditsPer1000Chars: Int
    public let exampleCosts: [(chars: Int, cost: Double)]
    
    public init(costPerCredit: Double, creditsPer1000Chars: Int, exampleCosts: [(chars: Int, cost: Double)]) {
        self.costPerCredit = costPerCredit
        self.creditsPer1000Chars = creditsPer1000Chars
        self.exampleCosts = exampleCosts
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
