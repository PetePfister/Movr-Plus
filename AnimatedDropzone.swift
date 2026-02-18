import SwiftUI
import UniformTypeIdentifiers

// Improved Dropzone with Animation
struct AnimatedDropzone: View {
    var isTargeted: Bool
    var isEmpty: Bool
    var onDropAction: ([NSItemProvider]) -> Bool
    var onTapAction: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background rectangle
            let backgroundFill = isTargeted ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08)
            let strokeColor = isTargeted ? Color.blue : Color.gray.opacity(0.2)
            let lineWidth: CGFloat = isTargeted ? 2 : 1
            
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundFill)
                .overlay(
                    // Use stroke instead of strokeBorder for dashed lines
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(strokeColor, style: StrokeStyle(
                            lineWidth: lineWidth,
                            dash: isTargeted ? [] : [6, 3]
                        ))
                )
            
            VStack(spacing: 16) {
                let iconName = isEmpty ? "arrow.down.doc.fill" : "photo.on.rectangle.angled"
                let iconColor = isTargeted ? Color.blue : Color.gray
                
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundColor(iconColor)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .animation(.spring(), value: isTargeted)
                
                let textContent = isEmpty ? "Drop files here or click to import" : "Drop more files to add to batch"
                let textColor = isTargeted ? Color.primary : Color.secondary
                
                Text(textContent)
                    .font(.title3)
                    .foregroundColor(textColor)
            }
            .padding()
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
            onDropAction(providers)
        }
        .onChange(of: isTargeted) { newValue in
            withAnimation(.spring()) {
                scale = newValue ? 1.1 : 1.0
                rotation = newValue ? 5 : 0
            }
        }
        .onTapGesture {
            onTapAction()
        }
    }
}
