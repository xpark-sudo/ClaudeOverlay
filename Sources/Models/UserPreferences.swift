import Foundation

struct UserPreferences: Codable {
    enum JumpTarget: String, Codable, CaseIterable {
        case vscode
        case iterm2
    }

    var jumpTarget: JumpTarget = .iterm2
    var launchAtLogin: Bool = false
    var language: String = "en"
}
