import XCTest
import Combine
@testable import AIChatBot

final class IntegrationTests: XCTestCase {
    var aiService: AIService!
    var voiceManager: VoiceManager!
    var carPlayManager: CarPlayManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        aiService = AIService()
        voiceManager = VoiceManager()
        carPlayManager = CarPlayManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        aiService = nil
        voiceManager = nil
        carPlayManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - AI Service Integration Tests
    
    func testAIServiceConfigIntegration() {
        // Test that AI service uses Config for sentence count
        let originalCount = Config.responseSentenceCount
        
        // Change sentence count
        Config.setResponseSentenceCount(3)
        
        // Verify the change is reflected
        XCTAssertEqual(Config.responseSentenceCount, 3, "Config should return updated sentence count")
        
        // Restore original value
        Config.setResponseSentenceCount(originalCount)
    }
    
    func testSentenceCountNotificationIntegration() {
        let expectation = XCTestExpectation(description: "AI service receives sentence count notification")
        
        // Listen for the notification that AIService should receive
        NotificationCenter.default.publisher(for: NSNotification.Name("SentenceCountChanged"))
            .sink { notification in
                if let count = notification.userInfo?["count"] as? Int {
                    XCTAssertEqual(count, 4, "Notification should contain the updated count")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Change the sentence count
        Config.setResponseSentenceCount(4)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Voice Manager Integration Tests
    
    func testVoiceManagerAIServiceIntegration() {
        // Test that voice manager and AI service can work together
        // This is a basic integration test to ensure they don't conflict
        
        XCTAssertNotNil(voiceManager, "VoiceManager should be available")
        XCTAssertNotNil(aiService, "AIService should be available")
        
        // Test that both can be initialized together
        XCTAssertNoThrow({
            _ = voiceManager.hasPermission
            _ = aiService.isProcessing
        }(), "Both services should work together without conflicts")
    }
    
    // MARK: - CarPlay Integration Tests
    
    func testCarPlayManagerSetup() {
        // Test that CarPlay manager can be set up without issues
        XCTAssertNoThrow(carPlayManager.setup(), "CarPlay setup should not crash")
    }
    
    func testCarPlayAIServiceIntegration() {
        // Test that CarPlay manager can work with AI service
        XCTAssertNotNil(carPlayManager, "CarPlay manager should be available")
        XCTAssertNotNil(aiService, "AI service should be available")
        
        // Test basic integration - they should not conflict
        XCTAssertNoThrow({
            carPlayManager.setup()
            _ = aiService.getRecentChats()
        }(), "CarPlay and AI service should work together")
    }
    
    // MARK: - Keychain Integration Tests
    
    func testKeychainConfigIntegration() {
        // Test that Config can work with KeychainManager (indirectly)
        XCTAssertNotNil(Config.perplexityBaseURL, "Config should have API URL")
        
        // Test that keychain operations don't interfere with config
        let testProvider = "integration_test"
        let testKey = "test_integration_key"
        
        let storeResult = KeychainManager.shared.storeAPIKey(testKey, for: testProvider)
        XCTAssertTrue(storeResult, "Keychain should work during integration test")
        
        // Config should still work
        let sentenceCount = Config.responseSentenceCount
        XCTAssertGreaterThan(sentenceCount, 0, "Config should still work after keychain operations")
        
        // Clean up
        _ = KeychainManager.shared.deleteAPIKey(for: testProvider)
    }
    
    // MARK: - End-to-End Workflow Tests
    
    func testCompleteWorkflow() {
        // Test a complete workflow that might happen in the app
        
        // 1. Start with fresh AI service
        aiService.startNewChat()
        XCTAssertEqual(aiService.chatHistory.count, 1, "Should have welcome message")
        
        // 2. Change settings
        Config.setResponseSentenceCount(2)
        XCTAssertEqual(Config.responseSentenceCount, 2, "Settings should update")
        
        // 3. Get recent chats
        let recentChats = aiService.getRecentChats()
        XCTAssertFalse(recentChats.isEmpty, "Should have recent chats")
        
        // 4. Test voice manager state
        XCTAssertFalse(voiceManager.isRecording, "Voice should not be recording")
        
        // 5. Test CarPlay setup
        XCTAssertNoThrow(carPlayManager.setup(), "CarPlay should set up successfully")
        
        // All components should work together without issues
        XCTAssertTrue(true, "Complete workflow should succeed")
    }
    
    // MARK: - Performance Integration Tests
    
    func testIntegratedSystemPerformance() {
        measure {
            // Test performance of the integrated system
            let service = AIService()
            let voice = VoiceManager()
            let carPlay = CarPlayManager.shared
            
            service.startNewChat()
            _ = service.getRecentChats()
            voice.requestPermissions()
            carPlay.setup()
            
            Config.setResponseSentenceCount(3)
            _ = Config.responseSentenceCount
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() {
        // Test that errors in one component don't crash others
        
        // Test invalid voice commands don't break AI service
        let invalidCommand = "invalid_command_xyz"
        XCTAssertNoThrow({
            _ = voiceManager.processVoiceCommand(invalidCommand)
            _ = aiService.isProcessing
        }(), "Invalid voice commands should not break AI service")
        
        // Test invalid config values don't break other services
        XCTAssertNoThrow({
            Config.setResponseSentenceCount(0)  // Invalid value
            _ = voiceManager.hasPermission
            carPlayManager.setup()
        }(), "Invalid config should not break other services")
        
        // Reset to valid value
        Config.setResponseSentenceCount(2)
    }
}

// MARK: - Mock Classes for Testing

class MockAIService: AIService {
    var mockIsProcessing = false
    var mockChatHistory: [ChatMessage] = []
    
    override var isProcessing: Bool {
        return mockIsProcessing
    }
    
    override var chatHistory: [ChatMessage] {
        return mockChatHistory
    }
    
    override func startNewChat() {
        mockChatHistory = [
            ChatMessage(content: "Mock welcome", isFromAI: true, timestamp: Date())
        ]
    }
}

class MockVoiceManager: VoiceManager {
    var mockHasPermission = true
    var mockIsRecording = false
    
    override var hasPermission: Bool {
        return mockHasPermission
    }
    
    override var isRecording: Bool {
        return mockIsRecording
    }
    
    override func requestPermissions() {
        mockHasPermission = true
    }
}

// MARK: - Mock Integration Tests

final class MockIntegrationTests: XCTestCase {
    
    func testMockServices() {
        let mockAI = MockAIService()
        let mockVoice = MockVoiceManager()
        
        XCTAssertFalse(mockAI.isProcessing, "Mock AI should not be processing")
        XCTAssertTrue(mockVoice.hasPermission, "Mock voice should have permission")
        
        mockAI.startNewChat()
        XCTAssertEqual(mockAI.chatHistory.count, 1, "Mock AI should have one message after new chat")
    }
}
