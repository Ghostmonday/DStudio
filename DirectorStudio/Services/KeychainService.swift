import Foundation
import Security

// MARK: - Keychain Service for Secure API Key Storage
class KeychainService {
    static let shared = KeychainService()
    
    private static let service = "com.directorstudio.app"
    private static let apiKeyAccount = "deepseek_api_key"
    
    private init() {}
    
    // MARK: - Save API Key
    static func saveAPIKey(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Delete existing item first
        deleteAPIKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // MARK: - Retrieve API Key
    static func getAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return apiKey
    }
    
    // MARK: - Delete API Key
    static func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Check if API Key exists
    static func hasAPIKey() -> Bool {
        do {
            let apiKey = try getAPIKey()
            return apiKey != nil && !apiKey!.isEmpty
        } catch {
            return false
        }
    }
}

// MARK: - Keychain Errors
enum KeychainError: Error, LocalizedError {
    case invalidData
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        }
    }
}
