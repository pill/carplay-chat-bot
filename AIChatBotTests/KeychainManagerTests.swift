import XCTest
@testable import AIChatBot

final class KeychainManagerTests: XCTestCase {
    let testProvider = "test_provider"
    let testAPIKey = "test_api_key_12345"
    
    override func setUp() {
        super.setUp()
        // Clean up any existing test data
        _ = KeychainManager.shared.deleteAPIKey(for: testProvider)
    }
    
    override func tearDown() {
        // Clean up test data
        _ = KeychainManager.shared.deleteAPIKey(for: testProvider)
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSingleton() {
        let manager1 = KeychainManager.shared
        let manager2 = KeychainManager.shared
        
        XCTAssertTrue(manager1 === manager2, "KeychainManager should be a singleton")
    }
    
    // MARK: - Store and Retrieve Tests
    
    func testStoreAndRetrieveAPIKey() {
        // Test storing an API key
        let storeResult = KeychainManager.shared.storeAPIKey(testAPIKey, for: testProvider)
        XCTAssertTrue(storeResult, "Storing API key should succeed")
        
        // Test retrieving the API key
        let retrievedKey = KeychainManager.shared.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, testAPIKey, "Retrieved API key should match stored key")
    }
    
    func testStoreEmptyAPIKey() {
        // Test storing an empty API key
        let storeResult = KeychainManager.shared.storeAPIKey("", for: testProvider)
        XCTAssertTrue(storeResult, "Storing empty API key should still succeed")
        
        let retrievedKey = KeychainManager.shared.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, "", "Retrieved key should be empty string")
    }
    
    func testUpdateAPIKey() {
        let firstKey = "first_api_key"
        let secondKey = "second_api_key"
        
        // Store first key
        let firstStoreResult = KeychainManager.shared.storeAPIKey(firstKey, for: testProvider)
        XCTAssertTrue(firstStoreResult, "Storing first API key should succeed")
        
        // Update with second key
        let secondStoreResult = KeychainManager.shared.storeAPIKey(secondKey, for: testProvider)
        XCTAssertTrue(secondStoreResult, "Updating API key should succeed")
        
        // Verify the key was updated
        let retrievedKey = KeychainManager.shared.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, secondKey, "Retrieved key should be the updated key")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteAPIKey() {
        // Store a key first
        let storeResult = KeychainManager.shared.storeAPIKey(testAPIKey, for: testProvider)
        XCTAssertTrue(storeResult, "Storing API key should succeed")
        
        // Verify it exists
        XCTAssertNotNil(KeychainManager.shared.getAPIKey(for: testProvider), 
                       "API key should exist before deletion")
        
        // Delete the key
        let deleteResult = KeychainManager.shared.deleteAPIKey(for: testProvider)
        XCTAssertTrue(deleteResult, "Deleting API key should succeed")
        
        // Verify it's gone
        XCTAssertNil(KeychainManager.shared.getAPIKey(for: testProvider), 
                    "API key should not exist after deletion")
    }
    
    func testDeleteNonExistentAPIKey() {
        // Try to delete a key that doesn't exist
        let deleteResult = KeychainManager.shared.deleteAPIKey(for: "non_existent_provider")
        XCTAssertTrue(deleteResult, "Deleting non-existent key should still return true")
    }
    
    // MARK: - Check Existence Tests
    
    func testHasAPIKey() {
        // Initially should not have the key
        XCTAssertFalse(KeychainManager.shared.hasAPIKey(for: testProvider), 
                      "Should not have API key initially")
        
        // Store a key
        let storeResult = KeychainManager.shared.storeAPIKey(testAPIKey, for: testProvider)
        XCTAssertTrue(storeResult, "Storing API key should succeed")
        
        // Now should have the key
        XCTAssertTrue(KeychainManager.shared.hasAPIKey(for: testProvider), 
                     "Should have API key after storing")
        
        // Delete the key
        let deleteResult = KeychainManager.shared.deleteAPIKey(for: testProvider)
        XCTAssertTrue(deleteResult, "Deleting API key should succeed")
        
        // Should not have the key anymore
        XCTAssertFalse(KeychainManager.shared.hasAPIKey(for: testProvider), 
                      "Should not have API key after deletion")
    }
    
    // MARK: - Provider Constants Tests
    
    func testProviderConstants() {
        XCTAssertEqual(KeychainManager.Provider.perplexity, "perplexity")
        XCTAssertEqual(KeychainManager.Provider.claude, "claude")
        XCTAssertEqual(KeychainManager.Provider.gpt, "gpt")
        XCTAssertEqual(KeychainManager.Provider.gemini, "gemini")
    }
    
    // MARK: - Multiple Providers Tests
    
    func testMultipleProviders() {
        let providers = [
            KeychainManager.Provider.perplexity,
            KeychainManager.Provider.claude,
            KeychainManager.Provider.gpt,
            KeychainManager.Provider.gemini
        ]
        
        let keys = [
            "perplexity_key_123",
            "claude_key_456", 
            "gpt_key_789",
            "gemini_key_abc"
        ]
        
        // Store keys for all providers
        for (provider, key) in zip(providers, keys) {
            let storeResult = KeychainManager.shared.storeAPIKey(key, for: provider)
            XCTAssertTrue(storeResult, "Storing key for \(provider) should succeed")
        }
        
        // Verify all keys can be retrieved
        for (provider, expectedKey) in zip(providers, keys) {
            let retrievedKey = KeychainManager.shared.getAPIKey(for: provider)
            XCTAssertEqual(retrievedKey, expectedKey, 
                          "Retrieved key for \(provider) should match stored key")
        }
        
        // Clean up
        for provider in providers {
            _ = KeychainManager.shared.deleteAPIKey(for: provider)
        }
    }
    
    // MARK: - Performance Tests
    
    func testKeychainPerformance() {
        measure {
            for i in 0..<10 {
                let provider = "test_provider_\(i)"
                let key = "test_key_\(i)"
                
                _ = KeychainManager.shared.storeAPIKey(key, for: provider)
                _ = KeychainManager.shared.getAPIKey(for: provider)
                _ = KeychainManager.shared.hasAPIKey(for: provider)
                _ = KeychainManager.shared.deleteAPIKey(for: provider)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testLongAPIKey() {
        // Test with a very long API key
        let longKey = String(repeating: "a", count: 1000)
        
        let storeResult = KeychainManager.shared.storeAPIKey(longKey, for: testProvider)
        XCTAssertTrue(storeResult, "Storing long API key should succeed")
        
        let retrievedKey = KeychainManager.shared.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, longKey, "Retrieved long key should match stored key")
    }
    
    func testSpecialCharactersInAPIKey() {
        // Test with special characters
        let specialKey = "key-with_special.chars+symbols!@#$%^&*()"
        
        let storeResult = KeychainManager.shared.storeAPIKey(specialKey, for: testProvider)
        XCTAssertTrue(storeResult, "Storing key with special characters should succeed")
        
        let retrievedKey = KeychainManager.shared.getAPIKey(for: testProvider)
        XCTAssertEqual(retrievedKey, specialKey, "Retrieved special key should match stored key")
    }
}
