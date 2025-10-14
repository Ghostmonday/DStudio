import SwiftUI

// MARK: - Settings View for App Configuration
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPrivacyPolicy = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
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
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Validate configuration on app launch
            _ = DeepSeekConfig.validateConfiguration()
        }
    }
    
    // MARK: - Helper Methods
    // No user-configurable API key methods needed
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

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
