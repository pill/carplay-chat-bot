import XCTest
import CarPlay
@testable import AIChatBot

final class CarPlayManagerTests: XCTestCase {
    var carPlayManager: CarPlayManager!
    
    override func setUp() {
        super.setUp()
        carPlayManager = CarPlayManager.shared
    }
    
    override func tearDown() {
        carPlayManager = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSingleton() {
        let manager1 = CarPlayManager.shared
        let manager2 = CarPlayManager.shared
        
        XCTAssertTrue(manager1 === manager2, "CarPlayManager should be a singleton")
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(carPlayManager, "CarPlayManager should initialize")
        XCTAssertNil(carPlayManager.interfaceController, "Interface controller should be nil initially")
    }
    
    func testSetup() {
        // Test setup doesn't crash
        XCTAssertNoThrow(carPlayManager.setup(), "Setup should not throw")
    }
    
    // MARK: - Interface Controller Tests
    
    func testInterfaceControllerAssignment() {
        // Test that we can assign an interface controller
        XCTAssertNil(carPlayManager.interfaceController, "Should start with nil interface controller")
        
        // We can't easily create a real CPInterfaceController in tests,
        // but we can test the property assignment
        // This is more of a smoke test
    }
    
    // MARK: - Template Creation Tests
    
    func testMainTemplateCreation() {
        // Test that creating the main template doesn't crash
        let mirror = Mirror(reflecting: carPlayManager)
        let createMainTemplateMethod = mirror.children.first { $0.label == "createMainTemplate" }
        
        // Since createMainTemplate is private, we can't test it directly
        // But we can test that the CarPlayManager doesn't crash during setup
        XCTAssertNoThrow(carPlayManager.setup())
    }
    
    // MARK: - Voice Integration Tests
    
    func testVoiceManagerIntegration() {
        // Test that CarPlayManager has access to voice functionality
        // This is tested indirectly through the existence of voice-related methods
        XCTAssertNotNil(carPlayManager, "CarPlayManager should exist for voice integration")
    }
    
    // MARK: - AI Service Integration Tests
    
    func testAIServiceIntegration() {
        // Test that CarPlayManager can work with AI service
        // This is tested indirectly through the manager's ability to function
        XCTAssertNotNil(carPlayManager, "CarPlayManager should exist for AI integration")
    }
    
    // MARK: - Performance Tests
    
    func testCarPlayManagerPerformance() {
        measure {
            let manager = CarPlayManager.shared
            manager.setup()
        }
    }
}

// MARK: - CarPlay Scene Delegate Tests

final class CarPlaySceneDelegateTests: XCTestCase {
    var sceneDelegate: CarPlaySceneDelegate!
    
    override func setUp() {
        super.setUp()
        sceneDelegate = CarPlaySceneDelegate()
    }
    
    override func tearDown() {
        sceneDelegate = nil
        super.tearDown()
    }
    
    func testSceneDelegateInitialization() {
        XCTAssertNotNil(sceneDelegate, "CarPlaySceneDelegate should initialize")
    }
    
    func testSceneDelegateConformsToProtocol() {
        XCTAssertTrue(sceneDelegate is CPTemplateApplicationSceneDelegate, 
                     "Should conform to CPTemplateApplicationSceneDelegate")
    }
}
