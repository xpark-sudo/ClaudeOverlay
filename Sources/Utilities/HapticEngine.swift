import AppKit

final class HapticEngine {
    static let shared = HapticEngine()

    private let performer = NSHapticFeedbackManager.defaultPerformer

    func statusChanged(to status: SessionStatus) {
        switch status {
        case .waiting:
            performer.perform(.levelChange, performanceTime: .now)
        case .running, .idle:
            performer.perform(.alignment, performanceTime: .now)
        case .done:
            performer.perform(.generic, performanceTime: .now)
        }
    }

    func selectionChanged() {
        performer.perform(.alignment, performanceTime: .now)
    }
}
