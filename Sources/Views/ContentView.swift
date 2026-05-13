import SwiftUI

// MARK: - Right-click menu for CC button

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
    var monitor: Any?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] e in
            guard let self = self, let w = self.window, w.isVisible else { return e }
            let loc = self.convert(e.locationInWindow, from: nil)
            if self.bounds.contains(loc) {
                if let m = self.rightClickMenu {
                    NSMenu.popUpContextMenu(m, with: e, for: self)
                }
                return nil
            }
            return e
        }
    }
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
    deinit {
        if let m = monitor { NSEvent.removeMonitor(m) }
    }
}

// MARK: - Click-outside monitor

private struct ClickOutsideHandler: NSViewRepresentable {
    let action: () -> Void
    func makeNSView(context: Context) -> NSView {
        let v = ClickOutsideView(); v.action = action; return v
    }
    func updateNSView(_ v: NSView, context: Context) {
        (v as? ClickOutsideView)?.action = action
    }
}
private final class ClickOutsideView: NSView {
    var action: (() -> Void)?
    var monitor: Any?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] e in
            guard let self = self, let w = self.window, w.isVisible else { return e }
            let loc = e.locationInWindow
            if !w.contentView!.bounds.contains(loc) {
                self.action?()
            }
            return e
        }
    }
    deinit { if let m = monitor { NSEvent.removeMonitor(m) } }
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var monitor: StatusFileMonitor
    @State private var expanded = false

    private let barW: CGFloat = 150
    private let barH: CGFloat = 40
    private let expandW: CGFloat = 220
    private let rowH: CGFloat = 36

    var body: some View {
        let hasWaiting = monitor.summary.waiting > 0
        let barBg = hasWaiting
            ? Color(red: 0.22, green: 0.04, blue: 0.04, opacity: 0.92)
            : Color(red: 0.08, green: 0.08, blue: 0.08, opacity: 0.88)

        VStack(spacing: 0) {
            Spacer()
            // Compact bar
            HStack(spacing: 8) {
                // CC Logo with right-click menu
                ZStack {
                    Button(action: {
                        if monitor.summary.total > 0 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                expanded.toggle()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.6, green: 0.2, blue: 0.9), Color(red: 0.2, green: 0.4, blue: 1.0)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 22, height: 22)
                            Text("CC")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    RightClickMenuView()
                        .frame(width: 22, height: 22)
                }

                // Status symbols — only show non-zero
                if monitor.summary.total > 0 {
                    let items: [(status: SessionStatus, count: Int)] = [
                        (.waiting, monitor.summary.waiting),
                        (.running, monitor.summary.running),
                        (.idle, monitor.summary.idle),
                        (.done, monitor.summary.done),
                    ].filter { $0.count > 0 }
                    ForEach(items, id: \.status.rawValue) { item in
                        HStack(spacing: 2) {
                            Text(item.status.symbol)
                                .font(.system(size: 17, weight: .bold))
                            Text("\(item.count)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(item.status.color)
                    }
                } else {
                    Text("--").font(.system(size: 11)).foregroundColor(.gray.opacity(0.4))
                }

                Spacer()
            }
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .frame(width: barW, height: barH)
            .background(barBg)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)

            // Expanded panel
            if expanded {
                VStack(spacing: 0) {
                    HStack {
                        Text("Claude Code")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Button(action: { withAnimation(.spring()) { expanded = false } }) {
                            Text("\u{00D7}")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: rowH)

                    Divider().background(Color.white.opacity(0.1))

                    if monitor.projects.isEmpty {
                        Text("No active sessions")
                            .font(.system(size: 11)).foregroundColor(.gray)
                            .frame(height: rowH * 2)
                    } else {
                        ForEach(monitor.projects) { p in
                            HStack(spacing: 10) {
                                Text(p.status.symbol)
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundColor(p.status.color)
                                    .frame(width: 22)
                                Text(midTruncate(p.projectName, 14))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Spacer()
                                Text(timeFmt(p.lastUpdated))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: rowH)
                            .background(p.status.rowBg)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                TerminalRouter.shared.jump(to: p)
                            }
                            if p.id != monitor.projects.last?.id {
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(width: expandW)
                .background(Color(red: 0.08, green: 0.08, blue: 0.08, opacity: 0.92))
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                .padding(.top, 6)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .background(ClickOutsideHandler {
            if expanded {
                withAnimation(.spring()) { expanded = false }
            }
        })
    }

    private func midTruncate(_ s: String, _ maxLen: Int) -> String {
        if s.count <= maxLen { return s }
        let half = (maxLen - 3) / 2
        return String(s.prefix(half)) + "..." + String(s.suffix(half))
    }

    private func timeFmt(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDateInToday(d) ? "HH:mm" : "MM-dd HH:mm"
        return f.string(from: d)
    }
}
