import Foundation
import SwiftUI

// Recent Files Manager with persistence
class RecentFilesManager: ObservableObject {
    static let shared = RecentFilesManager()
    private let userDefaultsKey = "recentDestinationPaths"
    private let maxRecentItems = 5
    
    @Published var recentDestinationPaths: [String] = []
    
    init() {
        loadRecentPaths()
    }
    
    private func loadRecentPaths() {
        if let paths = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            recentDestinationPaths = paths
        }
    }
    
    func addRecentPath(_ path: String) {
        // Remove if already exists to avoid duplicates
        recentDestinationPaths.removeAll { $0 == path }
        
        // Insert at beginning
        recentDestinationPaths.insert(path, at: 0)
        
        // Keep only the most recent ones
        if recentDestinationPaths.count > maxRecentItems {
            recentDestinationPaths = Array(recentDestinationPaths.prefix(maxRecentItems))
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(recentDestinationPaths, forKey: userDefaultsKey)
    }
    
    func clearRecentPaths() {
        recentDestinationPaths.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // Check if paths still exist
    func validatePaths() {
        let fileManager = FileManager.default
        recentDestinationPaths = recentDestinationPaths.filter { path in
            fileManager.fileExists(atPath: path)
        }
        UserDefaults.standard.set(recentDestinationPaths, forKey: userDefaultsKey)
    }
}