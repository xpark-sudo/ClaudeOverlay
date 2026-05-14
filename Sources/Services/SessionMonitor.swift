import Foundation
import Combine

struct SessionSnapshot: Identifiable, Equatable {
    let id: String
    let pid: Int32
    let cwd: String
    let projectName: String
    var derivedStatus: SessionStatus
    var hasChildren: Bool
    var isAskUserQuestion: Bool
    var lastUpdated: Date
    var terminalType: String
    var terminalAppPID: Int32

    static func == (lhs: SessionSnapshot, rhs: SessionSnapshot) -> Bool {
        lhs.id == rhs.id && lhs.derivedStatus == rhs.derivedStatus
            && lhs.hasChildren == rhs.hasChildren && lhs.projectName == rhs.projectName
    }
}

final class SessionMonitor: ObservableObject {
    @Published var sessions: [SessionSnapshot] = []
    @Published var summary = StatusSummary()

    private let sessionsDir = "\(FileManager.default.homeDirectoryForCurrentUser.path)/.claude/sessions"
    private let projectsDir = "\(FileManager.default.homeDirectoryForCurrentUser.path)/.claude/projects"
    private var timer: Timer?
    private var previousStatuses: [String: SessionStatus] = [:]

    func start() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Poll (background)

    private func poll() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: sessionsDir) else { return }

        let dirs = (sessionsDir, projectsDir)
        let prev = previousStatuses

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let result = Self.processDir(files: files, fm: fm, dirs: dirs, previousStatuses: prev)
            DispatchQueue.main.async {
                let changed = self.sessions != result.sessions || self.summary != result.summary
                guard changed else { return }
                self.sessions = result.sessions
                self.summary = result.summary
                self.previousStatuses = result.newPrev
            }
        }
    }

    private struct PollResult {
        let sessions: [SessionSnapshot]
        let summary: StatusSummary
        let newPrev: [String: SessionStatus]
    }

    private static func processDir(files: [String], fm: FileManager, dirs: (String, String), previousStatuses: [String: SessionStatus]) -> PollResult {
        let (sessionsDir, projectsDir) = dirs
        var loaded: [SessionSnapshot] = []
        var w = 0, r = 0, i = 0
        let now = Date()
        var newPrev = previousStatuses

        for file in files where file.hasSuffix(".json") {
            let path = "\(sessionsDir)/\(file)"
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pid = dict["pid"] as? Int32, pid > 0, kill(pid, 0) == 0,
                  let cwd = dict["cwd"] as? String,
                  let sessionId = dict["sessionId"] as? String,
                  let claudeStatus = dict["status"] as? String else { continue }

            let projectName = (cwd as NSString).lastPathComponent
            let hasChildren = !childPIDs(pid: pid).isEmpty
            let (termType, termAppPID) = detectTerminal(pid: pid)

            let (isAsk, hasPendingTool) = checkTranscript(
                sessionId: sessionId, cwd: cwd, projectsDir: projectsDir
            )

            let derived: SessionStatus
            if isAsk {
                derived = .waiting; w += 1
            } else if hasPendingTool && !hasChildren {
                derived = .waiting; w += 1
            } else if claudeStatus == "idle" {
                derived = .idle; i += 1
            } else {
                derived = .running; r += 1
            }

            // Haptic on change
            let prev = previousStatuses[sessionId]
            if let prev = prev, prev != derived {
                DispatchQueue.main.async { HapticEngine.shared.statusChanged(to: derived) }
            }
            newPrev[sessionId] = derived

            loaded.append(SessionSnapshot(
                id: sessionId, pid: pid, cwd: cwd, projectName: projectName,
                derivedStatus: derived, hasChildren: hasChildren,
                isAskUserQuestion: isAsk, lastUpdated: now,
                terminalType: termType, terminalAppPID: termAppPID
            ))
        }

        loaded.sort { a, b in
            if a.derivedStatus.priority != b.derivedStatus.priority {
                return a.derivedStatus.priority < b.derivedStatus.priority
            }
            return a.projectName.localizedCaseInsensitiveCompare(b.projectName) == .orderedAscending
        }

        let liveIds = Set(loaded.map(\.id))
        newPrev = newPrev.filter { liveIds.contains($0.key) }

        return PollResult(
            sessions: loaded,
            summary: StatusSummary(waiting: w, running: r, idle: i, done: 0, total: loaded.count),
            newPrev: newPrev
        )
    }

    // MARK: - Process tree

    private static func detectTerminal(pid: Int32) -> (String, Int32) {
        var currentPid = pid
        var appPID: Int32 = 0
        for _ in 0..<5 {
            let info = procInfo(pid: currentPid)
            guard info.ppid > 1 else { break }
            let ppid = info.ppid
            let comm = info.comm
            let path = procPath(pid: ppid)

            if comm.contains("iTerm") || path.contains("iTerm") {
                return ("iTerm2", ppid)
            }
            if comm.contains("Code") || comm.contains("Electron") || path.contains("Visual Studio Code") {
                return ("VSCode", ppid)
            }
            if comm.contains("Terminal") || path.contains("Terminal.app") {
                return ("Terminal", ppid)
            }
            if path.contains(".app/") && appPID == 0 {
                appPID = ppid
            }
            currentPid = ppid
        }
        return (appPID > 0 ? "Other" : "Unknown", appPID)
    }

    private static func shell(_ cmd: String, args: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: cmd)
        task.arguments = args
        task.standardOutput = Pipe()
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            if let data = try? (task.standardOutput as? Pipe)?.fileHandleForReading.readToEnd() {
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {}
        return nil
    }

    private static func procInfo(pid: Int32) -> (ppid: Int32, comm: String) {
        guard let str = shell("/bin/ps", args: ["-o", "ppid=,comm=", "-p", "\(pid)"]) else { return (0, "") }
        let parts = str.split(separator: " ", maxSplits: 1)
        if parts.count == 2, let ppid = Int32(parts[0]) { return (ppid, String(parts[1])) }
        return (0, "")
    }

    private static func procPath(pid: Int32) -> String {
        var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let len = proc_pidpath(pid, &path, UInt32(MAXPATHLEN))
        return len > 0 ? String(cString: path) : ""
    }

    // Background processes that don't indicate tool execution
    private static let ignoredProcs: Set<String> = ["caffeinate", "sourcekit-lsp", "claude-lsp"]

    private static func childPIDs(pid: Int32) -> [Int32] {
        guard let str = shell("/usr/bin/pgrep", args: ["-P", "\(pid)"]), !str.isEmpty else { return [] }
        return str.split(separator: "\n").compactMap {
            let cpid = Int32($0.trimmingCharacters(in: .whitespaces))
            guard let cpid = cpid else { return nil }
            // Skip known background daemons
            if let comm = shell("/bin/ps", args: ["-o", "comm=", "-p", "\(cpid)"]) {
                for ignored in ignoredProcs where comm.contains(ignored) { return nil }
            }
            return cpid
        }
    }

    // MARK: - Transcript

    private static func checkTranscript(sessionId: String, cwd: String, projectsDir: String) -> (isAsk: Bool, hasPendingTool: Bool) {
        let slug = cwd.replacingOccurrences(of: "/", with: "-")
        let path = "\(projectsDir)/\(slug)/\(sessionId).jsonl"

        guard let fh = FileHandle(forReadingAtPath: path) else { return (false, false) }
        defer { try? fh.close() }

        let end = fh.seekToEndOfFile()
        fh.seek(toFileOffset: max(0, end - 16384))
        guard let tail = String(data: fh.readDataToEndOfFile(), encoding: .utf8) else { return (false, false) }

        let lines = tail.split(separator: "\n").suffix(50)
        var isAsk = false, hasToolUse = false, hasResult = false

        for line in lines.reversed() {
            guard let data = line.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = dict["type"] as? String else { continue }

            if type == "user", dict["toolUseResult"] != nil { hasResult = true; break }
            if type == "assistant", let msg = dict["message"] as? [String: Any],
               let content = msg["content"] as? [[String: Any]] {
                for block in content where block["type"] as? String == "tool_use" {
                    hasToolUse = true
                    if block["name"] as? String == "AskUserQuestion" { isAsk = true }
                }
                if hasToolUse { break }
            }
        }
        return (isAsk, hasToolUse && !hasResult)
    }
}

struct StatusSummary: Equatable {
    var waiting: Int = 0
    var running: Int = 0
    var idle: Int = 0
    var done: Int = 0
    var total: Int = 0
}
