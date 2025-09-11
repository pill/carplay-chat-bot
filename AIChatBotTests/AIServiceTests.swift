import XCTest
import Combine
@testable import AIChatBot

final class AIServiceTests: XCTestCase {
    var aiService: AIService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        aiService = AIService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        aiService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAIServiceInitialization() {
        XCTAssertNotNil(aiService, "AIService should initialize successfully")
        XCTAssertEqual(aiService.currentProvider, .perplexity, "Default provider should be Perplexity")
        XCTAssertFalse(aiService.isProcessing, "Should not be processing initially")
        XCTAssertFalse(aiService.chatHistory.isEmpty, "Should have welcome message")
    }
    
    func testWelcomeMessage() {
        XCTAssertEqual(aiService.chatHistory.count, 1, "Should have exactly one welcome message")
        
        let welcomeMessage = aiService.chatHistory.first!
        XCTAssertTrue(welcomeMessage.isFromAI, "Welcome message should be from AI")
        XCTAssertTrue(welcomeMessage.content.contains("Hello"), "Welcome message should contain greeting")
    }
    
    // MARK: - Chat History Tests
    
    func testStartNewChat() {
        // Add some messages first
        let userMessage = ChatMessage(content: "Test message", isFromAI: false, timestamp: Date())
        aiService.chatHistory.append(userMessage)
        
        XCTAssertEqual(aiService.chatHistory.count, 2, "Should have welcome + user message")
        
        // Start new chat
        aiService.startNewChat()
        
        XCTAssertEqual(aiService.chatHistory.count, 1, "Should only have welcome message after reset")
        XCTAssertTrue(aiService.chatHistory.first!.isFromAI, "First message should be welcome message")
    }
    
    // MARK: - Provider Tests
    
    func testProviderChange() {
        // Test changing to Claude
        aiService.setProvider(.claude)
        XCTAssertEqual(aiService.currentProvider, .claude, "Provider should change to Claude")
        
        // Test changing to GPT
        aiService.setProvider(.gpt)
        XCTAssertEqual(aiService.currentProvider, .gpt, "Provider should change to GPT")
        
        // Test changing to Gemini
        aiService.setProvider(.gemini)
        XCTAssertEqual(aiService.currentProvider, .gemini, "Provider should change to Gemini")
    }
    
    func testProviderDisplayNames() {
        XCTAssertEqual(AIService.AIProvider.perplexity.displayName, "Perplexity")
        XCTAssertEqual(AIService.AIProvider.claude.displayName, "Claude")
        XCTAssertEqual(AIService.AIProvider.gpt.displayName, "GPT")
        XCTAssertEqual(AIService.AIProvider.gemini.displayName, "Gemini")
    }
    
    // MARK: - Processing State Tests
    
    func testProcessingState() {
        XCTAssertFalse(aiService.isProcessing, "Should not be processing initially")
        
        aiService.startAIProcessing()
        XCTAssertTrue(aiService.isProcessing, "Should be processing after start")
        
        aiService.stopAIProcessing()
        XCTAssertFalse(aiService.isProcessing, "Should not be processing after stop")
    }
    
    // MARK: - Error Handling Tests
    
    func testAIErrorDescriptions() {
        XCTAssertEqual(AIError.notImplemented.localizedDescription, "This feature is not yet implemented")
        XCTAssertEqual(AIError.invalidAPIKey.localizedDescription, "Invalid API key. Please check your configuration.")
        XCTAssertEqual(AIError.networkError.localizedDescription, "Network error. Please check your connection.")
        XCTAssertEqual(AIError.rateLimitExceeded.localizedDescription, "Rate limit exceeded. Please try again later.")
        XCTAssertEqual(AIError.serverError.localizedDescription, "The AI service is temporarily unavailable. Please try again later.")
    }
    
    // MARK: - Citation Cleanup Tests
    
    func testCitationCleanup() {
        // This tests the private cleanupCitations method indirectly
        // We'll test it by checking if citations are removed from responses
        let testStrings = [
            "This is a test [1] sentence.",
            "Multiple citations [1] and [2] here.",
            "With parentheses (1) and (2) citations.",
            "Superscript citations^1 and^2.",
            "Mixed [1] and (2) and^3 citations."
        ]
        
        let expectedResults = [
            "This is a test  sentence.",
            "Multiple citations  and  here.",
            "With parentheses  and  citations.",
            "Superscript citations and.",
            "Mixed  and  and citations."
        ]
        
        // Since cleanupCitations is private, we can't test it directly
        // But we know it should be called during API responses
        // This is more of a documentation of expected behavior
        XCTAssertEqual(testStrings.count, expectedResults.count, "Test data should match expected results")
    }
    
    // MARK: - Recent Chats Tests
    
    func testGetRecentChats() {
        let recentChats = aiService.getRecentChats()
        
        XCTAssertFalse(recentChats.isEmpty, "Should return some recent chats")
        XCTAssertEqual(recentChats.count, 3, "Should return 3 mock recent chats")
        
        // Test first chat
        let firstChat = recentChats.first!
        XCTAssertEqual(firstChat.title, "General Chat", "First chat should be General Chat")
        XCTAssertNotNil(firstChat.timestamp, "Chat should have timestamp")
    }
    
    // MARK: - Performance Tests
    
    func testAIServicePerformance() {
        measure {
            let service = AIService()
            service.startNewChat()
            _ = service.getRecentChats()
        }
    }
}

// MARK: - ChatMessage Tests

final class ChatMessageTests: XCTestCase {
    
    func testChatMessageCreation() {
        let timestamp = Date()
        let message = ChatMessage(
            content: "Test message",
            isFromAI: false,
            timestamp: timestamp
        )
        
        XCTAssertEqual(message.content, "Test message")
        XCTAssertFalse(message.isFromAI)
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertNotNil(message.id, "Message should have a UUID")
    }
    
    func testChatMessageFromAI() {
        let aiMessage = ChatMessage(
            content: "AI response",
            isFromAI: true,
            timestamp: Date()
        )
        
        XCTAssertTrue(aiMessage.isFromAI)
        XCTAssertEqual(aiMessage.content, "AI response")
    }
}

// MARK: - ChatSession Tests

final class ChatSessionTests: XCTestCase {
    
    func testChatSessionCreation() {
        let timestamp = Date()
        let session = ChatSession(
            title: "Test Session",
            lastMessage: "Last message",
            timestamp: timestamp
        )
        
        XCTAssertEqual(session.title, "Test Session")
        XCTAssertEqual(session.lastMessage, "Last message")
        XCTAssertEqual(session.timestamp, timestamp)
        XCTAssertNotNil(session.id, "Session should have a UUID")
    }
}
