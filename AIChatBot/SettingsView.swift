import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingAPIKeySetup = false
    @State private var newAPIKey = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("API Configuration") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Perplexity API")
                                .font(.headline)
                            Text(Config.isPerplexityConfigured ? "✅ Configured" : "❌ Not configured")
                                .font(.caption)
                                .foregroundColor(Config.isPerplexityConfigured ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Button(Config.isPerplexityConfigured ? "Update" : "Setup") {
                            showingAPIKeySetup = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if Config.isPerplexityConfigured {
                        Button("Remove API Key", role: .destructive) {
                            removeAPIKey()
                        }
                    }
                }
                
                Section("Security Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Secure Storage", systemImage: "lock.shield")
                            .font(.headline)
                        
                        Text("Your API key is stored securely in the iOS Keychain and is never saved in plain text or shared with third parties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("AI Provider")
                        Spacer()
                        Text("Perplexity AI")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAPIKeySetup) {
            APIKeySetupView(newAPIKey: $newAPIKey) { apiKey in
                setupAPIKey(apiKey)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupAPIKey(_ apiKey: String) {
        guard !apiKey.isEmpty else {
            showAlert(title: "Invalid API Key", message: "Please enter a valid API key.")
            return
        }
        
        guard apiKey.hasPrefix("pplx-") else {
            showAlert(title: "Invalid Format", message: "Perplexity API keys should start with 'pplx-'.")
            return
        }
        
        if Config.setupPerplexityAPIKey(apiKey) {
            showAlert(title: "Success", message: "API key has been securely saved.")
            newAPIKey = ""
        } else {
            showAlert(title: "Error", message: "Failed to save API key. Please try again.")
        }
    }
    
    private func removeAPIKey() {
        if Config.removePerplexityAPIKey() {
            showAlert(title: "Removed", message: "API key has been removed from secure storage.")
        } else {
            showAlert(title: "Error", message: "Failed to remove API key.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct APIKeySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newAPIKey: String
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("API Key Setup")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your Perplexity API key to enable AI chat functionality.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.headline)
                    
                    SecureField("pplx-xxxxxxxxxxxxxxxxxx", text: $newAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Your API key will be stored securely in the iOS Keychain.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Save API Key") {
                        onSave(newAPIKey)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newAPIKey.isEmpty)
                    
                    Link("Get API Key from Perplexity", destination: URL(string: "https://www.perplexity.ai/settings/api")!)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("API Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

#Preview {
    APIKeySetupView(newAPIKey: .constant("")) { _ in }
}