# Editable Text Input for Translation Dialog

**Date:** 2026-05-04  
**Status:** Approved

## Overview

Replace the current error alert when no text is selected with an editable text input dialog. Users can now invoke the translation shortcut without pre-selecting text and manually input text for translation. When text is pre-selected, users can edit it before rewriting.

## Current Behavior

- User presses keyboard shortcut without selected text → error alert appears
- User presses keyboard shortcut with selected text → dialog shows read-only text preview
- No way to manually input text for translation
- No way to edit pre-selected text before rewriting

## New Behavior

- User presses keyboard shortcut without selected text → dialog opens with empty, focused text field
- User presses keyboard shortcut with selected text → dialog opens with editable text field pre-filled with selection
- Users can type, paste, or edit text in all cases
- "Rewrite" button is disabled when text field is empty

## Architecture

### Component Changes

**1. AccessibilityService**

Modify `getSelectedText()` signature and behavior:

```swift
func getSelectedText() throws -> (text: String, element: AXUIElement?, range: CFRange?)
```

- Return optional `element` and `range` instead of always requiring them
- When no text is selected (range.length == 0), return `("", nil, nil)` instead of throwing `AccessibilityError.noSelectedText`
- Keep throwing errors only for: permission denied, no focused element
- This allows the dialog to open even when nothing is selected

**2. PopupContentView**

Replace read-only text preview with editable TextEditor:

- Add `@State private var editableText: String` initialized from `selectedText` parameter
- Add `@FocusState private var isTextFieldFocused: Bool` for focus management
- Replace `ScrollView { Text(selectedText) }` with `TextEditor(text: $editableText)`
- Add placeholder overlay when `editableText.isEmpty`: "Enter text to translate..."
- Set `.focused($isTextFieldFocused)` and initialize to `true` in `.onAppear`
- Update "Rewrite" button: `.disabled(editableText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)`
- Pass `editableText` to `onRewrite` callback instead of `selectedText`

**3. AppDelegate**

Update keyboard shortcut handling:

- Modify `handleKeyboardShortcut()` to handle new optional return values from `getSelectedText()`
- Update `showPopup()` signature: `showPopup(selectedText: String, element: AXUIElement?, range: CFRange?)`
- Update `performRewrite()` signature: `performRewrite(agent: Agent, element: AXUIElement?, range: CFRange?, originalText: String)`
- When `element` and `range` are nil, copy rewritten text to clipboard and show notification instead of replacing text

## Data Flow

### Flow 1: Pre-selected Text (Existing Use Case)

1. User selects "Hello" in any app → presses shortcut
2. `AccessibilityService.getSelectedText()` returns `("Hello", textFieldElement, CFRange(0,5))`
3. Dialog opens with TextEditor showing "Hello" (editable)
4. User edits to "Hello world" → clicks "Rewrite"
5. API processes "Hello world" → returns rewritten text
6. `AccessibilityService.replaceSelectedText()` replaces text at original range

### Flow 2: No Selection (New Use Case)

1. User presses shortcut with no text selected
2. `AccessibilityService.getSelectedText()` returns `("", nil, nil)`
3. Dialog opens with empty, focused TextEditor
4. User types "Hello world" → clicks "Rewrite"
5. API processes "Hello world" → returns rewritten text
6. Since `element` is nil, copy result to clipboard and show notification: "Rewritten text copied to clipboard"

### Flow 3: User Clears Text (Edge Case)

1. Dialog opens (with or without pre-selection)
2. User deletes all text in TextEditor
3. "Rewrite" button becomes disabled
4. User must type something or cancel

## UI Changes

### Before
```
┌─────────────────────────────────────┐
│ AuraWriter - Rewrite Text        ✕ │
├─────────────────────────────────────┤
│ Selected Text                       │
│ ┌─────────────────────────────────┐ │
│ │ Hello world (read-only)         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Agent: [Translator ▼]               │
│                                     │
│           [Cancel]  [Rewrite]       │
└─────────────────────────────────────┘
```

### After (with selection)
```
┌─────────────────────────────────────┐
│ AuraWriter - Rewrite Text        ✕ │
├─────────────────────────────────────┤
│ Text to Rewrite                     │
│ ┌─────────────────────────────────┐ │
│ │ Hello world█ (editable)         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Agent: [Translator ▼]               │
│                                     │
│           [Cancel]  [Rewrite]       │
└─────────────────────────────────────┘
```

### After (no selection)
```
┌─────────────────────────────────────┐
│ AuraWriter - Rewrite Text        ✕ │
├─────────────────────────────────────┤
│ Text to Rewrite                     │
│ ┌─────────────────────────────────┐ │
│ │ Enter text to translate...█     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Agent: [Translator ▼]               │
│                                     │
│           [Cancel]  [Rewrite]       │
└─────────────────────────────────────┘
```

## Error Handling

### API Failure After User Input
- Show error alert but keep dialog open
- Preserve user's text in TextEditor so they don't lose their input
- Allow retry or cancel

### Clipboard Fallback
- When no target element exists (no selection case), copy result to clipboard
- Show notification: "Rewritten text copied to clipboard"
- Close dialog after successful copy

### Empty Text Submission
- "Rewrite" button disabled when text is empty or whitespace-only
- Enter key does nothing when button is disabled
- User must type text or cancel

## Testing Strategy

### Manual Test Cases

**Test 1: No selection case**
- Press shortcut with no text selected
- Verify dialog opens with empty TextEditor
- Verify TextEditor is focused (cursor visible, can type immediately)
- Verify placeholder text "Enter text to translate..." is visible
- Type "Hello world"
- Verify "Rewrite" button is enabled
- Click "Rewrite"
- Verify API call succeeds
- Verify rewritten text is copied to clipboard
- Verify notification appears

**Test 2: Pre-selected text case**
- Select "Hello" in any app
- Press shortcut
- Verify dialog shows "Hello" in editable TextEditor
- Edit to "Hello world"
- Click "Rewrite"
- Verify rewritten text replaces original selection in target app

**Test 3: Empty text validation**
- Open dialog (any method)
- Clear all text in TextEditor
- Verify "Rewrite" button is disabled
- Verify pressing Enter does nothing
- Type text
- Verify "Rewrite" button becomes enabled

**Test 4: Focus behavior**
- Open dialog with no selection
- Verify can immediately start typing (no click needed)
- Open dialog with selection
- Verify can immediately start editing

**Test 5: Cancel behavior**
- Open dialog, make edits
- Click Cancel
- Verify original text unchanged
- Verify no API calls made

**Test 6: API error handling**
- Open dialog, type text
- Trigger API error (invalid key, network failure)
- Verify error alert appears
- Verify dialog stays open with text preserved
- Verify can retry or cancel

**Test 7: Long text handling**
- Open dialog
- Paste very long text (1000+ characters)
- Verify TextEditor scrolls properly
- Verify can edit and rewrite

## Implementation Notes

### TextEditor Placeholder
SwiftUI's TextEditor doesn't have native placeholder support. Use overlay approach:

```swift
ZStack(alignment: .topLeading) {
    if editableText.isEmpty {
        Text("Enter text to translate...")
            .foregroundColor(.secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
    }
    TextEditor(text: $editableText)
        .focused($isTextFieldFocused)
}
```

### Focus Management
Use `@FocusState` and set focus in `.onAppear`:

```swift
.onAppear {
    isTextFieldFocused = true
}
```

### Clipboard Notification
Use `NSUserNotification` or `UNUserNotificationCenter` for system notification when copying to clipboard.

## Success Criteria

- Users can invoke shortcut without pre-selecting text
- Dialog opens with focused, empty text field in no-selection case
- Users can edit pre-selected text before rewriting
- "Rewrite" button properly disabled for empty text
- Rewritten text goes to clipboard when no target element exists
- No regressions in existing pre-selection workflow
- All manual test cases pass
