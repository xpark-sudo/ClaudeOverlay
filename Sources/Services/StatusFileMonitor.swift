import Foundation
import Combine

final class StatusFileMonitor: ObservableObject {
    @Published var projects: [ProjectSessionInfo] = []
    @Published var summary = StatusSummary()

    private let statusDir = "/tmp/claude-sessions"
    private var timer: Timer?
    private var previousStatuses: [String: SessionStatus] = [:]

    func start() {
        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()

    private func poll() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: statusDir) else { return }

        var loaded: [ProjectSessionInfo] = []
        var w = 0, r = 0, i = 0, d = 0
        let now = Date()

        for file in files where file.hasSuffix(".json") {
            let path = "\(statusDir)/\(file)"
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { continue }
            guard var info = try? Self.decoder.decode(ProjectSessionInfo.self, from: data) else {
                try? fm.removeItem(atPath: path)
                continue
            }

            // Any file older than 30 min → remove (safety net for orphaned sessions)
            if now.timeIntervalSince(info.lastUpdated) > 1800.0 {
                try? fm.removeItem(atPath: path)
                continue
            }

            // idle + stale (>5 min) → remove (session closed)
            if info.status == .idle,
               now.timeIntervalSince(info.lastUpdated) > 300.0 {
                try? fm.removeItem(atPath: path)
                continue
            }

            // completed + stale (>30s) → remove file
            if info.status == .done,
               now.timeIntervalSince(info.lastUpdated) > 30.0 {
                try? fm.removeItem(atPath: path)
                continue
            }

            // running + stale (>5s) → idle
            if info.status == .running,
               now.timeIntervalSince(info.lastUpdated) > 5.0 {
                info.status = .idle
            }

            // Count in same pass
            switch info.status {
            case .waiting: w += 1
            case .running: r += 1
            case .idle:    i += 1
            case .done:    d += 1
            }
            loaded.append(info)
        }

        // Haptic on status change
        let liveIds = Set(loaded.map(\.projectId))
        for p in loaded {
            let prev = previousStatuses[p.projectId]
            if let prev = prev, prev != p.status {
                HapticEngine.shared.statusChanged(to: p.status)
            }
            previousStatuses[p.projectId] = p.status
        }
        // Clean up stale entries
        previousStatuses = previousStatuses.filter { liveIds.contains($0.key) }

        // Sort by priority: waiting → running → idle → done
        loaded.sort { a, b in
            if a.status.priority != b.status.priority {
                return a.status.priority < b.status.priority
            }
            return a.projectName.localizedCaseInsensitiveCompare(b.projectName) == .orderedAscending
        }

        let s = StatusSummary(waiting: w, running: r, idle: i, done: d, total: loaded.count)
        print("[ClaudeOverlay] poll: \(loaded.count) projects, summary: w=\(w) r=\(r) i=\(i) d=\(d)")

        DispatchQueue.main.async {
            self.projects = loaded
            self.summary = s
        }
    }
}

struct StatusSummary: Equatable {
    var waiting: Int = 0
    var running: Int = 0
    var idle: Int = 0
    var done: Int = 0
    var total: Int = 0
}
