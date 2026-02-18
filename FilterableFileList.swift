import SwiftUI

// Filterable File List with Search
struct FilterableFileList<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let searchPredicate: (Item, String) -> Bool
    let itemView: (Item) -> ItemView
    
    @Binding var searchText: String
    @State private var isSearchFocused: Bool = false
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { searchPredicate($0, searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                DebouncedTextField("Search files...", text: $searchText)
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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSearchFocused ? Color.blue : Color.clear, lineWidth: 1)
            )
            
            // Results summary if filtering
            if !searchText.isEmpty {
                HStack {
                    Text("Showing \(filteredItems.count) of \(items.count) files")
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
                    ForEach(filteredItems) { item in
                        itemView(item)
                    }
                }
                .padding()
            }
        }
    }
}