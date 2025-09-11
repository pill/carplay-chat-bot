import XCTest
@testable import AIChatBot

final class ConfigTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean up UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "response_sentence_count")
    }
    
    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "response_sentence_count")
        super.tearDown()
    }
    
    // MARK: - Response Sentence Count Tests
    
    func testDefaultSentenceCount() {
        // Test default value when nothing is stored
        let defaultCount = Config.responseSentenceCount
        XCTAssertEqual(defaultCount, 2, "Default sentence count should be 2")
    }
    
    func testSetSentenceCount() {
        // Test setting a valid sentence count
        Config.setResponseSentenceCount(3)
        XCTAssertEqual(Config.responseSentenceCount, 3, "Sentence count should be updated to 3")
        
        // Test setting different values
        Config.setResponseSentenceCount(1)
        XCTAssertEqual(Config.responseSentenceCount, 1, "Sentence count should be updated to 1")
        
        Config.setResponseSentenceCount(5)
        XCTAssertEqual(Config.responseSentenceCount, 5, "Sentence count should be updated to 5")
    }
    
    func testSentenceCountPersistence() {
        // Set a value
        Config.setResponseSentenceCount(4)
        
        // Verify it persists by reading directly from UserDefaults
        let storedValue = UserDefaults.standard.integer(forKey: "response_sentence_count")
        XCTAssertEqual(storedValue, 4, "Value should be persisted in UserDefaults")
        
        // Verify it's returned correctly
        XCTAssertEqual(Config.responseSentenceCount, 4, "Config should return persisted value")
    }
    
    func testInvalidSentenceCountHandling() {
        // Test zero value (should return default)
        UserDefaults.standard.set(0, forKey: "response_sentence_count")
        XCTAssertEqual(Config.responseSentenceCount, 2, "Zero value should return default of 2")
        
        // Test negative value (should return default)
        UserDefaults.standard.set(-1, forKey: "response_sentence_count")
        XCTAssertEqual(Config.responseSentenceCount, 2, "Negative value should return default of 2")
    }
    
    // MARK: - API Configuration Tests
    
    func testPerplexityBaseURL() {
        XCTAssertEqual(Config.perplexityBaseURL, "https://api.perplexity.ai", "Perplexity base URL should be correct")
    }
    
    // MARK: - Performance Tests
    
    func testConfigPerformance() {
        measure {
            for i in 1...100 {
                Config.setResponseSentenceCount(i % 5 + 1)
                _ = Config.responseSentenceCount
            }
        }
    }
    
    // MARK: - Notification Tests
    
    func testSentenceCountChangeNotification() {
        let expectation = XCTestExpectation(description: "Sentence count change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SentenceCountChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let count = notification.userInfo?["count"] as? Int {
                XCTAssertEqual(count, 3, "Notification should contain the new count")
                expectation.fulfill()
            }
        }
        
        Config.setResponseSentenceCount(3)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
