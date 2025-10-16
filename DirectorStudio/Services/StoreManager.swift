import Foundation
import StoreKit
import SwiftUI

// MARK: - Store Manager
@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let ledgerAPI = LedgerAPI.shared
    
    // Product IDs
    private let productIDs = [
        "com.neuraldraft.directorstudio.credits_5",
        "com.neuraldraft.directorstudio.credits_20",
        "com.neuraldraft.directorstudio.credits_100"
    ]
    
    // Product to credit mapping
    private let productCredits: [String: Int] = [
        "com.neuraldraft.directorstudio.credits_5": 5,
        "com.neuraldraft.directorstudio.credits_20": 20,
        "com.neuraldraft.directorstudio.credits_100": 100
    ]
    
    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleSuccessfulPurchase(transaction)
                await updatePurchasedProducts()
                return true
                
            case .userCancelled:
                return false
                
            case .pending:
                errorMessage = "Purchase pending approval"
                return false
                
            @unknown default:
                errorMessage = "Unknown purchase result"
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            return true
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            return false
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        purchasedProducts = purchased
    }
    
    private func handleSuccessfulPurchase(_ transaction: Transaction) async {
        // Get credit amount for this product
        guard let creditAmount = productCredits[transaction.productID] else {
            print("Unknown product ID: \(transaction.productID)")
            return
        }
        
        // Send to backend for credit topup
        if let authToken = getAuthToken() {
            do {
                let response = try await ledgerAPI.topupCredits(
                    authToken: authToken,
                    productId: transaction.productID,
                    transactionId: String(transaction.id),
                    signedTransaction: "signed_transaction_data" // In real implementation, get from StoreKit
                )
                
                if response.success {
                    print("Successfully topped up \(creditAmount) credits. New balance: \(response.new_balance)")
                } else {
                    print("Failed to topup credits: \(response.error ?? "Unknown error")")
                }
            } catch {
                print("Error topping up credits: \(error)")
            }
        }
        
        // Finish the transaction
        await transaction.finish()
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
    
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    // MARK: - Helper Methods
    func getProduct(for id: String) -> Product? {
        return products.first { $0.id == id }
    }
    
    func getCreditAmount(for product: Product) -> Int {
        return productCredits[product.id] ?? 0
    }
    
    func isProductPurchased(_ product: Product) -> Bool {
        return purchasedProducts.contains(product.id)
    }
}

// MARK: - Error Types
enum StoreError: Error, LocalizedError {
    case unverifiedTransaction
    case productNotFound
    case purchaseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unverifiedTransaction:
            return "Transaction could not be verified"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        }
    }
}
