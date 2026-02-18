import SwiftUI

// Debounced Text Field for delayed searching/filtering
struct DebouncedTextField: View {
    @Binding var text: String
    @State private var localText: String = ""
    let placeholder: String
    let debounceTime: TimeInterval
    
    @State private var debounceTask: Task<Void, Never>? = nil
    
    init(_ placeholder: String, text: Binding<String>, debounceTime: TimeInterval = 0.5) {
        self.placeholder = placeholder
        self._text = text
        self.debounceTime = debounceTime
    }
    
    var body: some View {
        TextField(placeholder, text: $localText)
            .onChange(of: localText) { newValue in
                // Cancel previous debounce task if it exists
                debounceTask?.cancel()
                
                // Create a new debounce task
                debounceTask = Task {
                    // Wait for the debounce time
                    try? await Task.sleep(nanoseconds: UInt64(debounceTime * 1_000_000_000))
                    
                    // If not cancelled, update the binding
                    if !Task.isCancelled {
                        text = newValue
                    }
                }
            }
            .onAppear {
                localText = text
            }
    }
}