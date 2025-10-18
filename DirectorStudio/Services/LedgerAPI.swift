import Foundation

// MARK: - Ledger API Client
class LedgerAPI {
    static let shared = LedgerAPI()
    
    private let baseURL = "https://carkncjucvtbggqrilwj.supabase.co/functions/v1"
    
    private init() {}
    
    // MARK: - Claim First Clip
    func claimFirstClip(siwaToken: String, deviceId: String) async throws -> ClaimResponse {
        let url = URL(string: "\(baseURL)/claim-first-clip")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ClaimRequest(
            siwa_id_token: siwaToken,
            device_install_id: deviceId,
            app_build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0",
            bundle_id: Bundle.main.bundleIdentifier ?? "com.neuraldraft.directorstudio"
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LedgerAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LedgerAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        return try JSONDecoder().decode(ClaimResponse.self, from: data)
    }
    
    // MARK: - Consume Credit
    func consumeCredit(authToken: String, amount: Int = 1) async throws -> ConsumeResponse {
        let url = URL(string: "\(baseURL)/consume-credit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ConsumeRequest(auth_token: authToken, amount: amount)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LedgerAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LedgerAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        return try JSONDecoder().decode(ConsumeResponse.self, from: data)
    }
    
    // MARK: - Topup Credits
    func topupCredits(authToken: String, productId: String, transactionId: String, signedTransaction: String) async throws -> TopupResponse {
        let url = URL(string: "\(baseURL)/credit-topup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = TopupRequest(
            auth_token: authToken,
            product_id: productId,
            transaction_id: transactionId,
            signed_transaction: signedTransaction
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LedgerAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LedgerAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        return try JSONDecoder().decode(TopupResponse.self, from: data)
    }
}

// MARK: - Request Models
struct ClaimRequest: Codable {
    let siwa_id_token: String
    let device_install_id: String
    let app_build: String
    let bundle_id: String
}

struct ConsumeRequest: Codable {
    let auth_token: String
    let amount: Int
}

struct TopupRequest: Codable {
    let auth_token: String
    let product_id: String
    let transaction_id: String
    let signed_transaction: String
}

// MARK: - Response Models
struct ClaimResponse: Codable {
    let granted: Bool
    let credits_delta: Int
    let auth_token: String?
    let error: String?
}

struct ConsumeResponse: Codable {
    let success: Bool
    let remaining: Int
    let error: String?
}

struct TopupResponse: Codable {
    let success: Bool
    let new_balance: Int
    let error: String?
}

// MARK: - Error Types
enum LedgerAPIError: Error, LocalizedError {
    case invalidResponse
    case serverError(Int, String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
