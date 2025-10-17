import SwiftUI

// MARK: - Export Sheet
struct ExportSheet: View {
    // BugScan: export system noop touch for analysis
    let project: Project?
    @Binding var selectedFormat: StudioView.ExportFormat
    @Binding var showShareSheet: Bool
    @Binding var exportedContent: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Format Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Format")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(StudioView.ExportFormat.allCases, id: \.self) { format in
                            Button(action: { selectedFormat = format }) {
                                HStack {
                                    Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedFormat == format ? .purple : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(format.rawValue)
                                            .foregroundColor(.white)
                                        
                                        Text(formatDescription(format))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Export Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            generateExport()
                            showShareSheet = true
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            generateExport()
                            saveToFiles()
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Save to Files")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .navigationTitle("Export Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    func formatDescription(_ format: StudioView.ExportFormat) -> String {
        switch format {
        case .screenplay:
            return "Full screenplay with scenes, characters, and cinematic direction"
        case .json:
            return "Raw data format for technical integration"
        case .promptList:
            return "Simple list of AI prompts ready for video generation"
        }
    }
    
    func generateExport() {
        guard let project = project else { return }
        
        switch selectedFormat {
        case .screenplay:
            exportedContent = project.exportAsScreenplay()
        case .json:
            exportedContent = project.exportAsJSON()
        case .promptList:
            exportedContent = project.exportAsPromptList()
        }
    }
    
    func saveToFiles() {
        guard let project = project else { return }
        
        let fileName: String
        let content = exportedContent
        
        switch selectedFormat {
        case .screenplay, .promptList:
            fileName = "\(project.title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).txt"
        case .json:
            fileName = "\(project.title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).json"
        }
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(fileName)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Show success feedback
            print("✅ Saved to: \(fileURL.path)")
        } catch {
            print("❌ Save error: \(error.localizedDescription)")
        }
        
        dismiss()
    }
}
