import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: MovrPlusViewModel
    @State private var isDestinationSelectorOpen = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Movr Plus")
                .font(.largeTitle.bold())
                .foregroundColor(.blue)
            
            HStack {
                Text("Destination Folder:")
                    .font(.headline)
                
                if viewModel.baseDestinationPath.isEmpty {
                    Text("No folder selected")
                        .foregroundColor(.red)
                        .italic()
                } else {
                    Text(viewModel.baseDestinationPath)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                Button("Select Folder") {
                    selectDestinationFolder()
                }
                .buttonStyle(.bordered)
                
                // Recent folders dropdown
                Menu {
                    ForEach(RecentFilesManager.shared.recentDestinationPaths, id: \.self) { path in
                        Button(path) {
                            viewModel.baseDestinationPath = path
                        }
                    }
                    
                    if !RecentFilesManager.shared.recentDestinationPaths.isEmpty {
                        Divider()
                        Button("Clear Recent Paths", role: .destructive) {
                            RecentFilesManager.shared.clearRecentPaths()
                        }
                    }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .disabled(RecentFilesManager.shared.recentDestinationPaths.isEmpty)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.bottom, 10)
    }
    
    func selectDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.baseDestinationPath = url.path
            RecentFilesManager.shared.addRecentPath(url.path)
        }
    }
}
