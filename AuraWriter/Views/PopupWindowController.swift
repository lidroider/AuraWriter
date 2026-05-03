import Cocoa
import SwiftUI

// Custom window that can become key to receive keyboard events
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

class PopupWindowController: NSWindowController {
    convenience init(contentView: some View) {
        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 300),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.hasShadow = true

        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        self.init(window: window)
    }

    func showAtMouseLocation() {
        guard let window = window else { return }

        let screenFrame = NSScreen.main?.frame ?? .zero

        // Golden ratio: 1.618
        let goldenRatio = 1.618

        // Position horizontally centered
        let originX = screenFrame.midX - (window.frame.width / 2)

        // Position vertically using golden ratio from bottom
        // Place window so its center is at the golden ratio point from bottom
        let goldenPoint = screenFrame.minY + (screenFrame.height / (1 + goldenRatio))
        let originY = goldenPoint - (window.frame.height / 2)

        window.setFrameOrigin(NSPoint(x: originX, y: originY))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func close() {
        window?.close()
    }
}
