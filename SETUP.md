# AI Chat Bot CarPlay App - Setup Guide

## Prerequisites

- macOS with Xcode 15.0 or later
- iOS 14.0+ deployment target
- Apple Developer Account with CarPlay entitlement
- iPhone with CarPlay support for testing
- CarPlay-compatible vehicle or simulator

## Installation Steps

### 1. Clone and Open Project

```bash
git clone <your-repo-url>
cd ai-bot
open AIChatBot.xcodeproj
```

### 2. Configure Project Settings

1. **Select Target**: Choose "AIChatBot" target
2. **Bundle Identifier**: Change to your unique identifier (e.g., `com.yourcompany.AIChatBot`)
3. **Team**: Select your development team
4. **Deployment Target**: Ensure iOS 14.0+ is selected

### 3. Configure CarPlay Entitlements

1. **Apple Developer Portal**:
   - Log into [developer.apple.com](https://developer.apple.com)
   - Navigate to Certificates, Identifiers & Profiles
   - Select your App ID
   - Enable CarPlay capability
   - Select appropriate CarPlay categories:
     - Entertainment
     - Communication
     - Information
     - Navigation (if needed)

2. **Xcode Project**:
   - Select your target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "CarPlay" capability
   - Select the same categories as in Developer Portal

### 4. Configure Info.plist

The project includes necessary permissions:
- Microphone access for voice input
- Speech recognition for voice-to-text
- Location access for CarPlay functionality

### 5. Build and Test

1. **Device Testing** (Required for CarPlay):
   - Connect iPhone to Mac
   - Select your device as target
   - Build and run (⌘+R)

2. **CarPlay Testing**:
   - Connect iPhone to CarPlay-compatible vehicle
   - Or use CarPlay simulator in Xcode
   - App should appear in CarPlay interface

## Project Structure

```
AIChatBot/
├── AIChatBotApp.swift          # Main app entry point
├── ContentView.swift           # SwiftUI main interface
├── CarPlayManager.swift        # CarPlay integration logic
├── AIService.swift            # AI service abstraction
├── VoiceManager.swift         # Speech recognition & synthesis
├── ChatViewController.swift   # UIKit chat interface
├── Info.plist                # App configuration
├── AIChatBot.entitlements    # CarPlay permissions
└── Assets.xcassets/          # App icons and resources
```

## Key Features

### CarPlay Integration
- **Main Menu**: New Chat, Recent Chats, Voice Chat, Settings
- **Chat Interface**: Voice input, text input, message history
- **Voice Commands**: Hands-free operation with Siri integration

### AI Service Layer
- **Provider Support**: Claude, GPT, Gemini (configurable)
- **Mock Responses**: Built-in for testing without API keys
- **Real API Integration**: Ready for production deployment

### Voice Management
- **Speech Recognition**: Convert voice to text
- **Text-to-Speech**: Read AI responses aloud
- **Voice Commands**: Control app with voice

## Configuration

### AI Service Setup

1. **API Keys**: Add your API keys in `AIService.swift`
2. **Provider Selection**: Choose default AI provider
3. **Custom Responses**: Modify mock response logic

### Voice Settings

1. **Speech Recognition**: Configure language and accuracy
2. **Text-to-Speech**: Adjust voice, speed, and pitch
3. **Voice Commands**: Customize command vocabulary

## Testing

### CarPlay Simulator
1. Open Xcode
2. Window → CarPlay Simulator
3. Test app interface and navigation

### Device Testing
1. Connect iPhone to vehicle
2. Launch app on phone
3. Verify CarPlay integration

## Troubleshooting

### Common Issues

1. **CarPlay Not Appearing**:
   - Check entitlements configuration
   - Verify Developer Portal settings
   - Ensure proper bundle identifier

2. **Voice Recognition Issues**:
   - Check microphone permissions
   - Verify speech recognition entitlement
   - Test on physical device

3. **Build Errors**:
   - Clean build folder (⇧⌘K)
   - Check deployment target compatibility
   - Verify Swift version compatibility

### Debug Tips

- Use Xcode console for logging
- Test voice features on device (not simulator)
- Verify CarPlay connection status
- Check permission requests

## Deployment

### App Store Submission

1. **Archive Project**: Product → Archive
2. **Upload to App Store Connect**
3. **Configure CarPlay Categories** in App Store Connect
4. **Submit for Review**

### Enterprise Distribution

1. **Export IPA** with appropriate provisioning
2. **Distribute via MDM** or enterprise channels
3. **Configure CarPlay policies** if needed

## Support

For additional help:
- [Apple CarPlay Developer Documentation](https://developer.apple.com/carplay/)
- [CarPlay Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/carplay)
- [iOS Speech Framework](https://developer.apple.com/documentation/speech)

## License

This project is provided as-is for educational and development purposes. Ensure compliance with Apple's App Store guidelines and CarPlay requirements. 