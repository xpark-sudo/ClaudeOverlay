import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private let prefsPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let dir = "\(home)/.claude/claude-overlay"
        return "\(dir)/preferences.json"
    }()

    func ensureDirectoriesExist() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let overlayDir = "\(home)/.claude/claude-overlay"
        let responsesDir = "\(home)/.claude/claude_pending_responses"
        let sessionsDir = "/tmp/claude-sessions"

        for dir in [overlayDir, responsesDir, sessionsDir] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
    }

    var preferences: UserPreferences {
        get {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: prefsPath)),
                  let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
                return UserPreferences()
            }
            return prefs
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                try? data.write(to: URL(fileURLWithPath: prefsPath))
            }
        }
    }
}
