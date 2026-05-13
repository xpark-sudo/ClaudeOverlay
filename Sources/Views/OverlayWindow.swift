import AppKit
import SwiftUI

final class OverlayWindow: NSPanel {
    init(hostingView: NSHostingView<ContentView>) {
        super.init(contentRect: NSRect(origin: .zero, size: NSSize(width: 240, height: 500)),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        hasShadow = false
        isReleasedWhenClosed = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        isMovableByWindowBackground = true

        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView
    }

    override var canBecomeKey: Bool { false }

    func moveToCorner() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let r = screen.visibleFrame
        setFrameOrigin(NSPoint(x: r.maxX - frame.width - 16, y: r.minY + 16))
    }
}
