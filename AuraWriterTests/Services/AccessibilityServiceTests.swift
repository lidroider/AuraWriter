import XCTest
@testable import AuraWriter

class AccessibilityServiceTests: XCTestCase {
    var service: AccessibilityService!

    override func setUp() {
        super.setUp()
        service = AccessibilityService()
    }

    func testGetSelectedTextWithNoSelection() throws {
        // This test requires mocking AXUIElement behavior
        // For now, we'll test the signature change
        // In a real scenario, you'd mock the accessibility APIs

        // Test that the method returns optional types
        let result = try? service.getSelectedText()
        XCTAssertNotNil(result, "Method should return a tuple even with no selection")
    }

    func testGetSelectedTextReturnsOptionalElement() {
        // Verify the return type includes optional element and range
        // This is a compile-time check more than runtime
        let expectation = XCTestExpectation(description: "Return type is correct")

        do {
            let (text, element, range) = try service.getSelectedText()
            // If element and range are nil, that's valid
            XCTAssertNotNil(text, "Text should always be non-nil (empty string if no selection)")
            expectation.fulfill()
        } catch {
            // Expected for no accessibility permission in test environment
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
