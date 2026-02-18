import SwiftUI

// Status Message Toast
struct StatusToast: View {
    enum ToastStyle {
        case success, error, info, warning
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    let message: String
    let style: ToastStyle
    let isVisible: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
                .font(.title3)
            
            Text(message)
                .lineLimit(3)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.windowBackgroundColor).opacity(0.95))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.color.opacity(0.3), lineWidth: 1)
        )
        .padding()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 50)
        .animation(.spring(), value: isVisible)
    }
}