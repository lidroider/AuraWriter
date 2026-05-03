import XCTest
import AppKit
@testable import AuraWriter

final class RevertStateTests: XCTestCase {
    func testIsExpiredReturnsFalseForRecentState() {
        let app = NSRunningApplication.current
        let state = RevertState(
            originalText: "test",
            replacedRange: NSRange(location: 0, length: 4),
            targetApp: app,
            timestamp: Date()
        )

        XCTAssertFalse(state.isExpired)
    }

    func testIsExpiredReturnsTrueForOldState() {
        let app = NSRunningApplication.current
        let oldTimestamp = Date().addingTimeInterval(-301) // 301 seconds ago
        let state = RevertState(
            originalText: "test",
            replacedRange: NSRange(location: 0, length: 4),
            targetApp: app,
            timestamp: oldTimestamp
        )

        XCTAssertTrue(state.isExpired)
    }

    func testIsExpiredReturnsFalseAtExactly5Minutes() {
        let app = NSRunningApplication.current
        let timestamp = Date().addingTimeInterval(-300) // Exactly 300 seconds
        let state = RevertState(
            originalText: "test",
            replacedRange: NSRange(location: 0, length: 4),
            targetApp: app,
            timestamp: timestamp
        )

        XCTAssertFalse(state.isExpired)
    }
}
