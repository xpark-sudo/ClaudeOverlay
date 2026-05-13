import Foundation

final class ConfirmationManager {
    static let shared = ConfirmationManager()

    private let responseDir: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/claude_pending_responses"
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()

    func getConfirmation(for projectId: String) -> ConfirmationRequest? {
        let path = "\(responseDir)/\(projectId).json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let request = try? decoder.decode(ConfirmationRequest.self, from: data) else {
            return nil
        }
        return request.status == .pending ? request : nil
    }

    func resolve(request: ConfirmationRequest, answer: String) {
        var resolved = request
        resolved.status = answer.isEmpty ? .timeout : .resolved
        resolved.answer = answer

        let path = "\(responseDir)/\(request.projectId).json"
        if let data = try? encoder.encode(resolved) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
