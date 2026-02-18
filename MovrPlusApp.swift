import SwiftUI

@main
struct MovrPlusApp: App {
    // Use StateObject for creating a viewModel
    @StateObject private var viewModel = MovrPlusViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
