import SwiftUI

// Process Button with Progress
struct ProcessButtonWithProgress: View {
    let isProcessing: Bool
    let progress: Double
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                if isProcessing {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 16, height: 16)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(progress))
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(-90))
                    }
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                }
                
                Text(isProcessing ? "Processing..." : "Process Files")
            }
            .frame(minWidth: 150)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isProcessing)
        .animation(.easeInOut, value: isProcessing)
    }
}