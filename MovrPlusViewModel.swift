import SwiftUI
import Combine
import UniformTypeIdentifiers

// Helper actor for URL collection to avoid Sendable issues
actor URLCollector {
    private(set) var urls: [URL] = []
    
    func add(_ url: URL) {
        urls.append(url)
    }
    
    func getAll() -> [URL] {
        return urls
    }
    
    func clear() {
        urls.removeAll()
    }
}

@MainActor
class MovrPlusViewModel: ObservableObject {
    @Published var imageFiles: [ImageFile] = []
    @Published var baseDestinationPath: String = ""
    @Published var selectedBatchType: ImageType? = nil
    @Published var isProcessing: Bool = false
    @Published var processingMessage: String = ""
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false
    
    // Enhanced properties
    @Published var processingProgress: Double = 0
    @Published var processingSpeed: Double = 0 // Files per second
    @Published var estimatedTimeRemaining: TimeInterval = 0
    
    // Processing timestamp and user info - UPDATED
    private let username: String = "PetePfister"
    private let currentDateTime: String = "2025-07-28 21:43:13"
    
    // Performance tracking
    private var processingStartTime: Date?
    private var lastProgressUpdate: Date = Date()
    private var filesProcessedSinceLastUpdate: Int = 0
    
    // Auto-save state
    private var autoSaveTimer: Timer?
    
    init() {
        // Load recent destination path if available
        if let lastPath = RecentFilesManager.shared.recentDestinationPaths.first {
            baseDestinationPath = lastPath
        }
        
        // Load saved batch type
        if let savedBatchType = UserDefaults.standard.string(forKey: "selectedBatchType"),
           let batchType = ImageType.allCases.first(where: { $0.rawValue == savedBatchType }) {
            selectedBatchType = batchType
        }
        
        // Start auto-save timer
        startAutoSaveTimer()
    }
    
    deinit {
        autoSaveTimer?.invalidate()
    }
    
    // MARK: - Auto-Save Functionality
    
    private func startAutoSaveTimer() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                self.saveAppState()
            }
        }
    }
    
    private func saveAppState() {
        if let batchType = selectedBatchType {
            UserDefaults.standard.set(batchType.rawValue, forKey: "selectedBatchType")
        }
        UserDefaults.standard.set(baseDestinationPath, forKey: "lastDestinationPath")
        
        // Save file metadata for recovery
        let fileData = imageFiles.map { file in
            [
                "url": file.originalURL.path,
                "type": file.imageType.rawValue,
                "description": file.description,
                "requestID": file.requestID,
                "company": file.company.rawValue,
                "sequence": file.sequence,
                "verified": file.isVerified
            ]
        }
        UserDefaults.standard.set(fileData, forKey: "savedImageFiles")
    }
    
    func loadSavedFiles() {
        guard let savedData = UserDefaults.standard.array(forKey: "savedImageFiles") as? [[String: Any]] else { return }
        
        var loadedFiles: [ImageFile] = []
        
        for data in savedData {
            guard let urlPath = data["url"] as? String,
                  let typeString = data["type"] as? String,
                  let type = ImageType.allCases.first(where: { $0.rawValue == typeString }),
                  FileManager.default.fileExists(atPath: urlPath) else { continue }
            
            let url = URL(fileURLWithPath: urlPath)
            var file = ImageFile(url: url, initialType: type)
            
            if let description = data["description"] as? String { file.description = description }
            if let requestID = data["requestID"] as? String { file.requestID = requestID }
            if let companyString = data["company"] as? String,
               let company = Retailer.allCases.first(where: { $0.rawValue == companyString }) {
                file.company = company
            }
            if let sequence = data["sequence"] as? String { file.sequence = sequence }
            if let verified = data["verified"] as? Bool { file.isVerified = verified }
            
            // Regenerate filename
            file.newFilename = ImageFile.generateNewFilename(
                description: file.description,
                requestID: file.requestID,
                company: file.company,
                sequence: file.sequence,
                isRetouched: file.isRetouched,
                imageType: file.imageType,
                originalExtension: file.originalExtension
            )
            
            loadedFiles.append(file)
        }
        
        if !loadedFiles.isEmpty {
            imageFiles = loadedFiles
            ProcessingLog.shared.logAction(
                action: "Session Restored",
                filename: "Application",
                result: "Loaded \(loadedFiles.count) files from previous session"
            )
        }
    }
    
    // MARK: - File Handling Methods
    
    func handleFileDrop(providers: [NSItemProvider]) {
        let urlTypeIdentifier = UTType.fileURL.identifier
        
        Task {
            let collector = URLCollector()
            
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(urlTypeIdentifier) {
                    let urlResult: URL? = await withCheckedContinuation { continuation in
                        provider.loadItem(forTypeIdentifier: urlTypeIdentifier, options: nil) { (item, error) in
                            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                                continuation.resume(returning: url)
                            } else if let url = item as? URL {
                                continuation.resume(returning: url)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        }
                    }
                    
                    if let url = urlResult {
                        await collector.add(url)
                    }
                }
            }
            
            let urls = await collector.getAll()
            
            await MainActor.run {
                importFiles(from: urls)
            }
        }
    }
    
    func importFiles(from urls: [URL]) {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "tif", "tiff", "bmp", "heic", "ai", "svg", "eps", "r3d", "cr2", "rtn", "pct", "arw", "dpx", "psb", "thm", "ps", "psd", "avif", "tga", "webp", "dng", "nef", "crw"]
        
        var importedCount = 0
        var skippedCount = 0
        
        for url in urls {
            let fileExtension = url.pathExtension.lowercased()
            if imageExtensions.contains(fileExtension) {
                // Check if file already exists
                if !imageFiles.contains(where: { $0.originalURL.path == url.path }) {
                    let newFile = ImageFile(url: url, initialType: selectedBatchType)
                    imageFiles.append(newFile)
                    importedCount += 1
                } else {
                    skippedCount += 1
                }
            }
        }
        
        // Sort files by name for consistent display
        imageFiles.sort { $0.originalFilename < $1.originalFilename }
        
        // Log import results
        if importedCount > 0 {
            ProcessingLog.shared.logAction(
                action: "Files Imported",
                filename: "Batch Import",
                result: "Imported \(importedCount) files, skipped \(skippedCount) duplicates"
            )
        }
        
        // Auto-save after import
        saveAppState()
        
        // Preload thumbnails for first few files
        if !imageFiles.isEmpty {
            let urlsToPreload = Array(imageFiles.prefix(10).map { $0.originalURL })
            ThumbnailManager.shared.preloadThumbnails(for: urlsToPreload)
        }
    }
    
    // MARK: - File Management Methods
    
    func clearFiles() {
        imageFiles.removeAll()
        processingMessage = ""
        processingProgress = 0
        processingSpeed = 0
        estimatedTimeRemaining = 0
        
        ProcessingLog.shared.logAction(
            action: "Files Cleared",
            filename: "Application",
            result: "All files removed from current session"
        )
        
        // Clear saved state
        UserDefaults.standard.removeObject(forKey: "savedImageFiles")
    }
    
    func removeFile(id: UUID) {
        if let index = imageFiles.firstIndex(where: { $0.id == id }) {
            let filename = imageFiles[index].originalFilename
            imageFiles.remove(at: index)
            
            ProcessingLog.shared.logAction(
                action: "File Removed",
                filename: filename,
                result: "File removed from current batch"
            )
            
            saveAppState()
        }
    }
    
    func removeFiles(ids: [UUID]) {
        let removedCount = ids.count
        imageFiles.removeAll { ids.contains($0.id) }
        
        ProcessingLog.shared.logAction(
            action: "Bulk File Removal",
            filename: "Batch Operation",
            result: "Removed \(removedCount) files from current batch"
        )
        
        saveAppState()
    }
    
    // MARK: - File Update Methods
    
    func updateImageType(id: UUID, type: ImageType) {
        if let index = imageFiles.firstIndex(where: { $0.id == id }) {
            let oldType = imageFiles[index].imageType
            imageFiles[index].imageType = type
            imageFiles[index].destinationFolder = type.defaultDestination
            
            // Regenerate filename with new type
            imageFiles[index].newFilename = ImageFile.generateNewFilename(
                description: imageFiles[index].description,
                requestID: imageFiles[index].requestID,
                company: imageFiles[index].company,
                sequence: imageFiles[index].sequence,
                isRetouched: imageFiles[index].isRetouched,
                imageType: type,
                originalExtension: imageFiles[index].originalExtension
            )
            
            ProcessingLog.shared.logAction(
                action: "Image Type Changed",
                filename: imageFiles[index].originalFilename,
                result: "Changed from \(oldType.rawValue) to \(type.rawValue)"
            )
        }
    }
    
    func updateProductInfo(id: UUID, description: String, requestID: String, company: Retailer, sequence: String, isRetouched: Bool) {
        if let index = imageFiles.firstIndex(where: { $0.id == id }) {
            let oldDescription = imageFiles[index].description
            let oldRequestID = imageFiles[index].requestID
            let oldCompany = imageFiles[index].company
            
            imageFiles[index].description = description
            imageFiles[index].requestID = requestID
            imageFiles[index].company = company
            imageFiles[index].sequence = sequence
            imageFiles[index].isRetouched = isRetouched
            
            // Regenerate filename
            imageFiles[index].newFilename = ImageFile.generateNewFilename(
                description: description,
                requestID: requestID,
                company: company,
                sequence: sequence,
                isRetouched: isRetouched,
                imageType: imageFiles[index].imageType,
                originalExtension: imageFiles[index].originalExtension
            )
            
            // Log changes
            var changes: [String] = []
            if oldDescription != description { changes.append("description: \(oldDescription) → \(description)") }
            if oldRequestID != requestID { changes.append("requestID: \(oldRequestID) → \(requestID)") }
            if oldCompany != company { changes.append("company: \(oldCompany.rawValue) → \(company.rawValue)") }
            
            ProcessingLog.shared.logAction(
                action: "Product Info Updated",
                filename: imageFiles[index].originalFilename,
                result: changes.joined(separator: ", ")
            )
        }
    }
    
    func updateThumbnail(id: UUID, thumbnail: NSImage?) {
        if let index = imageFiles.firstIndex(where: { $0.id == id }) {
            imageFiles[index].thumbnail = thumbnail
        }
    }
    
    func verifyFile(id: UUID, isVerified: Bool) {
        if let index = imageFiles.firstIndex(where: { $0.id == id }) {
            imageFiles[index].isVerified = isVerified
            
            ProcessingLog.shared.logAction(
                action: isVerified ? "File Verified" : "File Unverified",
                filename: imageFiles[index].originalFilename,
                result: isVerified ? "Marked as verified" : "Verification removed"
            )
        }
    }
    
    // MARK: - Batch Operations
    
    func toggleVerifyAllFiles() {
        let allVerified = areAllFilesVerified()
        
        for index in imageFiles.indices {
            imageFiles[index].isVerified = !allVerified
        }
        
        ProcessingLog.shared.logAction(
            action: allVerified ? "Unverify All Files" : "Verify All Files",
            filename: "Batch Operation",
            result: "\(imageFiles.count) files \(allVerified ? "unverified" : "verified")"
        )
    }
    
    func areAllFilesVerified() -> Bool {
        return !imageFiles.isEmpty && imageFiles.allSatisfy { $0.isVerified }
    }
    
    // MARK: - Smart Auto-Fill Features
    
    func autoFillMissingInfo() {
        var patterns: [String: (company: Retailer, requestPattern: String)] = [:]
        var filledCount = 0
        
        // Learn patterns from existing files
        for file in imageFiles where !file.requestID.isEmpty && !file.description.isEmpty {
            let key = file.company.rawValue
            if patterns[key] == nil {
                let pattern = extractRequestPattern(file.requestID)
                patterns[key] = (file.company, pattern)
            }
        }
        
        // Apply patterns to incomplete files
        for index in imageFiles.indices {
            let file = imageFiles[index]
            var wasUpdated = false
            
            // Auto-detect company and info if missing
            if file.description.isEmpty || file.requestID.isEmpty {
                let detectedInfo = smartParseFilename(file.originalFilename, using: patterns)
                
                if !detectedInfo.description.isEmpty && file.description.isEmpty {
                    imageFiles[index].description = detectedInfo.description
                    wasUpdated = true
                }
                
                if !detectedInfo.requestID.isEmpty && file.requestID.isEmpty {
                    imageFiles[index].requestID = detectedInfo.requestID
                    wasUpdated = true
                }
                
                if detectedInfo.company != file.company {
                    imageFiles[index].company = detectedInfo.company
                    wasUpdated = true
                }
                
                if wasUpdated {
                    filledCount += 1
                    
                    // Regenerate filename
                    imageFiles[index].newFilename = ImageFile.generateNewFilename(
                        description: imageFiles[index].description,
                        requestID: imageFiles[index].requestID,
                        company: imageFiles[index].company,
                        sequence: imageFiles[index].sequence,
                        isRetouched: imageFiles[index].isRetouched,
                        imageType: imageFiles[index].imageType,
                        originalExtension: imageFiles[index].originalExtension
                    )
                }
            }
        }
        
        ProcessingLog.shared.logAction(
            action: "Auto-Fill Applied",
            filename: "Batch Operation",
            result: "Applied smart patterns to \(filledCount) of \(imageFiles.count) files"
        )
    }
    
    private func extractRequestPattern(_ requestID: String) -> String {
        if requestID.hasPrefix("MO") {
            return "MO"
        } else if requestID.hasPrefix("PH") {
            return "PH"
        }
        return ""
    }
    
    private func smartParseFilename(_ filename: String, using patterns: [String: (company: Retailer, requestPattern: String)]) -> (description: String, requestID: String, company: Retailer) {
        // Enhanced parsing with learned patterns
        let result = ImageFile.parseFilename(filename, imageType: .lifestyle)
        
        // If we found a request ID, use it to determine company
        if !result.requestID.isEmpty {
            return (result.description, result.requestID, result.company)
        }
        
        // Try to match against learned patterns
        for (_, pattern) in patterns {
            if filename.lowercased().contains(pattern.requestPattern.lowercased()) {
                return (result.description, result.requestID, pattern.company)
            }
        }
        
        return (result.description, result.requestID, result.company)
    }
    
    // MARK: - Bulk Operations
    
    func duplicateFiles(_ fileIds: [UUID]) {
        var duplicatedCount = 0
        
        for id in fileIds {
            if let original = imageFiles.first(where: { $0.id == id }) {
                var duplicate = ImageFile(url: original.originalURL, initialType: original.imageType)
                duplicate.description = original.description.isEmpty ? "" : original.description + "_copy"
                duplicate.requestID = original.requestID
                duplicate.company = original.company
                duplicate.sequence = original.sequence
                imageFiles.append(duplicate)
                duplicatedCount += 1
            }
        }
        
        if duplicatedCount > 0 {
            ProcessingLog.shared.logAction(
                action: "Files Duplicated",
                filename: "Batch Operation",
                result: "Created \(duplicatedCount) duplicate files"
            )
            
            saveAppState()
        }
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "defaultBatchType": selectedBatchType?.rawValue ?? "",
            "destinationPath": baseDestinationPath,
            "username": username,
            "timestamp": currentDateTime,
            "version": "1.0"
        ]
    }
    
    func importSettings(_ settings: [String: Any]) {
        if let batchType = settings["defaultBatchType"] as? String {
            selectedBatchType = ImageType.allCases.first { $0.rawValue == batchType }
        }
        if let path = settings["destinationPath"] as? String, !path.isEmpty {
            baseDestinationPath = path
        }
        
        ProcessingLog.shared.logAction(
            action: "Settings Imported",
            filename: "Application",
            result: "Applied imported configuration settings"
        )
    }
    
    // MARK: - Statistics and Analytics
    
    func getProcessingStats() -> (totalFiles: Int, verified: Int, byType: [ImageType: Int], byCompany: [Retailer: Int]) {
        let totalFiles = imageFiles.count
        let verified = imageFiles.filter { $0.isVerified }.count
        
        var byType: [ImageType: Int] = [:]
        var byCompany: [Retailer: Int] = [:]
        
        for file in imageFiles {
            byType[file.imageType, default: 0] += 1
            byCompany[file.company, default: 0] += 1
        }
        
        return (totalFiles, verified, byType, byCompany)
    }
    
    func getValidationReport() -> [String] {
        var issues: [String] = []
        
        for file in imageFiles {
            if file.description.isEmpty {
                issues.append("\(file.originalFilename): Missing description")
            }
            if file.requestID.isEmpty {
                issues.append("\(file.originalFilename): Missing request ID")
            }
            if file.newFilename.isEmpty {
                issues.append("\(file.originalFilename): Cannot generate valid filename")
            }
        }
        
        return issues
    }
    
    // MARK: - Helper method to update processing errors
    
    private func updateProcessingError(fileId: UUID, error: String) {
        if let index = imageFiles.firstIndex(where: { $0.id == fileId }) {
            imageFiles[index].processingError = error
        }
    }
    
    // MARK: - Enhanced File Processing
    
    func processFiles() {
        guard !baseDestinationPath.isEmpty else {
            showError("Please select a destination folder first.")
            return
        }
        
        guard !imageFiles.isEmpty else {
            showError("No files to process.")
            return
        }
        
        // Validate files before processing
        let validationIssues = getValidationReport()
        if validationIssues.count > imageFiles.count / 2 { // If more than 50% have issues
            showError("Too many files have validation issues. Please review and fix before processing.")
            return
        }
        
        isProcessing = true
        processingProgress = 0
        processingSpeed = 0
        estimatedTimeRemaining = 0
        processingMessage = "Initializing file processing..."
        processingStartTime = Date()
        lastProgressUpdate = Date()
        filesProcessedSinceLastUpdate = 0
        
        // Create a copy of the files array to work with in the background
        let filesToProcess = imageFiles
        
        Task {
            let fileManager = FileManager.default
            var successCount = 0
            var errorCount = 0
            var errorResults: [(UUID, String)] = []
            let startTime = Date()
            
            for (index, file) in filesToProcess.enumerated() {
                // Update UI progress on main actor
                await MainActor.run {
                    let progress = Double(index) / Double(filesToProcess.count)
                    processingProgress = progress
                    processingMessage = "Processing \(file.originalFilename)... (\(index + 1)/\(filesToProcess.count))"
                    
                    // Calculate processing speed and ETA
                    let elapsed = Date().timeIntervalSince(startTime)
                    if elapsed > 1.0 { // Only calculate after 1 second
                        processingSpeed = Double(index) / elapsed
                        let remaining = filesToProcess.count - index
                        estimatedTimeRemaining = processingSpeed > 0 ? Double(remaining) / processingSpeed : 0
                    }
                }
                
                do {
                    // Skip files with missing critical info
                    if file.newFilename.isEmpty {
                        errorResults.append((file.id, "Cannot generate valid filename - missing required information"))
                        errorCount += 1
                        continue
                    }
                    
                    // Create destination directory if needed
                    let destinationDir = URL(fileURLWithPath: baseDestinationPath).appendingPathComponent(file.destinationFolder)
                    try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
                    
                    // Copy file with new name
                    let destinationURL = destinationDir.appendingPathComponent(file.newFilename)
                    
                    // Handle existing files
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        // Create backup name if file exists
                        let nameWithoutExt = (file.newFilename as NSString).deletingPathExtension
                        let ext = (file.newFilename as NSString).pathExtension
                        let backupName = "\(nameWithoutExt)_\(Int(Date().timeIntervalSince1970)).\(ext)"
                        let backupURL = destinationDir.appendingPathComponent(backupName)
                        
                        try fileManager.copyItem(at: file.originalURL, to: backupURL)
                        
                        ProcessingLog.shared.logAction(
                            action: "File Processed (Renamed)",
                            filename: file.originalFilename,
                            result: "Copied to \(backupURL.path) (original name existed)"
                        )
                    } else {
                        try fileManager.copyItem(at: file.originalURL, to: destinationURL)
                        
                        ProcessingLog.shared.logAction(
                            action: "File Processed",
                            filename: file.originalFilename,
                            result: "Copied to \(destinationURL.path)"
                        )
                    }
                    
                    successCount += 1
                    
                } catch {
                    // Store error info for later UI update
                    errorResults.append((file.id, error.localizedDescription))
                    
                    ProcessingLog.shared.logAction(
                        action: "File Processing Error",
                        filename: file.originalFilename,
                        result: "Error: \(error.localizedDescription)"
                    )
                    
                    errorCount += 1
                }
                
                // Brief pause to keep UI responsive
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
            
            // Update UI with final results on main actor
            await MainActor.run {
                // Apply all error updates at once
                for (fileId, errorMessage) in errorResults {
                    updateProcessingError(fileId: fileId, error: errorMessage)
                }
                
                isProcessing = false
                processingProgress = 1.0
                processingSpeed = 0
                estimatedTimeRemaining = 0
                
                let totalTime = Date().timeIntervalSince(startTime)
                let avgSpeed = totalTime > 0 ? Double(filesToProcess.count) / totalTime : 0
                
                if errorCount == 0 {
                    processingMessage = "✓ All \(successCount) files processed successfully! (avg: \(String(format: "%.1f", avgSpeed)) files/sec)"
                } else {
                    processingMessage = "⚠ Completed: \(successCount) successful, \(errorCount) errors (avg: \(String(format: "%.1f", avgSpeed)) files/sec)"
                }
                
                // Log final summary
                ProcessingLog.shared.logAction(
                    action: "Processing Complete",
                    filename: "Batch Operation",
                    result: "Processed \(successCount) files successfully, \(errorCount) errors in \(String(format: "%.1f", totalTime)) seconds"
                )
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        
        ProcessingLog.shared.logAction(
            action: "Error",
            filename: "Application",
            result: message
        )
    }
    
    // MARK: - Utility Methods
    
    func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.0f sec", seconds)
        } else if seconds < 3600 {
            return String(format: "%.1f min", seconds / 60)
        } else {
            return String(format: "%.1f hr", seconds / 3600)
        }
    }
    
    func getMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            return String(format: "%.1f MB", usedMB)
        } else {
            return "Unknown"
        }
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Performance monitoring imports
import Darwin.Mach
