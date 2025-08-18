import SwiftUI

struct ContentView: View {
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("AI Chat Bot")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Welcome to AI Chat Bot!")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    
                    Text("This is a boilerplate CarPlay-enabled chat application.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    TextField("Type your message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send Message") {
                        // Placeholder for send functionality
                        messageText = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
} 