import Foundation
import AppKit

struct RevertState {
    let originalText: String
    let replacedRange: NSRange
    let targetApp: NSRunningApplication
    let timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 300 // 5 minutes
    }
}
