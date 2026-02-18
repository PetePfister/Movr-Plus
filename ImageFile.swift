import Foundation
import AppKit

// Extension to help with string manipulation
extension String {
    func deletingPathExtension() -> String {
        return (self as NSString).deletingPathExtension
    }
    
    func lastPathComponent() -> String {
        return (self as NSString).lastPathComponent
    }
}

struct ImageFile: Identifiable {
    let id = UUID()
    let url: URL
    
    // Original file properties
    let originalURL: URL
    let originalFilename: String
    let originalExtension: String
    
    // Parsed metadata from filename
    let parsedCompany: String?
    let parsedItemNumber: String?
    let parsedRequestID: String?
    let parsedSequenceNumber: String?
    
    // Editable fields for the UI
    var description: String
    var requestID: String
    var company: Retailer = .qvc
    var sequence: String
    var isRetouched: Bool = false
    var imageType: ImageType
    var isVerified: Bool = false
    
    // Processing state
    var newFilename: String = ""
    var destinationFolder: String
    var processingError: String?
    var thumbnail: NSImage?
    
    // Current Date and Time in UTC
    private static let currentDateTime = "2025-07-29 15:47:58"
    private static let currentUser = "PetePfister"
    
    // MARK: - Initialization
    
    init(url: URL, initialType: ImageType? = nil) {
        self.url = url
        self.originalURL = url
        self.originalFilename = url.lastPathComponent
        self.originalExtension = url.pathExtension.lowercased()
        
        // Parse the filename using our enhanced parser
        let parsed = Self.parseFilenameInternal(originalFilename)
        self.parsedCompany = parsed.company
        self.parsedItemNumber = parsed.descriptionItemNumber
        self.parsedRequestID = parsed.requestID
        self.parsedSequenceNumber = parsed.sequenceNumber
        
        // Initialize editable fields with parsed values
        self.description = parsed.descriptionItemNumber ?? ""
        self.requestID = parsed.requestID ?? ""
        self.sequence = parsed.sequenceNumber ?? ""
        
        // Set company based on parsed data
        if let parsedCompany = parsed.company {
            if parsedCompany == "QVC" {
                self.company = .qvc
            } else if parsedCompany == "HSN" {
                self.company = .hsn
            }
        }
        
        // Set image type (use provided or default to lifestyle)
        self.imageType = initialType ?? .lifestyle
        
        // Set default destination folder based on image type
        self.destinationFolder = imageType.defaultDestination
        
        // Generate initial filename
        self.newFilename = Self.generateNewFilename(
            description: self.description,
            requestID: self.requestID,
            company: self.company,
            sequence: self.sequence,
            isRetouched: self.isRetouched,
            imageType: self.imageType,
            originalExtension: self.originalExtension
        )
    }
    
    // MARK: - Filename Generation
    
    static func generateNewFilename(
        description: String,
        requestID: String,
        company: Retailer,
        sequence: String,
        isRetouched: Bool,
        imageType: ImageType,
        originalExtension: String
    ) -> String {
        // Return empty string if essential info is missing
        if description.isEmpty || requestID.isEmpty {
            return ""
        }
        
        var components = ["IMG", company.rawValue, "PH", imageType.abbreviation, requestID, description]
        
        // Add sequence number for lifestyle images
        if imageType == .lifestyle && !sequence.isEmpty {
            components.append(sequence)
        }
        
        // Add RT suffix for retouched images
        if isRetouched {
            components.append("RT")
        }
        
        // Join with underscores and add extension
        let basename = components.joined(separator: "_")
        return "\(basename).\(originalExtension)"
    }
    
    // MARK: - Filename Parsing
    
    // Public result struct for external use
    struct FilenameParseResult {
        var description: String = ""
        var requestID: String = ""
        var company: Retailer = .qvc
        var sequenceNumber: String = ""
    }
    
    // Public parsing method for external use
    static func parseFilename(_ filename: String, imageType: ImageType? = nil) -> FilenameParseResult {
        let parsed = parseFilenameInternal(filename)
        var result = FilenameParseResult()
        
        result.description = parsed.descriptionItemNumber ?? ""
        result.requestID = parsed.requestID ?? ""
        
        if let company = parsed.company {
            if company == "QVC" {
                result.company = .qvc
            } else if company == "HSN" {
                result.company = .hsn
            }
        }
        
        result.sequenceNumber = parsed.sequenceNumber ?? ""
        
        return result
    }
    
    // Private structure for internal parsed results
    private struct ParsedFilename {
        var company: String?
        var descriptionItemNumber: String?
        var requestID: String?
        var sequenceNumber: String?
    }
    
    // Internal implementation of the parser
    private static func parseFilenameInternal(_ filename: String) -> ParsedFilename {
        var result = ParsedFilename()
        
        // Strip extension
        let basename = filename.deletingPathExtension()
        let cleanFilename = filename.replacingOccurrences(of: "'", with: "")
        
        // ----- REQUEST ID DETECTION -----
        
        // Match MO/PH request IDs and extract ONLY the base number (before any dash)
        // MO Request IDs - extract just the base MO number without suffixes
        if let moMatch = cleanFilename.range(of: "MO(\\d+)", options: .regularExpression),
           let moDigits = Range(NSRange(moMatch, in: cleanFilename), in: cleanFilename) {
            result.company = "QVC"
            // Extract just the MO + digits without any suffix
            let moRequest = String(cleanFilename[moDigits])
            result.requestID = moRequest
        }
        // PH Request IDs - extract just the base PH number without suffixes
        else if let phMatch = cleanFilename.range(of: "PH(\\d+)", options: .regularExpression),
                let phDigits = Range(NSRange(phMatch, in: cleanFilename), in: cleanFilename) {
            result.company = "HSN"
            // Extract just the PH + digits without any suffix
            let phRequest = String(cleanFilename[phDigits])
            result.requestID = phRequest
        }
        
        // ----- ITEM NUMBER DETECTION -----
        
        // FIRST PRIORITY: QVC-style item numbers (letter prefix followed by digits)
        let qvcItemPattern = "(?<![A-Za-z])([ACEFHJKMQSTV]\\d{6})(?![A-Za-z0-9])"
        let qvcItemRegex = try? NSRegularExpression(pattern: qvcItemPattern, options: [])
        if let qvcItemMatch = qvcItemRegex?.firstMatch(in: cleanFilename, range: NSRange(location: 0, length: cleanFilename.count)),
           let range = Range(qvcItemMatch.range(at: 1), in: cleanFilename) {
            result.descriptionItemNumber = String(cleanFilename[range])
            
            // If company is still unknown, this is likely QVC
            if result.company == nil {
                result.company = "QVC"
            }
        }
        // Handle H-prefixed item number that might appear at the start of the filename
        else if let hItemMatch = cleanFilename.range(of: "^H(\\d{6})", options: .regularExpression) {
            result.descriptionItemNumber = String(cleanFilename[hItemMatch])
            
            if result.company == nil {
                result.company = "QVC"
            }
        }
        // Check for standard H-prefix item number anywhere in the filename
        else if let hItemMatch = cleanFilename.range(of: "(?<![A-Za-z])(H\\d{6})(?![A-Za-z0-9])", options: .regularExpression) {
            result.descriptionItemNumber = String(cleanFilename[hItemMatch])
            
            if result.company == nil {
                result.company = "QVC"
            }
        }
        // Look for H item numbers separated by dashes, underscores, or spaces (H-478461)
        else {
            let pattern = "(?<![A-Za-z])(H)[-_ ]?(\\d{6})(?![A-Za-z0-9])"
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            if let match = regex?.firstMatch(in: cleanFilename, range: NSRange(location: 0, length: cleanFilename.count)) {
                if match.numberOfRanges >= 3,
                   let hRange = Range(match.range(at: 1), in: cleanFilename),
                   let digitsRange = Range(match.range(at: 2), in: cleanFilename) {
                    let h = String(cleanFilename[hRange])
                    let digits = String(cleanFilename[digitsRange])
                    
                    // Combine H + 6 digits
                    result.descriptionItemNumber = "\(h)\(digits)"
                    
                    if result.company == nil {
                        result.company = "QVC"
                    }
                }
            }
        }
        
        // SECOND PRIORITY: If no QVC-style item number found, check TSV patterns
        if result.descriptionItemNumber == nil {
            let hasTSV = cleanFilename.range(of: "TSV", options: [.caseInsensitive]) != nil
            
            if hasTSV {
                // Try to find a 6-digit number after TSV
                let tsvItemRegex = try? NSRegularExpression(pattern: "TSV[^0-9]*(\\d{6})", options: [.caseInsensitive])
                if let tsvMatch = tsvItemRegex?.firstMatch(in: cleanFilename, range: NSRange(location: 0, length: cleanFilename.count)),
                   let range = Range(tsvMatch.range(at: 1), in: cleanFilename) {
                    result.descriptionItemNumber = String(cleanFilename[range])
                }
                // Also look for pattern where item number is before TSV
                else {
                    let preTsvItemRegex = try? NSRegularExpression(pattern: "(\\d{6})[^0-9]*TSV", options: [.caseInsensitive])
                    if let preTsvMatch = preTsvItemRegex?.firstMatch(in: cleanFilename, range: NSRange(location: 0, length: cleanFilename.count)),
                       let range = Range(preTsvMatch.range(at: 1), in: cleanFilename) {
                        result.descriptionItemNumber = String(cleanFilename[range])
                    }
                }
            }
        }
        
        // THIRD PRIORITY: HSN-style numeric item numbers
        if result.descriptionItemNumber == nil {
            // HSN style (for files that begin with numeric identifier)
            var hsnItemNumber: String? = nil
            
            // Check if file starts with an item number
            let startNumberRegex = try? NSRegularExpression(pattern: "^(\\d{6,})(?:_|\\s)", options: [])
            if let startMatch = startNumberRegex?.firstMatch(in: cleanFilename, options: [], range: NSRange(location: 0, length: cleanFilename.count)) {
                if let range = Range(startMatch.range(at: 1), in: cleanFilename) {
                    hsnItemNumber = String(cleanFilename[range])
                }
            }
            
            // Check for embedded item numbers (common in HSN files)
            if hsnItemNumber == nil {
                let embeddedRegex = try? NSRegularExpression(pattern: "(?:_|\\s)(\\d{6,})(?:_|\\s)", options: [])
                if let embeddedMatch = embeddedRegex?.firstMatch(in: cleanFilename, options: [], range: NSRange(location: 0, length: cleanFilename.count)) {
                    if let range = Range(embeddedMatch.range(at: 1), in: cleanFilename) {
                        hsnItemNumber = String(cleanFilename[range])
                    }
                }
            }
            
            result.descriptionItemNumber = hsnItemNumber
        }
        
        // ----- SEQUENCE NUMBER DETECTION -----
        
        // Method 1: Look for numbers at the end of the filename (enhanced)
        let seqAtEndRegex = try? NSRegularExpression(pattern: "(?:_|\\s|-|)(\\d{3,4})$", options: [])
        if let seqMatch = seqAtEndRegex?.firstMatch(in: basename, options: [], range: NSRange(location: 0, length: basename.count)) {
            if let range = Range(seqMatch.range(at: 1), in: basename) {
                result.sequenceNumber = String(basename[range])
            }
        }
        // Method 2: Look for patterns like Ava0220 (word followed by exactly 4 digits at end)
        else if let wordSeqMatch = basename.range(of: "[A-Za-z]+(\\d{4})$", options: .regularExpression),
                let digitRange = basename.range(of: "\\d{4}$", options: .regularExpression) {
            result.sequenceNumber = String(basename[digitRange])
        }
        // Method 3: Look for patterns like Krystal34021
        else if let nameNumMatch = basename.range(of: "[A-Za-z]+(\\d{4,5})$", options: .regularExpression),
                let digitRange = basename.range(of: "\\d{4,5}$", options: .regularExpression) {
            result.sequenceNumber = String(basename[digitRange])
        }
        // Method 4: Month abbreviation followed by digits (like JULY1154)
        else {
            let monthSeqRegex = try? NSRegularExpression(pattern: "(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)(\\d{3,4})$", options: [.caseInsensitive])
            if let monthMatch = monthSeqRegex?.firstMatch(in: basename, options: [], range: NSRange(location: 0, length: basename.count)) {
                if let range = Range(monthMatch.range(at: 2), in: basename) {
                    result.sequenceNumber = String(basename[range])
                }
            }
        }
        
        return result
    }
}

// MARK: - Helpers for batch processing
extension ImageFile {
    // Group files by their item numbers
    static func groupByItemNumber(_ files: [ImageFile]) -> [String: [ImageFile]] {
        var grouped = [String: [ImageFile]]()
        
        for file in files {
            if !file.description.isEmpty {
                if grouped[file.description] == nil {
                    grouped[file.description] = [file]
                } else {
                    grouped[file.description]!.append(file)
                }
            } else {
                // Group files with unknown item numbers under a special key
                let key = "Unknown"
                if grouped[key] == nil {
                    grouped[key] = [file]
                } else {
                    grouped[key]!.append(file)
                }
            }
        }
        
        return grouped
    }
    
    // Sort files by sequence number when available
    static func sortBySequence(_ files: [ImageFile]) -> [ImageFile] {
        return files.sorted { file1, file2 in
            // If both have sequence numbers, sort numerically
            if !file1.sequence.isEmpty && !file2.sequence.isEmpty,
               let num1 = Int(file1.sequence), let num2 = Int(file2.sequence) {
                return num1 < num2
            }
            
            // If only one has a sequence number, prioritize that one
            if !file1.sequence.isEmpty && file2.sequence.isEmpty {
                return true
            }
            if file1.sequence.isEmpty && !file2.sequence.isEmpty {
                return false
            }
            
            // Fall back to filename sorting
            return file1.originalFilename < file2.originalFilename
        }
    }
    
    // MARK: - New Workflow Helpers
    
    // Check if filename ends with _R suffix (before extension)
    func hasRSuffix() -> Bool {
        let nameWithoutExt = originalFilename.deletingPathExtension()
        return nameWithoutExt.hasSuffix("_R")
    }
    
    // Add _R suffix to filename (before extension)
    // Note: This checks for existing _R suffix to avoid duplicates
    func addRSuffix(_ filename: String) -> String {
        let nameWithoutExt = filename.deletingPathExtension()
        
        // Check if already has _R suffix
        if nameWithoutExt.hasSuffix("_R") {
            return filename // Already has _R, return as-is
        }
        
        let ext = (filename as NSString).pathExtension
        return "\(nameWithoutExt)_R.\(ext)"
    }
    
    // Extract camera count (last underscore-separated numeric sequence before extension)
    // This looks for numeric sequences separated by underscores
    // Examples: "H123456_ABC_102.jpg" -> "102", "file_005.jpg" -> "005"
    // Returns nil if no numeric sequence is found
    func extractCameraCount() -> String? {
        let nameWithoutExt = originalFilename.deletingPathExtension()
        
        // First try: Look for _R suffix and extract digits before it
        if nameWithoutExt.hasSuffix("_R") {
            let withoutR = String(nameWithoutExt.dropLast(2))
            // Look for last underscore-separated numeric sequence
            let components = withoutR.split(separator: "_")
            if let lastComponent = components.last,
               lastComponent.allSatisfy({ $0.isNumber }) {
                return String(lastComponent)
            }
        }
        
        // Second try: Look for last underscore-separated numeric sequence
        let components = nameWithoutExt.split(separator: "_")
        for component in components.reversed() {
            if component.allSatisfy({ $0.isNumber }) {
                return String(component)
            }
        }
        
        return nil
    }
    
    // Generate YYMM date format from current date
    static func getCurrentYYMM() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMM"
        return formatter.string(from: Date())
    }
    
    // Auto-detect category based on item number first letter
    func autoCategoryFromItemNumber() -> String? {
        guard !description.isEmpty else { return nil }
        
        let firstChar = description.prefix(1).uppercased()
        
        if firstChar == "H" || firstChar == "M" {
            return "HO"
        } else if firstChar == "K" {
            return "QC"
        }
        
        // For other cases, return nil to prompt user
        return nil
    }
    
    // Get first letter of item number for archive path
    func getFirstLetterOfItemNumber() -> String? {
        guard !description.isEmpty else { return nil }
        return String(description.prefix(1).uppercased())
    }
    
    // Get last two digits of item number for archive path
    func getLastTwoDigitsOfItemNumber() -> String? {
        guard !description.isEmpty else { return nil }
        
        // Extract just the numeric portion from the end
        let digits = description.filter { $0.isNumber }
        guard digits.count >= 2 else { return nil }
        
        return String(digits.suffix(2))
    }
}
