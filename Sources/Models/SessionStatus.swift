import SwiftUI

enum SessionStatus: String, Codable, Equatable {
    case waiting = "needs_confirmation"
    case running = "running"
    case idle = "waiting_input"
    case done = "completed"

    var symbol: String {
        switch self {
        case .waiting: return "\u{25B3}"  // △
        case .running: return "\u{25CF}"  // ●
        case .idle:    return "\u{21A9}"  // ↩
        case .done:    return "\u{2713}"  // ✓
        }
    }

    var color: Color {
        switch self {
        case .waiting: return Color(red: 1.0, green: 0.25, blue: 0.25)   // red
        case .running: return Color(red: 1.0, green: 0.80, blue: 0.15)   // yellow
        case .idle:    return Color.orange                                 // orange
        case .done:    return Color(red: 0.29, green: 0.87, blue: 0.50)  // green
        }
    }

    var rowBg: Color? {
        switch self {
        case .waiting: return Color.red.opacity(0.15)
        case .running: return Color.yellow.opacity(0.10)
        case .idle:    return Color.orange.opacity(0.08)
        case .done:    return nil
        }
    }

    var priority: Int {
        switch self {
        case .waiting: return 0
        case .running: return 1
        case .idle:    return 2
        case .done:    return 3
        }
    }
}
