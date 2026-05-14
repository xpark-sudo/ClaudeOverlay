import AppKit

final class TerminalRouter {
    static let shared = TerminalRouter()

    func jump(to session: SessionSnapshot) {
        // VS Code: use URL scheme to open the project
        if session.terminalType == "VSCode" {
            let encoded = session.cwd.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? session.cwd
            if let url = URL(string: "vscode://file/\(encoded)") {
                NSWorkspace.shared.open(url)
            }
            return
        }

        // Generic: activate the terminal app by PID
        if session.terminalAppPID > 0,
           let app = NSRunningApplication(processIdentifier: pid_t(session.terminalAppPID)) {
            app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }

        // Fallback: try known terminals
        let terminals = ["com.googlecode.iterm2", "com.apple.Terminal"]
        for bid in terminals {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: url, configuration: config)
                return
            }
        }
    }
}
