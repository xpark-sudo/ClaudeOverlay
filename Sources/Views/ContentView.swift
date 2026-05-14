import SwiftUI

// MARK: - Design

private enum Dim {
    static let barW: CGFloat = 180
    static let expandW: CGFloat = 220
    static let barH: CGFloat = 42
    static let rowH: CGFloat = 38
}

// MARK: - Click Outside

private struct ClickOutsideHandler: NSViewRepresentable {
    let action: () -> Void
    func makeNSView(context: Context) -> NSView { let v = ClickOutsideView(); v.action = action; return v }
    func updateNSView(_ v: NSView, context: Context) { (v as? ClickOutsideView)?.action = action }
}
private final class ClickOutsideView: NSView {
    var action: (() -> Void)?
    private var monitor: Any?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] e in
            guard let self = self, let w = self.window, w.isVisible else { return e }
            if !w.contentView!.bounds.contains(e.locationInWindow) { self.action?() }
            return e
        }
    }
    deinit { if let m = monitor { NSEvent.removeMonitor(m) } }
}

// MARK: - Right Click

private struct RightClickMenuView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = RightClickView()
        v.rightClickMenu = {
            let m = NSMenu()
            m.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            return m
        }()
        return v
    }
    func updateNSView(_ v: NSView, context: Context) {}
}
private final class RightClickView: NSView {
    var rightClickMenu: NSMenu?
    private var monitor: Any?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] e in
            guard let self = self, let w = self.window, w.isVisible else { return e }
            if self.bounds.contains(self.convert(e.locationInWindow, from: nil)) {
                if let m = self.rightClickMenu { NSMenu.popUpContextMenu(m, with: e, for: self) }
                return nil
            }
            return e
        }
    }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    deinit { if let m = monitor { NSEvent.removeMonitor(m) } }
}

// MARK: - Status Dot

private struct StatusDot: View {
    let color: Color
    let pulse: Bool
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.4

    var body: some View {
        ZStack {
            if pulse {
                Circle()
                    .stroke(color.opacity(opacity), lineWidth: 2)
                    .frame(width: 14, height: 14)
                    .scaleEffect(scale)
            }
            Circle().fill(color).frame(width: 7, height: 7)
        }
        .onAppear {
            if pulse {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scale = 1.5; opacity = 0.1
                }
            }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var monitor: SessionMonitor
    @State private var expanded = false

    var body: some View {
        let s = monitor.summary
        let hasWaiting = s.waiting > 0

        // Dynamic bar background
        let barBg: Color = hasWaiting
            ? Color(red: 0.18, green: 0.04, blue: 0.04, opacity: 0.92)
            : Color(red: 0.07, green: 0.07, blue: 0.09, opacity: 0.90)

        VStack(spacing: 0) {
            Spacer()

            // === COMPACT BAR ===
            HStack(spacing: 6) {
                // Logo + toggle
                ZStack {
                    Button(action: {
                        if s.total > 0 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                expanded.toggle()
                            }
                        }
                    }) {
                        Text("CC")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.6)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                            )
                    }
                    .buttonStyle(.plain)
                    RightClickMenuView().frame(width: 24, height: 24)
                }

                // Status indicators — only show non-zero
                if s.total > 0 {
                    let items: [(Color, Bool, Int)] = [
                        (SessionStatus.waiting.color, s.waiting > 0, s.waiting),
                        (SessionStatus.running.color, false, s.running),
                        (SessionStatus.idle.color, false, s.idle),
                    ].filter { $0.2 > 0 }
                    HStack(spacing: 10) {
                        ForEach(0..<items.count, id: \.self) { idx in
                            let item = items[idx]
                            HStack(spacing: 4) {
                                StatusDot(color: item.0, pulse: item.1)
                                Text("\(item.2)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(item.0)
                            }
                        }
                    }
                } else {
                    Text("--")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.35))
                }

                Spacer()

                // Chevron
                if s.total > 0 {
                    Image(systemName: expanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.leading, 8).padding(.trailing, 10)
            .frame(width: Dim.barW, height: Dim.barH)
            .background(barBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(hasWaiting ? 0.12 : 0.05), lineWidth: 0.5)
            )

            // === EXPANDED ===
            if expanded {
                VStack(spacing: 0) {
                    HStack {
                        Text("Claude Code")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Button(action: { withAnimation(.spring()) { expanded = false } }) {
                            Text("—")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: Dim.rowH)

                    Divider().background(Color.white.opacity(0.07))

                    if monitor.sessions.isEmpty {
                        Text("无活跃会话")
                            .font(.system(size: 11)).foregroundColor(.gray)
                            .frame(height: Dim.rowH * 2)
                    } else {
                        ForEach(monitor.sessions) { session in
                            sessionRow(session)
                            if session.id != monitor.sessions.last?.id {
                                Divider().background(Color.white.opacity(0.04)).padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(width: Dim.expandW)
                .background(Color(red: 0.07, green: 0.07, blue: 0.09, opacity: 0.92))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
                .padding(.top, 6)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .background(ClickOutsideHandler {
            if expanded { withAnimation(.spring()) { expanded = false } }
        })
    }

    // MARK: - Row

    private func sessionRow(_ session: SessionSnapshot) -> some View {
        HStack(spacing: 8) {
            // Status dot (with pulse ring when waiting)
            ZStack {
                if session.derivedStatus == .waiting {
                    Circle()
                        .stroke(session.derivedStatus.color.opacity(0.4), lineWidth: 3)
                        .frame(width: 16, height: 16)
                }
                Circle()
                    .fill(session.derivedStatus.color)
                    .frame(width: 8, height: 8)
            }

            // Name
            Text(session.projectName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer()

            // Jump arrow
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .frame(height: Dim.rowH)
        .background(session.derivedStatus.rowBg ?? Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            TerminalRouter.shared.jump(to: session)
        }
    }
}
