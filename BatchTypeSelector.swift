import SwiftUI

struct BatchTypeSelector: View {
    @ObservedObject var viewModel: MovrPlusViewModel
    
    // Define grid layout with 3 columns
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Default Image Type for Batch")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(ImageType.allCases) { type in
                    Button {
                        viewModel.selectedBatchType = type
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.system(size: 28))
                            
                            Text(type.rawValue)
                                .fontWeight(.medium)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 140, height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedBatchType == type ? type.color.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedBatchType == type ? type.color : Color.gray.opacity(0.3),
                                                lineWidth: viewModel.selectedBatchType == type ? 2 : 1)
                                )
                        )
                        .foregroundColor(viewModel.selectedBatchType == type ? type.color : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Drop files to begin")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding()
    }
}
