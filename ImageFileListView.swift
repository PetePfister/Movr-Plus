import SwiftUI

struct ImageFileListView: View {
    @ObservedObject var viewModel: MovrPlusViewModel
    @State private var searchText: String = ""
    
    // Search predicate for files
    private func fileMatchesSearch(_ file: ImageFile) -> Bool {
        if searchText.isEmpty { return true }
        let lowercasedQuery = searchText.lowercased()
        
        return file.originalFilename.lowercased().contains(lowercasedQuery) ||
               file.description.lowercased().contains(lowercasedQuery) ||
               file.requestID.lowercased().contains(lowercasedQuery) ||
               file.imageType.rawValue.lowercased().contains(lowercasedQuery) ||
               file.company.rawValue.lowercased().contains(lowercasedQuery)
    }
    
    var filteredFiles: [ImageFile] {
        if searchText.isEmpty {
            return viewModel.imageFiles
        } else {
            return viewModel.imageFiles.filter { fileMatchesSearch($0) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .padding([.horizontal, .top])
            
            // Results summary if filtering
            if !searchText.isEmpty {
                HStack {
                    Text("Showing \(filteredFiles.count) of \(viewModel.imageFiles.count) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            
            // File list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredFiles) { file in
                        ImageFileRow(fileId: file.id, viewModel: viewModel)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 1)
                            .id("\(file.id)-\(file.imageType)-\(file.sequence)")
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Prefetch thumbnails for files in the background
            Task {
                for url in viewModel.imageFiles.map({ $0.originalURL }) {
                    // Add completion handler to the thumbnail call
                    ThumbnailManager.shared.thumbnail(for: url) { _ in
                        // We're just prefetching, so we don't need to do anything with the result
                    }
                    // Give UI a chance to breathe between loads
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                }
            }
        }
    }
}
