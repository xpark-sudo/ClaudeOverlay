import Foundation

struct ProjectSessionInfo: Codable, Identifiable, Equatable {
    var id: String { projectId }

    let projectId: String
    let projectName: String
    let projectPath: String
    var status: SessionStatus
    let lastUpdated: Date
    let terminalType: String
    var hasConfirmation: Bool
    var confirmationId: String?
}
