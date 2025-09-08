import Foundation
import CarPlay
import Intents

class CarPlayManager: NSObject, CPTemplateApplicationSceneDelegate {
    static let shared = CarPlayManager()
    
    var interfaceController: CPInterfaceController?
    private var aiService = AIService()
    private var voiceManager = VoiceManager()
    
    private override init() {
        super.init()
    }
    
    func setup() {
        print("🚗 Setting up CarPlay manager")
        // CarPlay setup is now handled through scene delegates
    }
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        print("🚗 CarPlay connected!")
        self.interfaceController = interfaceController
        setupCarPlayInterface()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        print("🚗 CarPlay disconnected")
        self.interfaceController = nil
    }
    
    func setupCarPlayInterface() {
        guard let interfaceController = interfaceController else {
            print("🚗 No interface controller available")
            return
        }
        
        print("🚗 Setting up CarPlay interface")
        // Create the main template
        let template = createMainTemplate()
        interfaceController.setRootTemplate(template, animated: true, completion: nil)
    }
    
    private func createMainTemplate() -> CPTemplate {
        // Create main menu items
        let newChatItem = CPListItem(
            text: "New Chat",
            detailText: "Start a new conversation",
            image: UIImage(systemName: "plus.circle")
        )
        newChatItem.handler = { [weak self] _, completion in
            self?.startNewChat(completion: completion)
        }
        
        let recentChatsItem = CPListItem(
            text: "Recent Chats",
            detailText: "View recent conversations", 
            image: UIImage(systemName: "clock")
        )
        recentChatsItem.handler = { [weak self] _, completion in
            self?.showRecentChats(completion: completion)
        }
        
        let voiceChatItem = CPListItem(
            text: "Voice Chat",
            detailText: "Start voice conversation",
            image: UIImage(systemName: "mic.circle")
        )
        voiceChatItem.handler = { [weak self] _, completion in
            self?.startVoiceChat(completion: completion)
        }
        
        let settingsItem = CPListItem(
            text: "Settings",
            detailText: "Configure AI service",
            image: UIImage(systemName: "gear")
        )
        settingsItem.handler = { [weak self] _, completion in
            self?.showSettings(completion: completion)
        }
        
        let listTemplate = CPListTemplate(
            title: "AI Chat Bot",
            sections: [
                CPListSection(items: [newChatItem, recentChatsItem, voiceChatItem, settingsItem])
            ]
        )
        
        return listTemplate
    }
    
    private func startNewChat(completion: @escaping () -> Void) {
        aiService.startNewChat()
        
        let chatTemplate = createChatTemplate()
        interfaceController?.pushTemplate(chatTemplate, animated: true, completion: nil)
        completion()
    }
    
    private func showRecentChats(completion: @escaping () -> Void) {
        let recentChats = aiService.getRecentChats()
        let items = recentChats.map { chat in
            let item = CPListItem(
                text: chat.title,
                detailText: chat.lastMessage,
                image: UIImage(systemName: "message")
            )
            item.handler = { [weak self] _, completion in
                self?.openChat(chat, completion: completion)
            }
            return item
        }
        
        let template = CPListTemplate(
            title: "Recent Chats",
            sections: [CPListSection(items: items)]
        )
        
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
        completion()
    }
    
    private func startVoiceChat(completion: @escaping () -> Void) {
        let voiceTemplate = createVoiceChatTemplate()
        interfaceController?.pushTemplate(voiceTemplate, animated: true, completion: nil)
        completion()
    }
    
    private func showSettings(completion: @escaping () -> Void) {
        let aiServiceItem = CPListItem(
            text: "AI Service",
            detailText: "Configure AI provider",
            image: UIImage(systemName: "brain")
        )
        aiServiceItem.handler = { _, completion in
            // Handle AI service selection
            completion()
        }
        
        let voiceSettingsItem = CPListItem(
            text: "Voice Settings",
            detailText: "Adjust voice preferences",
            image: UIImage(systemName: "speaker.wave.2")
        )
        voiceSettingsItem.handler = { _, completion in
            // Handle voice settings
            completion()
        }
        
        let settingsItems = [aiServiceItem, voiceSettingsItem]
        
        let template = CPListTemplate(
            title: "Settings",
            sections: [CPListSection(items: settingsItems)]
        )
        
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
        completion()
    }
    
    private func createChatTemplate() -> CPTemplate {
        let newMessageButton = CPGridButton(
            titleVariants: ["New Message"],
            image: UIImage(systemName: "plus.circle")!
        ) { [weak self] (button: CPGridButton) in
            self?.showChatInput()
        }
        
        let voiceInputButton = CPGridButton(
            titleVariants: ["Voice Input"],
            image: UIImage(systemName: "mic.circle")!
        ) { [weak self] (button: CPGridButton) in
            self?.startVoiceInput()
        }
        
        let repeatButton = CPGridButton(
            titleVariants: ["Repeat Last"],
            image: UIImage(systemName: "arrow.clockwise")!
        ) { [weak self] (button: CPGridButton) in
            self?.repeatLastResponse()
        }
        
        let template = CPGridTemplate(
            title: "AI Chat",
            gridButtons: [newMessageButton, voiceInputButton, repeatButton]
        )
        
        return template
    }
    
    private func createVoiceChatTemplate() -> CPTemplate {
        let startButton = CPGridButton(
            titleVariants: ["Start Recording"],
            image: UIImage(systemName: "mic.circle.fill")!
        ) { [weak self] (button: CPGridButton) in
            self?.startVoiceRecording()
        }
        
        let stopButton = CPGridButton(
            titleVariants: ["Stop Recording"],
            image: UIImage(systemName: "stop.circle.fill")!
        ) { [weak self] (button: CPGridButton) in
            self?.stopVoiceRecording()
        }
        
        let template = CPGridTemplate(
            title: "Voice Chat",
            gridButtons: [startButton, stopButton]
        )
        
        return template
    }
    
    private func showChatInput() {
        // Show text input interface
        let cancelAction = CPAlertAction(title: "Cancel", style: .cancel) { _ in
            // Just dismiss
        }
        
        let sendAction = CPAlertAction(title: "Send", style: .default) { [weak self] _ in
            self?.sendChatMessage()
        }
        
        let alert = CPAlertTemplate(
            titleVariants: ["New Message"],
            actions: [cancelAction, sendAction]
        )
        
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
    
    private func startVoiceInput() {
        voiceManager.startRecording { [weak self] transcribedText in
            DispatchQueue.main.async {
                self?.handleVoiceInput(transcribedText)
            }
        }
    }
    
    private func startVoiceRecording() {
        voiceManager.startRecording { [weak self] transcribedText in
            DispatchQueue.main.async {
                self?.handleVoiceInput(transcribedText)
            }
        }
    }
    
    private func stopVoiceRecording() {
        voiceManager.stopRecording()
    }
    
    private func handleVoiceInput(_ text: String) {
        guard !text.isEmpty else { return }
        
        Task {
            await aiService.sendMessage(text)
            
            // Speak the AI response
            if let lastMessage = aiService.chatHistory.last,
               lastMessage.isFromAI {
                voiceManager.speak(lastMessage.content)
            }
        }
    }
    
    private func sendChatMessage() {
        // Handle sending the current message
    }
    
    private func repeatLastResponse() {
        guard let lastMessage = aiService.chatHistory.last,
              lastMessage.isFromAI else { return }
        
        voiceManager.speak(lastMessage.content)
    }
    
    private func openChat(_ chat: ChatSession, completion: @escaping () -> Void) {
        // Open a specific chat session
        completion()
    }
}
