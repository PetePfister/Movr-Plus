import SwiftUI
import UniformTypeIdentifiers

struct LogViewer: View {
    @State private var logText = ProcessingLog.shared.generateLogReport()
    @State private var showingSaveDialog = false
    
    var body: some View {
        VStack {
            Text("Processing Log")
                .font(.title)
                .padding()
            
            ScrollView {
                Text(logText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(minWidth: 600, minHeight: 400)
            
            HStack {
                Button("Save Log") {
                    showingSaveDialog = true
                }
                .padding()
                
                Spacer()
                
                Button("Close") {
                    // Dismiss presented by parent
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 700, height: 500)
        .background(Color(.windowBackgroundColor))
        .fileExporter(
            isPresented: $showingSaveDialog,
            document: TextDocument(text: logText),
            contentType: .plainText,
            defaultFilename: "MovrPlus_Log"
        ) { _ in }
    }
}

// Text Document for Log Export
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
