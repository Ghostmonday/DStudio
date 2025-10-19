//
//  CreditsPurchaseManager.swift
//  DirectorStudio
//
//  StoreKit 2 In-App Purchase Manager
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
public class CreditsPurchaseManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var products: [Product] = []
    @Published public var purchasedProductIDs: Set<String> = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // MARK: - Private State
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    public init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Management
    
    @MainActor
    public func requestProducts() async {
        do {
            let productIdentifiers = [
                "com.directorstudio.credits.100",
                "com.directorstudio.credits.500", 
                "com.directorstudio.credits.1000"
            ]
            
            products = try await Product.products(for: productIdentifiers)
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Purchase Management
    
    public func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        default:
            return nil
        }
    }
    
    public func restorePurchases() async throws {
        try await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func updateCustomerProductStatus() async {
        var purchasedProductIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchasedProductIDs
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Store Error

public enum StoreError: Error, LocalizedError {
    case failedVerification
    
    public var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
