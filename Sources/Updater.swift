import AppKit

final class Updater {
    static let isEnabledInBuild = Bundle.main.object(forInfoDictionaryKey: "AwakeSelfUpdating") as? Bool == true

    private static let latestReleaseURL = "https://api.github.com/repos/betterCallHex/awake/releases/latest"
    private static let checkInterval: TimeInterval = 24 * 60 * 60
    private static let schedulerInterval: TimeInterval = 60 * 60

    private let defaults = UserDefaults.standard
    private let scheduler = NSBackgroundActivityScheduler(identifier: "local.awake.update-check")
    private let installedVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    private var isChecking = false

    var updatesAutomatically: Bool {
        get { defaults.object(forKey: "updatesAutomatically") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "updatesAutomatically") }
    }

    private var isCheckDue: Bool {
        let lastCheck = defaults.object(forKey: "lastUpdateCheck") as? Date ?? .distantPast
        return Date().timeIntervalSince(lastCheck) >= Self.checkInterval
    }

    func start() {
        guard Self.isEnabledInBuild else { return }
        scheduler.interval = Self.schedulerInterval
        scheduler.repeats = true
        scheduler.qualityOfService = .utility
        scheduler.schedule { [weak self] completion in
            guard let self else { return completion(.finished) }
            if self.scheduler.shouldDefer { return completion(.deferred) }
            DispatchQueue.main.async { self.checkAutomatically { completion(.finished) } }
        }
    }

    func checkNow() {
        check(reportingToUser: true)
    }

    private func checkAutomatically(then done: @escaping () -> Void) {
        guard updatesAutomatically, isCheckDue else { return done() }
        check(reportingToUser: false, then: done)
    }

    private func check(reportingToUser: Bool, then done: @escaping () -> Void = {}) {
        guard !isChecking else { return done() }
        isChecking = true
        let installedVersion = installedVersion
        DispatchQueue.global(qos: .utility).async {
            let outcome = Self.update(from: installedVersion)
            DispatchQueue.main.async {
                self.finishCheck(outcome, reportingToUser: reportingToUser)
                done()
            }
        }
    }

    private func finishCheck(_ outcome: Outcome, reportingToUser: Bool) {
        isChecking = false
        if outcome != .failed { defaults.set(Date(), forKey: "lastUpdateCheck") }
        switch outcome {
        case .updated:
            Self.relaunch()
        case .upToDate where reportingToUser:
            Self.showAlert("Awake \(installedVersion) is up to date.")
        case .failed where reportingToUser:
            Self.showAlert("Couldn't check for updates. Try again later.")
        default:
            break
        }
    }

    private static func update(from installedVersion: String) -> Outcome {
        guard let release = latestRelease() else { return .failed }
        guard isNewer(release.version, than: installedVersion) else { return .upToDate }
        return install(release) ? .updated : .failed
    }

    private static func latestRelease() -> (version: String, diskImageURL: String)? {
        guard let response = run("/usr/bin/curl", "-fsSL", "-H", "Accept: application/vnd.github+json", latestReleaseURL),
              let release = try? JSONSerialization.jsonObject(with: response) as? [String: Any],
              let tag = release["tag_name"] as? String,
              let assets = release["assets"] as? [[String: Any]],
              let diskImage = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
              let diskImageURL = diskImage["browser_download_url"] as? String else { return nil }
        return (version(fromTag: tag), diskImageURL)
    }

    static func version(fromTag tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    static func isNewer(_ version: String, than installedVersion: String) -> Bool {
        version.compare(installedVersion, options: .numeric) == .orderedDescending
    }

    private static func install(_ release: (version: String, diskImageURL: String)) -> Bool {
        let fileManager = FileManager.default
        let installedApp = Bundle.main.bundleURL
        guard let workFolder = try? fileManager.url(
            for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: installedApp, create: true
        ) else { return false }
        defer { try? fileManager.removeItem(at: workFolder) }

        let diskImage = workFolder.appendingPathComponent("Awake.dmg").path
        let mountPoint = workFolder.appendingPathComponent("mount")
        let newApp = workFolder.appendingPathComponent("Awake.app")
        guard run("/usr/bin/curl", "-fsSL", "-o", diskImage, release.diskImageURL) != nil,
              run("/usr/bin/hdiutil", "attach", diskImage, "-nobrowse", "-readonly", "-noautoopen", "-mountpoint", mountPoint.path) != nil
        else { return false }
        let copied = (try? fileManager.copyItem(at: mountPoint.appendingPathComponent("Awake.app"), to: newApp)) != nil
        run("/usr/bin/hdiutil", "detach", mountPoint.path, "-force")
        guard copied, isAwake(newApp, version: release.version) else { return false }
        return (try? fileManager.replaceItemAt(installedApp, withItemAt: newApp)) != nil
    }

    private static func isAwake(_ app: URL, version: String) -> Bool {
        let info = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist"))
        return info?["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier
            && info?["CFBundleShortVersionString"] as? String == version
            && run("/usr/bin/codesign", "--verify", app.path) != nil
    }

    @discardableResult
    private static func run(_ executable: String, _ arguments: String...) -> Data? {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return process.terminationStatus == 0 ? data : nil
    }

    private static func relaunch() {
        let waitThenOpen = "while /bin/kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do /bin/sleep 0.1; done; /usr/bin/open \"$0\""
        let relauncher = Process()
        relauncher.executableURL = URL(fileURLWithPath: "/bin/sh")
        relauncher.arguments = ["-c", waitThenOpen, Bundle.main.bundlePath]
        try? relauncher.run()
        NSApp.terminate(nil)
    }

    private static func showAlert(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
}

private enum Outcome {
    case updated, upToDate, failed
}
