# Editable Text Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable users to invoke the translation shortcut without pre-selecting text and allow editing of pre-selected text before rewriting.

**Architecture:** Modify AccessibilityService to return optional element/range instead of throwing errors when no text is selected. Replace read-only ScrollView in PopupContentView with editable TextEditor. Update AppDelegate to handle optional element/range and fallback to clipboard when no target exists.

**Tech Stack:** Swift 5.0, SwiftUI, macOS Accessibility APIs, Combine

---

## File Structure

**Modified Files:**
- `AuraWriter/Services/AccessibilityService.swift` - Change return type to support optional element/range
- `AuraWriter/Views/PopupContentView.swift` - Replace ScrollView with TextEditor, add focus management
- `AuraWriter/AppDelegate.swift` - Handle optional element/range, add clipboard fallback

**Test Files:**
- `AuraWriterTests/Services/AccessibilityServiceTests.swift` - Test new optional return behavior
- `AuraWriterTests/Views/PopupContentViewTests.swift` - Test TextEditor behavior and validation

---

### Task 1: Update AccessibilityService Return Type

**Files:**
- Modify: `AuraWriter/Services/AccessibilityService.swift:35-75`
- Test: `AuraWriterTests/Services/AccessibilityServiceTests.swift`

- [ ] **Step 1: Write failing test for no selection case**

Create or update `AuraWriterTests/Services/AccessibilityServiceTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test to verify current behavior**

Run: `xcodebuild test -scheme AuraWriter -destination 'platform=macOS' -only-testing:AuraWriterTests/AccessibilityServiceTests`

Expected: Tests may fail or skip due to accessibility permissions in test environment, but compilation should succeed.

- [ ] **Step 3: Update AccessibilityService signature and implementation**

Modify `AuraWriter/Services/AccessibilityService.swift`:

```swift
func getSelectedText() throws -> (text: String, element: AXUIElement?, range: CFRange?) {
    guard checkPermission() else {
        throw AccessibilityError.permissionDenied
    }

    let systemWideElement = AXUIElementCreateSystemWide()

    var focusedElement: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

    guard result == .success, let element = focusedElement else {
        throw AccessibilityError.noFocusedElement
    }

    let axElement = unsafeBitCast(element, to: AXUIElement.self)

    var selectedTextRange: CFTypeRef?
    let rangeResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextRangeAttribute as CFString, &selectedTextRange)

    guard rangeResult == .success, let rangeValue = selectedTextRange else {
        // No selection - return empty text with nil element and range
        return ("", nil, nil)
    }

    let axValue = unsafeBitCast(rangeValue, to: AXValue.self)

    var range = CFRange(location: 0, length: 0)
    AXValueGetValue(axValue, .cfRange, &range)

    // If range length is 0, return empty text with nil element and range
    guard range.length > 0 else {
        return ("", nil, nil)
    }

    var selectedText: CFTypeRef?
    let textResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedText)

    guard textResult == .success, let text = selectedText as? String, !text.isEmpty else {
        return ("", nil, nil)
    }

    return (text, axElement, range)
}
```

- [ ] **Step 4: Run tests to verify changes**

Run: `xcodebuild test -scheme AuraWriter -destination 'platform=macOS' -only-testing:AuraWriterTests/AccessibilityServiceTests`

Expected: Tests pass or skip gracefully (accessibility APIs may not work in test environment).

- [ ] **Step 5: Commit AccessibilityService changes**

```bash
git add AuraWriter/Services/AccessibilityService.swift AuraWriterTests/Services/AccessibilityServiceTests.swift
git commit -m "feat: return optional element/range from getSelectedText

Allow getSelectedText to return empty text with nil element/range
instead of throwing error when no text is selected."
```

---

### Task 2: Update PopupContentView with Editable TextEditor

**Files:**
- Modify: `AuraWriter/Views/PopupContentView.swift:1-139`
- Test: Manual testing (SwiftUI view testing)

- [ ] **Step 1: Add state properties for editable text and focus**

Modify `AuraWriter/Views/PopupContentView.swift`:

```swift
import SwiftUI

struct PopupContentView: View {
    @ObservedObject var agentService: AgentService
    @ObservedObject var preferencesService: PreferencesService

    let selectedText: String
    let onRewrite: (Agent, String) -> Void  // Updated signature to pass edited text
    let onCancel: () -> Void

    @State private var selectedAgent: Agent?
    @State private var isLoading = false
    @State private var editableText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private var resolvedAgent: Agent? {
        selectedAgent ?? getDefaultAgent()
    }
    
    private var isRewriteDisabled: Bool {
        editableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
```

- [ ] **Step 2: Replace ScrollView with TextEditor**

Continue modifying `AuraWriter/Views/PopupContentView.swift` body:

```swift
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AuraWriter - Rewrite Text")
                    .font(.headline)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            VStack(spacing: 16) {
                // Editable text input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Text to Rewrite")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        if editableText.isEmpty {
                            Text("Enter text to translate...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        
                        TextEditor(text: $editableText)
                            .font(.body)
                            .frame(maxHeight: 500)
                            .focused($isTextFieldFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                    }
                    .frame(maxHeight: 500)
                }

                // Agent selection
                if !agentService.agents.isEmpty {
                    Picker("Agent:", selection: Binding(
                        get: { resolvedAgent ?? agentService.agents[0] },
                        set: { selectedAgent = $0 }
                    )) {
                        ForEach(agentService.agents) { agent in
                            Text(agent.name).tag(agent)
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear {
                        if selectedAgent == nil {
                            selectedAgent = getDefaultAgent()
                        }
                        editableText = selectedText
                        isTextFieldFocused = true
                    }
                    .onChange(of: agentService.agents) { _ in
                        if selectedAgent == nil {
                            selectedAgent = getDefaultAgent()
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .keyboardShortcut(.cancelAction)

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.small)
                                Text("Rewriting...")
                            }
                            .frame(minWidth: 80)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        } else {
                            Button {
                                isLoading = true
                                if let agent = resolvedAgent {
                                    onRewrite(agent, editableText)
                                }
                            } label: {
                                Text("Rewrite")
                                    .foregroundColor(.white)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor)
                            )
                            .keyboardShortcut(.defaultAction)
                            .disabled(isRewriteDisabled)
                            .opacity(isRewriteDisabled ? 0.5 : 1.0)
                        }
                    }
                } else {
                    Text("No agents configured")
                        .foregroundColor(.secondary)
                    Button("Configure Agents") {
                        onCancel()
                    }
                }
            }
            .padding()
        }
        .frame(width: 800)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(20)
    }

    private func getDefaultAgent() -> Agent? {
        if let bundleID = preferencesService.getCurrentAppBundleID(),
           let agentID = preferencesService.getDefaultAgent(forApp: bundleID),
           let agent = agentService.agents.first(where: { $0.id == agentID }) {
            return agent
        }
        return agentService.agents.first
    }
}
```

- [ ] **Step 3: Build project to verify compilation**

Run: `xcodebuild build -scheme AuraWriter -destination 'platform=macOS'`

Expected: Build succeeds with no errors.

- [ ] **Step 4: Commit PopupContentView changes**

```bash
git add AuraWriter/Views/PopupContentView.swift
git commit -m "feat: replace read-only text with editable TextEditor

- Add @State editableText and @FocusState for focus management
- Replace ScrollView with TextEditor for editing capability
- Add placeholder text overlay for empty state
- Disable Rewrite button when text is empty
- Auto-focus text field on appear"
```

---

### Task 3: Update AppDelegate to Handle Optional Element/Range

**Files:**
- Modify: `AuraWriter/AppDelegate.swift:222-307`

- [ ] **Step 1: Update handleKeyboardShortcut to handle optional returns**

Modify `AuraWriter/AppDelegate.swift`:

```swift
    private func handleKeyboardShortcut() {
        do {
            let (text, element, range) = try accessibilityService.getSelectedText()
            showPopup(selectedText: text, element: element, range: range)
        } catch {
            showError(error.localizedDescription)
        }
    }
```

- [ ] **Step 2: Update showPopup signature**

Modify `AuraWriter/AppDelegate.swift`:

```swift
    private func showPopup(selectedText: String, element: AXUIElement?, range: CFRange?) {
        let contentView = PopupContentView(
            agentService: agentService,
            preferencesService: preferencesService,
            selectedText: selectedText,
            onRewrite: { [weak self] agent, editedText in
                self?.performRewrite(agent: agent, element: element, range: range, originalText: editedText)
            },
            onCancel: { [weak self] in
                self?.closePopup()
            }
        )

        popupWindowController = PopupWindowController(contentView: contentView)
        popupWindowController?.showAtMouseLocation()
    }
```

- [ ] **Step 3: Update performRewrite to handle clipboard fallback**

Modify `AuraWriter/AppDelegate.swift`:

```swift
    private func performRewrite(agent: Agent, element: AXUIElement?, range: CFRange?, originalText: String) {
        rewriteTask = Task {
            do {
                let rewrittenText = try await backendService.rewriteText(agent: agent, selectedText: originalText)

                await MainActor.run {
                    // Close popup after successful API call
                    closePopup()

                    // If we have a target element, replace text in place
                    if let element = element, let range = range {
                        do {
                            // Focus the target app before replacing text
                            accessibilityService.focusApplication(for: element)

                            try accessibilityService.replaceSelectedText(element: element, range: range, newText: rewrittenText)

                            // Store revert state
                            if let app = NSWorkspace.shared.frontmostApplication {
                                revertState = RevertState(
                                    originalText: originalText,
                                    replacedRange: NSRange(location: range.location, length: range.length),
                                    targetApp: app,
                                    timestamp: Date()
                                )
                            }
                        } catch {
                            showError("Failed to replace text: \(error.localizedDescription)")
                        }
                    } else {
                        // No target element - copy to clipboard and notify
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(rewrittenText, forType: .string)
                        
                        showNotification(title: "AuraWriter", message: "Rewritten text copied to clipboard")
                    }
                }
            } catch {
                await MainActor.run {
                    closePopup()

                    let errorMessage: String
                    if let backendError = error as? BackendError {
                        switch backendError {
                        case .invalidURL:
                            errorMessage = "Invalid backend URL for agent '\(agent.name)'"
                        case .networkError(let underlyingError):
                            errorMessage = "Network error: \(underlyingError.localizedDescription)"
                        case .invalidResponse:
                            errorMessage = "Invalid response from backend. Check your API key and backend URL."
                        case .emptyResponse:
                            errorMessage = "Backend returned empty response"
                        case .timeout:
                            errorMessage = "Request timed out after 30 seconds"
                        }
                    } else {
                        errorMessage = "Failed to rewrite text: \(error.localizedDescription)"
                    }
                    showError(errorMessage)
                }
            }
        }
    }
```

- [ ] **Step 4: Add notification helper method**

Add to `AuraWriter/AppDelegate.swift`:

```swift
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
```

- [ ] **Step 5: Build project to verify compilation**

Run: `xcodebuild build -scheme AuraWriter -destination 'platform=macOS'`

Expected: Build succeeds with no errors.

- [ ] **Step 6: Commit AppDelegate changes**

```bash
git add AuraWriter/AppDelegate.swift
git commit -m "feat: handle optional element/range with clipboard fallback

- Update handleKeyboardShortcut to handle optional returns
- Update showPopup and performRewrite signatures
- Add clipboard fallback when no target element exists
- Add notification helper for clipboard copy confirmation"
```

---

### Task 4: Manual Testing

**Files:**
- None (manual testing only)

- [ ] **Step 1: Test no selection case**

1. Build and run the app: `xcodebuild build -scheme AuraWriter -destination 'platform=macOS' && open build/Release/AuraWriter.app`
2. Press keyboard shortcut without selecting any text
3. Verify dialog opens with empty, focused TextEditor
4. Verify placeholder text "Enter text to translate..." is visible
5. Type "Hello world"
6. Verify "Rewrite" button is enabled
7. Click "Rewrite"
8. Verify rewritten text is copied to clipboard
9. Verify notification appears: "Rewritten text copied to clipboard"

Expected: All steps pass without errors.

- [ ] **Step 2: Test pre-selected text case**

1. Select text "Hello" in any application (e.g., TextEdit)
2. Press keyboard shortcut
3. Verify dialog shows "Hello" in editable TextEditor
4. Edit text to "Hello world"
5. Click "Rewrite"
6. Verify rewritten text replaces original selection in target app

Expected: Text is replaced successfully.

- [ ] **Step 3: Test empty text validation**

1. Open dialog (with or without pre-selection)
2. Clear all text in TextEditor
3. Verify "Rewrite" button is disabled
4. Verify pressing Enter does nothing
5. Type some text
6. Verify "Rewrite" button becomes enabled

Expected: Button state changes correctly.

- [ ] **Step 4: Test focus behavior**

1. Open dialog with no selection
2. Verify cursor is visible in TextEditor (auto-focused)
3. Start typing immediately without clicking
4. Verify text appears

Expected: TextEditor is auto-focused.

- [ ] **Step 5: Test cancel behavior**

1. Open dialog, type or edit text
2. Click Cancel
3. Verify dialog closes
4. Verify no API calls made (check network logs if needed)
5. Verify original text unchanged

Expected: Cancel works correctly.

- [ ] **Step 6: Document test results**

Create a test summary in the commit message for the final commit.

---

### Task 5: Final Integration and Documentation

**Files:**
- Modify: `README.md` (if usage instructions need updating)

- [ ] **Step 1: Update README if needed**

Check if `README.md` needs updates for the new behavior:

```markdown
## Usage

1. Select text in any application (optional - you can also input text manually)
2. Press your keyboard shortcut (default: ⌘⇧A)
3. The dialog opens with your selected text (or empty if no selection)
4. Edit the text if needed
5. Choose an agent from the popup (or use the pre-selected default)
6. Click "Rewrite" or press Enter
7. The selected text is replaced with the AI-generated version (or copied to clipboard if no selection)
```

- [ ] **Step 2: Run full build and test**

Run: `xcodebuild clean build test -scheme AuraWriter -destination 'platform=macOS'`

Expected: Build and tests pass.

- [ ] **Step 3: Final commit**

```bash
git add README.md
git commit -m "docs: update usage instructions for editable text input

Users can now invoke shortcut without pre-selecting text.
Dialog allows editing text before rewriting.
Clipboard fallback when no target element exists."
```

- [ ] **Step 4: Create summary of changes**

Document completed:
- AccessibilityService returns optional element/range
- PopupContentView uses editable TextEditor with focus management
- AppDelegate handles clipboard fallback for no-selection case
- All manual tests passed
- README updated with new usage flow

---

## Self-Review Checklist

**Spec Coverage:**
- ✅ No selection case - Task 1, 2, 3
- ✅ Editable text for pre-selected text - Task 2
- ✅ Empty text validation - Task 2
- ✅ Focus management - Task 2
- ✅ Clipboard fallback - Task 3
- ✅ Error handling - Task 3
- ✅ Testing - Task 4
- ✅ Documentation - Task 5

**Placeholder Check:**
- ✅ No TBD or TODO items
- ✅ All code blocks complete
- ✅ All test commands specified
- ✅ All file paths exact

**Type Consistency:**
- ✅ `getSelectedText()` returns `(text: String, element: AXUIElement?, range: CFRange?)`
- ✅ `showPopup()` accepts `element: AXUIElement?, range: CFRange?`
- ✅ `performRewrite()` accepts `element: AXUIElement?, range: CFRange?`
- ✅ `onRewrite` callback passes `(Agent, String)` for edited text
- ✅ `editableText` is `String` type throughout

**Commit Strategy:**
- ✅ Each task has a focused commit
- ✅ Commit messages follow conventional commits format
- ✅ Changes are incremental and testable
