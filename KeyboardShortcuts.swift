import SwiftUI
import AppKit

// Simple keyboard shortcuts manager
struct KeyboardShortcutsManager {
    static let importFiles = KeyEquivalent("i")
    static let clearAll = KeyEquivalent("k")
    static let processFiles = KeyEquivalent("p")
    static let verifyAll = KeyEquivalent("v")
    static let batchControls = KeyEquivalent("b")
    static let search = KeyEquivalent("f")
    static let autoFill = KeyEquivalent("a")
    static let sort = KeyEquivalent("s")
}

// Menu commands for keyboard shortcuts
struct KeyboardShortcutCommands: Commands {
    let importAction: () -> Void
    let clearAction: () -> Void
    let processAction: () -> Void
    let verifyAction: () -> Void
    let toggleBatchAction: () -> Void
    let searchAction: () -> Void
    let autoFillAction: () -> Void
    let sortAction: () -> Void
    
    var body: some Commands {
        CommandMenu("File") {
            Button("Import Files") {
                importAction()
            }.keyboardShortcut(KeyboardShortcutsManager.importFiles, modifiers: [.command])
            
            Button("Clear All") {
                clearAction()
            }.keyboardShortcut(KeyboardShortcutsManager.clearAll, modifiers: [.command])
            
            Button("Process Files") {
                processAction()
            }.keyboardShortcut(KeyboardShortcutsManager.processFiles, modifiers: [.command])
        }
        
        CommandMenu("Tools") {
            Button("Toggle Verify All") {
                verifyAction()
            }.keyboardShortcut(KeyboardShortcutsManager.verifyAll, modifiers: [.command])
            
            Button("Toggle Batch Controls") {
                toggleBatchAction()
            }.keyboardShortcut(KeyboardShortcutsManager.batchControls, modifiers: [.command])
            
            Button("Search") {
                searchAction()
            }.keyboardShortcut(KeyboardShortcutsManager.search, modifiers: [.command])
            
            Button("Auto-Fill Missing Info") {
                autoFillAction()
            }.keyboardShortcut(KeyboardShortcutsManager.autoFill, modifiers: [.command])
            
            Button("Sort Files") {
                sortAction()
            }.keyboardShortcut(KeyboardShortcutsManager.sort, modifiers: [.command])
        }
    }
}
