import SwiftUI
import StoreKit

// MARK: - Paywall Sheet
struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager()
    @StateObject private var creditWallet = CreditWallet()
    @State private var selectedProduct: Product?
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        
                        Text("Get More Credits")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Generate amazing videos with Sora AI")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Current Balance
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("\(creditWallet.balance) credits")
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Pricing Information
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                            Text("Pricing: $0.08 per credit")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        Text("1 credit = 1,000 characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example usage:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("500 chars")
                                Spacer()
                                Text("1 credit = $0.08")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("2,000 chars")
                                Spacer()
                                Text("2 credits = $0.16")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("5,000 chars")
                                Spacer()
                                Text("5 credits = $0.40")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Products
                    VStack(spacing: 16) {
                        ForEach(storeManager.products, id: \.id) { product in
                            ProductCard(
                                product: product,
                                creditAmount: storeManager.getCreditAmount(for: product),
                                isRecommended: product.id == "com.neuraldraft.directorstudio.credits_20",
                                isLoading: storeManager.isLoading,
                                onPurchase: {
                                    selectedProduct = product
                                    Task {
                                        let success = await storeManager.purchase(product)
                                        if success {
                                            await creditWallet.refresh()
                                            dismiss()
                                        }
                                    }
                                }
                            )
                        }
                    }
                    
                    // Restore Purchases
                    Button("Restore Purchases") {
                        Task {
                            let success = await storeManager.restorePurchases()
                            restoreMessage = success ? "Purchases restored successfully" : "No purchases to restore"
                            showingRestoreAlert = true
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.top)
                    
                    // Footer
                    Text("Credits never expire. Purchase once, use forever.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
                Button("OK") { }
            } message: {
                Text(restoreMessage)
            }
            .alert("Purchase Error", isPresented: .constant(storeManager.errorMessage != nil)) {
                Button("OK") {
                    storeManager.errorMessage = nil
                }
            } message: {
                Text(storeManager.errorMessage ?? "")
            }
        }
        .task {
            await storeManager.loadProducts()
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let creditAmount: Int
    let isRecommended: Bool
    let isLoading: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(creditAmount) Credits")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isRecommended {
                            Text("BEST VALUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(product.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if creditAmount > 1 {
                        Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: product.price).doubleValue / Double(creditAmount)))/credit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: onPurchase) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text("Purchase")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRecommended ? Color.blue : Color(.systemGray5))
                .foregroundColor(isRecommended ? .white : .primary)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRecommended ? Color.blue : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    PaywallSheet()
}
