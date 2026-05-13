import AppKit
import SwiftUI
import Combine
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: OverlayWindow?
    private var monitor: StatusFileMonitor?
    private var hotkey: HotkeyManager?
    private var subs = Set<AnyCancellable>()
    private var hadWaiting = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance enforcement via PID file
        if !Self.acquireSingletonLock() {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)

        let m = StatusFileMonitor()
        self.monitor = m
        m.start()

        let contentView = ContentView(monitor: m)

        let host = NSHostingView(rootView: contentView)

        let w = OverlayWindow(hostingView: host)
        self.window = w
        w.moveToCorner()
        w.orderFrontRegardless()

        setupHotkey()
        observeSessions(m)
        requestNotificationPermission()
        AppSettings.shared.ensureDirectoriesExist()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkey?.unregister()
        monitor?.stop()
        Self.releaseSingletonLock()
    }

    // MARK: - Singleton lock

    private static let pidFile = "/tmp/claude-overlay.pid"

    private static func acquireSingletonLock() -> Bool {
        let pidStr = "\(ProcessInfo.processInfo.processIdentifier)\n"
        let url = URL(fileURLWithPath: pidFile)

        // Try atomic creation first (O_EXCL semantics)
        do {
            try pidStr.data(using: .utf8)!.write(to: url, options: .withoutOverwriting)
            return true
        } catch {
            // File exists — check if it's stale
            if let data = try? Data(contentsOf: url),
               let pidStr2 = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let pid = Int32(pidStr2),
               pid > 0,
               kill(pid, 0) == 0 {
                // Another instance is alive
                return false
            }
            // Stale PID — remove and retry once
            try? FileManager.default.removeItem(atPath: pidFile)
            do {
                try pidStr.data(using: .utf8)!.write(to: url, options: .withoutOverwriting)
                return true
            } catch {
                return false
            }
        }
    }

    private static func releaseSingletonLock() {
        try? FileManager.default.removeItem(atPath: pidFile)
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkey = HotkeyManager { [weak self] in self?.toggle() }
        hotkey?.register()
    }

    // MARK: - Session observation

    private func observeSessions(_ m: StatusFileMonitor) {
        m.$summary
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in
                guard let self = self else { return }
                if s.total > 0, self.window?.isVisible == false {
                    self.show()
                }
                if s.waiting > 0, !self.hadWaiting {
                    self.sendNotification(count: s.waiting)
                }
                self.hadWaiting = s.waiting > 0
            }
            .store(in: &subs)
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendNotification(count: Int) {
        let c = UNMutableNotificationContent()
        c.title = "ClaudeOverlay"
        c.body = "\(count) session(s) need your attention"
        c.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    // MARK: - Show / Hide

    func toggle() { window?.isVisible == true ? hide() : show() }

    func show() {
        window?.moveToCorner()
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }
}
