import Foundation
import Security

// MARK: - API Key Manager
class APIKeyManager {
    static let shared = APIKeyManager()
    
    private let service = "com.neuraldraft.directorstudio"
    private let account = "pollo_api_key"
    
    private init() {}
    
    // MARK: - Keychain Operations
    func saveAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods
    func hasAPIKey() -> Bool {
        return loadAPIKey() != nil
    }
    
    func getAPIKey() -> String {
        #if DEBUG
        // Debug fallback to environment variable
        if let envKey = ProcessInfo.processInfo.environment["POLLO_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        #endif
        
        return loadAPIKey() ?? ""
    }
    
    func isValidAPIKey(_ key: String) -> Bool {
        // Basic validation - should be non-empty and look like an API key
        return !key.isEmpty && key.count > 10
    }
}
