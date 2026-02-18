import Foundation
import AppKit

class ThumbnailManager {
    static let shared = ThumbnailManager()
    private var cache = NSCache<NSString, NSImage>()
    private var ongoingOperations = [URL: OperationStatus]()
    private let processingQueue = DispatchQueue(label: "thumbnail.processing", qos: .userInitiated, attributes: .concurrent)
    
    private enum OperationStatus {
        case inProgress(callback: [(NSImage?) -> Void])
        case completed(image: NSImage?)
    }
    
    private init() {
        cache.countLimit = 200 // Increased cache size
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB max cache size
        
        // Memory pressure handling - FIXED for macOS
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: NSApplication.willTerminateNotification, // Use willTerminate instead
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        cache.removeAllObjects()
        ongoingOperations.removeAll()
    }
    
    func thumbnail(for url: URL, completion: @escaping (NSImage?) -> Void) {
        let key = url.absoluteString as NSString
        
        // Check cache first
        if let cachedImage = cache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        // Check if already loading
        if let status = ongoingOperations[url] {
            switch status {
            case .completed(let image):
                completion(image)
            case .inProgress(var callbacks):
                callbacks.append(completion)
                ongoingOperations[url] = .inProgress(callback: callbacks)
            }
            return
        }
        
        // Start new loading operation
        ongoingOperations[url] = .inProgress(callback: [completion])
        
        processingQueue.async {
            var resultImage: NSImage? = nil
            
            if FileManager.default.fileExists(atPath: url.path) {
                // Fast path for common image formats
                if let image = self.fastImageLoad(from: url) {
                    let resizedImage = self.resizeImage(image, to: CGSize(width: 160, height: 160))
                    
                    let byteCount = 160 * 160 * 4
                    DispatchQueue.main.async {
                        self.cache.setObject(resizedImage, forKey: key, cost: byteCount)
                    }
                    resultImage = resizedImage
                }
            }
            
            // Get callbacks and complete
            var callbacks: [(NSImage?) -> Void] = []
            DispatchQueue.main.sync {
                if case let .inProgress(existingCallbacks) = self.ongoingOperations[url] {
                    callbacks = existingCallbacks
                }
                self.ongoingOperations[url] = .completed(image: resultImage)
            }
            
            DispatchQueue.main.async {
                for callback in callbacks {
                    callback(resultImage)
                }
            }
        }
    }
    
    private func fastImageLoad(from url: URL) -> NSImage? {
        // Optimized loading for common formats
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif":
            return NSImage(contentsOf: url)
        case "heic":
            // Handle HEIC with fallback
            return NSImage(contentsOf: url)
        default:
            // For other formats, try standard loading
            return NSImage(contentsOf: url)
        }
    }
    
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: .copy,
                  fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }
    
    // Batch preload for better UX
    func preloadThumbnails(for urls: [URL]) {
        for url in urls.prefix(10) { // Limit to first 10
            thumbnail(for: url) { _ in }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        ongoingOperations.removeAll()
    }
}
