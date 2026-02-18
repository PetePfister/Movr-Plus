import Foundation

struct ProcessingLogEntry {
    let timestamp: Date
    let user: String
    let action: String
    let filename: String
    let result: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: timestamp)
    }
}

class ProcessingLog {
    static let shared = ProcessingLog()
    
    private var entries: [ProcessingLogEntry] = []
    private let username: String = "PetePfister" 
    private let currentDateTime: String = "2025-07-28 19:29:55" 
    
    var isEmpty: Bool { entries.isEmpty }
    
    private init() {}
    
    func logAction(action: String, filename: String, result: String) {
        let entry = ProcessingLogEntry(
            timestamp: Date(),
            user: username,
            action: action,
            filename: filename,
            result: result
        )
        entries.append(entry)
    }
    
    func generateLogReport() -> String {
        var report = "Movr Plus Processing Log\n"
        report += "UTC Time: \(currentDateTime)\n"
        report += "User: \(username)\n"
        report += "----------------------------\n\n"
        
        for entry in entries {
            report += "[\(entry.formattedTimestamp)] \(entry.action): \(entry.filename)\n"
            report += "Result: \(entry.result)\n\n"
        }
        
        return report
    }
    
    func saveLogToFile(at url: URL) throws {
        let report = generateLogReport()
        try report.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func clearLog() {
        entries.removeAll()
    }
}