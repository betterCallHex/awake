import CoreServices
import Foundation

final class ClaudeWatch {
    static let quietPeriod: TimeInterval = 10 * 60
    var onChange: () -> Void = {}
    private(set) var isWorking = false
    private var stream: FSEventStreamRef?
    private var quietTimer: Timer?

    func start() {
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        guard let stream = FSEventStreamCreate(nil, Self.receiveEvents, &context, Self.sessionFolders as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 10, flags) else { return }
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
        self.stream = stream
    }

    private static var sessionFolders: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".claude/projects").path,
            home.appendingPathComponent("Library/Application Support/Claude/local-agent-mode-sessions").path,
        ]
    }

    private static let receiveEvents: FSEventStreamCallback = { _, info, _, paths, _, _ in
        guard let info else { return }
        let watch = Unmanaged<ClaudeWatch>.fromOpaque(info).takeUnretainedValue()
        let changedPaths = Unmanaged<CFArray>.fromOpaque(paths).takeUnretainedValue() as? [String] ?? []
        guard changedPaths.contains(where: isTranscript) else { return }
        watch.sawActivity()
    }

    static func isTranscript(_ path: String) -> Bool {
        path.contains("/.claude/projects/") && path.hasSuffix(".jsonl")
    }

    private func sawActivity() {
        quietTimer?.invalidate()
        quietTimer = Timer.scheduledTimer(withTimeInterval: Self.quietPeriod, repeats: false) { [weak self] _ in self?.wentQuiet() }
        quietTimer?.tolerance = 30
        guard !isWorking else { return }
        isWorking = true
        onChange()
    }

    private func wentQuiet() {
        isWorking = false
        onChange()
    }

    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        quietTimer?.invalidate()
        isWorking = false
    }
}
