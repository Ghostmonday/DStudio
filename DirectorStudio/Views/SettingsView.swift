import SwiftUI

// MARK: - Settings View for App Configuration
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthService()
    @StateObject private var creditWallet = CreditWallet()
    @StateObject private var storeManager = StoreManager()
    
    @State private var showingPrivacyPolicy = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPaywallSheet = false
    @State private var showingAPIKeySheet = false
    @State private var apiKeyText = ""
    @State private var shareTelemetry = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Section
                Section {
                    if authService.isSignedIn {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Signed in with Apple")
                                    .font(.headline)
                                if let email = authService.userEmail {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button("Sign Out") {
                                authService.signOut()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    } else {
                        Button(action: { authService.signInWithApple() }) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                Text("Sign in with Apple")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Account")
                }
                
                // MARK: - Credits Section
                Section {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("Credits")
                        Spacer()
                        Text("\(creditWallet.balance)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { showingPaywallSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            Text("Buy More Credits")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { Task { await storeManager.restorePurchases() } }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                            Text("Restore Purchases")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Credits")
                }
                
                // MARK: - AI Configuration Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Processing")
                                .font(.headline)
                            Spacer()
                            if DeepSeekConfig.hasValidAPIKey() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Text(DeepSeekConfig.hasValidAPIKey() ? 
                             "AI features are enabled and ready to process your stories." :
                             "AI features require developer configuration. Contact support if needed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Status")
                                .fontWeight(.medium)
                            Spacer()
                            Text(DeepSeekConfig.hasValidAPIKey() ? "Configured" : "Not Configured")
                                .foregroundColor(DeepSeekConfig.hasValidAPIKey() ? .green : .orange)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("AI Configuration")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Notice:")
                            .fontWeight(.semibold)
                        Text("• Story content is sent to DeepSeek for AI processing")
                        Text("• No personal data is collected or stored by DirectorStudio")
                        Text("• All processing happens securely through encrypted connections")
                        Text("• Your stories remain private and are not shared with third parties")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // MARK: - Sora API Configuration
                Section {
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundColor(.purple)
                        Text("Sora/Pollo API")
                        Spacer()
                        if APIKeyManager.shared.hasAPIKey() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: { showingAPIKeySheet = true }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.blue)
                            Text("Connect Sora/Pollo")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Video Generation")
                } footer: {
                    Text("Required for generating video clips with Sora AI. Your API key is stored securely in Keychain.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Telemetry Section
                Section {
                    Toggle(isOn: $shareTelemetry) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                            Text("Share Performance Data")
                        }
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Help improve DirectorStudio by sharing anonymized performance data. No personal information is collected.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Privacy Section
                Section {
                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Privacy & Data")
                }
                
                // MARK: - App Information
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Information")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingPaywallSheet) {
            PaywallSheet()
        }
        .sheet(isPresented: $showingAPIKeySheet) {
            APIKeySheet(apiKeyText: $apiKeyText)
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Validate configuration on app launch
            _ = DeepSeekConfig.validateConfiguration()
            // Load telemetry preference
            shareTelemetry = UserDefaults.standard.bool(forKey: "shareTelemetry")
            // Load existing API key
            apiKeyText = APIKeyManager.shared.getAPIKey()
        }
        .onChange(of: shareTelemetry) { newValue in
            UserDefaults.standard.set(newValue, forKey: "shareTelemetry")
        }
        .task {
            await creditWallet.refresh()
        }
    }
    
    // MARK: - Helper Methods
    // No user-configurable API key methods needed
}

// MARK: - API Key Sheet
struct APIKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var apiKeyText: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Connect Sora/Pollo API")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your Pollo.ai API key to enable video generation with Sora AI.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.headline)
                    
                    SecureField("Enter your Pollo.ai API key", text: $apiKeyText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(apiKeyText.isEmpty)
                    
                    if APIKeyManager.shared.hasAPIKey() {
                        Button("Remove API Key") {
                            removeAPIKey()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("API Key", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveAPIKey() {
        if APIKeyManager.shared.isValidAPIKey(apiKeyText) {
            let success = APIKeyManager.shared.saveAPIKey(apiKeyText)
            if success {
                alertMessage = "API key saved successfully"
                showingAlert = true
                dismiss()
            } else {
                alertMessage = "Failed to save API key"
                showingAlert = true
            }
        } else {
            alertMessage = "Please enter a valid API key"
            showingAlert = true
        }
    }
    
    private func removeAPIKey() {
        let success = APIKeyManager.shared.deleteAPIKey()
        if success {
            apiKeyText = ""
            alertMessage = "API key removed successfully"
            showingAlert = true
            dismiss()
        } else {
            alertMessage = "Failed to remove API key"
            showingAlert = true
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Group {
                        privacySection(
                            title: "Data Collection",
                            content: "DirectorStudio does not collect, store, or transmit any personal information. The only data processed is the story content you provide for AI analysis."
                        )
                        
                        privacySection(
                            title: "API Configuration",
                            content: "DirectorStudio uses a developer-configured DeepSeek API key for AI processing. The key is embedded securely in the app and never exposed to users."
                        )
                        
                        privacySection(
                            title: "AI Processing",
                            content: "Story content is sent directly to DeepSeek's API for processing. We do not store, cache, or retain any of your content after processing is complete."
                        )
                        
                        privacySection(
                            title: "Local Storage",
                            content: "Processed projects are stored locally on your device using UserDefaults. This data remains on your device and is not synced or backed up to external servers."
                        )
                        
                        privacySection(
                            title: "Third-Party Services",
                            content: "DirectorStudio uses DeepSeek's API for AI processing. Please review DeepSeek's privacy policy for information about how they handle your data."
                        )
                        
                        privacySection(
                            title: "Your Rights",
                            content: "You can delete all local data at any time by uninstalling the app. There is no account or registration required."
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// #Preview {
//     SettingsView()
//         .environmentObject(AppState())
// }
