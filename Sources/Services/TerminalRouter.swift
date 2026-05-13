import AppKit

final class TerminalRouter {
    static let shared = TerminalRouter()

    func jump(to project: ProjectSessionInfo) {
        let prefs = AppSettings.shared.preferences

        // Respect project's actual terminal type first; fall back to global preference
        let target: UserPreferences.JumpTarget
        switch project.terminalType {
        case "VSCode":
            target = .vscode
        case "iTerm2":
            target = .iterm2
        case "Terminal":
            target = .iterm2 // Terminal.app not yet supported, route to iTerm2
        default:
            target = prefs.jumpTarget
        }

        switch target {
        case .vscode:
            openInVSCode(path: project.projectPath)
        case .iterm2:
            openInITerm2(path: project.projectPath)
        }
    }

    private func openInVSCode(path: String) {
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        if let url = URL(string: "vscode://file/\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openInITerm2(path: String) {
        let escaped = path.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "iTerm"
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if
            tell current session of current window
                write text "cd \(escaped) && clear"
            end tell
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            openITerm2ViaWorkspace()
        }

        if process.terminationStatus != 0 {
            openITerm2ViaWorkspace()
        }
    }

    private func openITerm2ViaWorkspace() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    }
}
