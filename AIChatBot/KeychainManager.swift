import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    private let service = "com.phlave.AIChatBot"
    
    // MARK: - Store API Key
    func storeAPIKey(_ apiKey: String, for provider: String) -> Bool {
        let account = "\(provider)_api_key"
        let data = apiKey.data(using: .utf8)!
        
        // Delete any existing item first
        _ = deleteAPIKey(for: provider)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve API Key
    func getAPIKey(for provider: String) -> String? {
        let account = "\(provider)_api_key"
        
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
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    // MARK: - Delete API Key
    func deleteAPIKey(for provider: String) -> Bool {
        let account = "\(provider)_api_key"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Check if API Key Exists
    func hasAPIKey(for provider: String) -> Bool {
        return getAPIKey(for: provider) != nil
    }
}

// MARK: - Provider Constants
extension KeychainManager {
    struct Provider {
        static let perplexity = "perplexity"
        static let claude = "claude"
        static let gpt = "gpt"
        static let gemini = "gemini"
    }
}