import Foundation

// Batch Processing Coordinator for efficient sequencing of operations
actor BatchProcessingCoordinator {
    private var isProcessing = false
    private var queue = [() async -> Void]()
    private var isCancelled = false
    
    // Progress tracking
    private(set) var total = 0
    private(set) var completed = 0
    
    var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    func addOperation(_ operation: @escaping () async -> Void) {
        queue.append(operation)
        total += 1
        processNextIfNeeded()
    }
    
    func addOperations(_ operations: [() async -> Void]) {
        queue.append(contentsOf: operations)
        total += operations.count
        processNextIfNeeded()
    }
    
    private func processNextIfNeeded() {
        guard !isProcessing, !queue.isEmpty, !isCancelled else { return }
        
        isProcessing = true
        let operation = queue.removeFirst()
        
        Task {
            await operation()
            completed += 1
            isProcessing = false
            processNextIfNeeded()
        }
    }
    
    func cancelAll() {
        isCancelled = true
        queue.removeAll()
    }
    
    func reset() {
        isCancelled = false
        total = 0
        completed = 0
    }
}