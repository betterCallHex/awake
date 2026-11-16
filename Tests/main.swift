import Foundation

var failures = 0

func expect(_ condition: Bool, _ description: String) {
    guard !condition else { return }
    print("FAIL: \(description)")
    failures += 1
}

expect(Updater.isNewer("1.10", than: "1.9"), "1.10 is newer than 1.9")
expect(Updater.isNewer("1.1", than: "1.0.2"), "1.1 is newer than 1.0.2")
expect(Updater.isNewer("1.0.2", than: "1.0"), "1.0.2 is newer than 1.0")
expect(!Updater.isNewer("1.1", than: "1.1"), "1.1 is not newer than itself")
expect(!Updater.isNewer("1.0.2", than: "1.1"), "1.0.2 is not newer than 1.1")
expect(Updater.version(fromTag: "v1.1") == "1.1", "v1.1 is version 1.1")
expect(Updater.version(fromTag: "1.1") == "1.1", "1.1 is version 1.1")
expect(ClaudeWatch.isTranscript("/Users/me/.claude/projects/-Users-me-app/3f2a.jsonl"), "a Claude Code session transcript counts as Claude working")
expect(ClaudeWatch.isTranscript("/Users/me/Library/Application Support/Claude/local-agent-mode-sessions/a/b/local_c/.claude/projects/-outputs/3f2a.jsonl"), "a Claude.app Cowork transcript counts as Claude working")
expect(!ClaudeWatch.isTranscript("/Users/me/Library/Application Support/Claude/local-agent-mode-sessions/a/b/local_c/audit.jsonl"), "a Cowork audit log does not count")
expect(!ClaudeWatch.isTranscript("/Users/me/.claude/projects/-Users-me-app/memory/notes.md"), "a project memory file does not count")

print(failures == 0 ? "All tests passed" : "\(failures) test(s) failed")
exit(failures == 0 ? 0 : 1)
