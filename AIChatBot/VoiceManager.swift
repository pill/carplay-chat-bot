import Foundation
import Speech
import AVFoundation

class VoiceManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var hasPermission = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
        checkPermissions()
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.hasPermission = status == .authorized
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.hasPermission = self?.hasPermission ?? false && granted
                }
            }
        }
    }
    
    private func checkPermissions() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let audioStatus = AVAudioSession.sharedInstance().recordPermission
        
        hasPermission = speechStatus == .authorized && audioStatus == .granted
    }
    
    func startRecording(completion: @escaping (String) -> Void) {
        guard hasPermission else {
            print("Speech recognition permission not granted")
            return
        }
        
        // Stop any existing recording
        stopRecording()
        
        // Configure audio session for iOS Simulator compatibility
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                var isFinal = false
                
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    completion(transcribedText)
                    isFinal = result.isFinal
                }
                
                if error != nil || isFinal {
                    self?.stopRecording()
                }
            }
        }
        
        // Configure audio input with safer format handling
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate format before using
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("Invalid audio format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
            stopRecording()
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        // Reset audio session
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
    }
    
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Configure audio session for speech synthesis
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session for speech: \(error)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        // Speak
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func continueSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    // MARK: - Voice Commands
    
    func processVoiceCommand(_ command: String) -> VoiceCommand? {
        let lowercasedCommand = command.lowercased()
        
        if lowercasedCommand.contains("stop") || lowercasedCommand.contains("pause") {
            return .stop
        } else if lowercasedCommand.contains("continue") || lowercasedCommand.contains("resume") {
            return .continue
        } else if lowercasedCommand.contains("repeat") {
            return .`repeat`
        } else if lowercasedCommand.contains("new chat") || lowercasedCommand.contains("start over") {
            return .newChat
        } else if lowercasedCommand.contains("help") {
            return .help
        } else if lowercasedCommand.contains("start ai") || lowercasedCommand.contains("start processing") || lowercasedCommand.contains("begin ai") {
            return .startAI
        } else if lowercasedCommand.contains("stop ai") || lowercasedCommand.contains("stop processing") || lowercasedCommand.contains("cancel ai") {
            return .stopAI
        }
        
        return nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

// MARK: - Voice Commands

enum VoiceCommand {
    case stop
    case `continue`
    case `repeat`
    case newChat
    case help
    case startAI
    case stopAI
    
    var description: String {
        switch self {
        case .stop:
            return "Stop speaking"
        case .continue:
            return "Continue speaking"
        case .`repeat`:
            return "Repeat last response"
        case .newChat:
            return "Start new chat"
        case .help:
            return "Show help"
        case .startAI:
            return "Start voice recording"
        case .stopAI:
            return "Stop AI processing"
        }
    }
} 