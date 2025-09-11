# AIChatBot Unit Tests

Comprehensive unit tests for the AIChatBot application to prevent regressions and ensure code quality.

## 🧪 Test Files Overview

### Core Functionality Tests
- **`AIServiceTests.swift`** - Tests AI functionality, provider switching, chat history management, and citation cleanup
- **`ConfigTests.swift`** - Tests configuration management, settings persistence, and notification system
- **`KeychainManagerTests.swift`** - Tests secure API key storage and retrieval

### Platform Integration Tests
- **`CarPlayManagerTests.swift`** - Tests CarPlay integration, scene management, and template creation
- **`VoiceManagerTests.swift`** - Tests voice recognition, speech synthesis, and command processing

### System Integration Tests
- **`IntegrationTests.swift`** - Tests cross-component integration, end-to-end workflows, and error handling

## 🎯 Testing Coverage

### AI Service Testing
- ✅ Provider switching (Perplexity, Claude, GPT, Gemini)
- ✅ Chat history management
- ✅ Citation cleanup and response formatting
- ✅ Sentence count customization
- ✅ Processing state management
- ✅ Error handling

### Configuration Testing
- ✅ UserDefaults persistence
- ✅ Settings validation
- ✅ Notification broadcasting
- ✅ Performance optimization

### CarPlay Testing
- ✅ Scene delegate lifecycle
- ✅ Interface controller management
- ✅ Template creation
- ✅ Integration with voice and AI services

### Voice Management Testing
- ✅ Permission handling
- ✅ Recording state management
- ✅ Command processing
- ✅ Speech synthesis
- ✅ Edge case handling

### Security Testing
- ✅ Keychain storage and retrieval
- ✅ API key management
- ✅ Multiple provider support
- ✅ Data persistence

### Integration Testing
- ✅ Component interaction
- ✅ Notification system
- ✅ Error propagation
- ✅ Performance testing
- ✅ Mock object testing

## 🚀 Setup Instructions

### Method 1: Xcode GUI (Recommended)
1. Open `AIChatBot.xcodeproj` in Xcode
2. Go to **File → New → Target...**
3. Choose **Unit Testing Bundle** under **Test**
4. Name it `AIChatBotTests`
5. Set target to be tested as `AIChatBot`
6. Delete the default test file Xcode creates
7. Add all `.swift` files from `AIChatBotTests` folder to the target

### Method 2: Using Setup Script
```bash
./setup_tests.sh
```

## 🏃‍♂️ Running Tests

### In Xcode
- Press `Cmd+U` to run all tests
- Use the Test Navigator to run individual test files or methods

### Command Line
```bash
xcodebuild test -scheme AIChatBot -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Individual Test Classes
```bash
xcodebuild test -scheme AIChatBot -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:AIChatBotTests/AIServiceTests
```

## 📊 Test Statistics

- **Total Test Files:** 6
- **Total Test Methods:** ~60+
- **Coverage Areas:** 6 major components
- **Integration Tests:** Cross-component workflows
- **Performance Tests:** Included for all major components
- **Mock Tests:** For external dependencies

## 🛡️ Regression Protection

These tests protect against:
- ❌ Breaking changes to AI response formatting
- ❌ Settings not persisting correctly
- ❌ CarPlay integration failures
- ❌ Voice command processing errors
- ❌ Keychain security issues
- ❌ Component integration problems
- ❌ Performance degradation

## 📈 Continuous Integration

To integrate with CI/CD:
```bash
# Example GitHub Actions test command
xcodebuild test -scheme AIChatBot -destination 'platform=iOS Simulator,name=iPhone 16' -enableCodeCoverage YES
```

## 🔧 Maintenance

- **Update tests** when adding new features
- **Run tests** before committing changes
- **Review test failures** carefully - they often catch real bugs
- **Add performance tests** for new heavy operations

## 💡 Best Practices

1. **Test behavior, not implementation** - Focus on what the code should do
2. **Use descriptive test names** - Make failures easy to understand
3. **Test edge cases** - Empty strings, nil values, boundary conditions
4. **Mock external dependencies** - Keep tests fast and reliable
5. **Test error conditions** - Ensure graceful error handling

---

*Created to ensure the AIChatBot remains stable and bug-free as new features are added.*
