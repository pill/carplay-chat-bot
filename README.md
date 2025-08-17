# AI Chat Bot - Apple CarPlay App

A boilerplate Apple CarPlay application that provides AI chat functionality while driving.

## Features

- **CarPlay Integration**: Native CarPlay interface for safe in-car AI interactions
- **AI Chat**: Connect to various AI services (Claude, GPT, etc.)
- **Voice Commands**: Hands-free operation with Siri integration
- **Account Management**: Seamless login using phone app credentials
- **Chat Management**: Create new conversations and manage existing chats

## Commands

- Create a new chat
- Repeat the last answer
- Voice-to-text input
- Hands-free navigation

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Apple Developer Account with CarPlay entitlement
- iPhone with CarPlay support

## Installation

1. Clone this repository
2. Open `AIChatBot.xcodeproj` in Xcode
3. Configure your team and bundle identifier
4. Build and run on device (CarPlay requires physical device testing)

## CarPlay Entitlements

This app requires the following CarPlay entitlements:
- `com.apple.developer.carplay-charging`
- `com.apple.developer.carplay-communication`
- `com.apple.developer.carplay-entertainment`

## Architecture

- **CarPlay Integration**: Uses CarPlay framework for in-car interface
- **AI Service Layer**: Abstracted AI service integration
- **Voice Processing**: Speech recognition and synthesis
- **Data Persistence**: Core Data for chat history

## License

MIT License - see LICENSE file for details



