import Foundation

struct ConfirmationRequest: Codable, Identifiable, Equatable {
    var id: String { confirmationId }

    let confirmationId: String
    let projectId: String
    let projectName: String
    let question: String
    let options: [String]
    let multiSelect: Bool
    let timestamp: Date
    var status: ResponseStatus
    var answer: String?
}

enum ResponseStatus: String, Codable {
    case pending
    case resolved
    case timeout
}
