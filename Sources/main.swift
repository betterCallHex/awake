import AppKit
import IOKit.pwr_mgt
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let defaults = UserDefaults.standard
    private let loginItem = SMAppService.mainApp
    private let updater = Updater()
    private let audioWatch = AudioWatch()
    private let claudeWatch = ClaudeWatch()
    private var assertionID: IOPMAssertionID = 0
    private var holdsAssertion = false
    private var isAlwaysAwake = false

    private var awakeWhileAudioPlays: Bool {
        get { defaults.bool(forKey: "awakeWhileAudioPlays") }
        set { defaults.set(newValue, forKey: "awakeWhileAudioPlays") }
    }

    private var awakeWhileClaudeWorks: Bool {
        get { defaults.bool(forKey: "awakeWhileClaudeWorks") }
        set { defaults.set(newValue, forKey: "awakeWhileClaudeWorks") }
    }

    private var isAudioKeepingAwake: Bool { awakeWhileAudioPlays && audioWatch.isPlaying }
    private var isClaudeKeepingAwake: Bool { awakeWhileClaudeWorks && claudeWatch.isWorking }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        defaults.register(defaults: ["awakeWhileAudioPlays": true, "awakeWhileClaudeWorks": true])
        enableOpenAtLoginOnFirstLaunch()
        isAlwaysAwake = defaults.bool(forKey: "isAwake")
        audioWatch.onChange = { [weak self] in self?.update() }
        claudeWatch.onChange = { [weak self] in self?.update() }
        if awakeWhileAudioPlays { audioWatch.start() }
        if awakeWhileClaudeWorks { claudeWatch.start() }
        update()
        updater.start()
    }

    @objc private func handleClick() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            isAlwaysAwake.toggle()
            defaults.set(isAlwaysAwake, forKey: "isAwake")
            update()
        }
    }

    private func update() {
        holdAssertion(isAlwaysAwake || isAudioKeepingAwake || isClaudeKeepingAwake)
        render()
    }

    private func holdAssertion(_ hold: Bool) {
        guard hold != holdsAssertion else { return }
        if hold {
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Awake is keeping your Mac awake" as CFString,
                &assertionID
            )
            holdsAssertion = result == kIOReturnSuccess
        } else {
            IOPMAssertionRelease(assertionID)
            holdsAssertion = false
        }
    }

    private func enableOpenAtLoginOnFirstLaunch() {
        guard !defaults.bool(forKey: "didSetUpOpenAtLogin") else { return }
        try? loginItem.register()
        defaults.set(true, forKey: "didSetUpOpenAtLogin")
    }

    @objc private func toggleAwakeWhileAudioPlays() {
        awakeWhileAudioPlays.toggle()
        if awakeWhileAudioPlays { audioWatch.start() } else { audioWatch.stop() }
        update()
    }

    @objc private func toggleAwakeWhileClaudeWorks() {
        awakeWhileClaudeWorks.toggle()
        if awakeWhileClaudeWorks { claudeWatch.start() } else { claudeWatch.stop() }
        update()
    }

    @objc private func toggleOpenAtLogin() {
        if loginItem.status == .enabled {
            try? loginItem.unregister()
        } else {
            try? loginItem.register()
        }
    }

    @objc private func toggleUpdatesAutomatically() {
        updater.updatesAutomatically.toggle()
    }

    @objc private func checkForUpdates() {
        updater.checkNow()
    }

    private func render() {
        let image = icon()
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = toolTip()
    }

    private func icon() -> NSImage? {
        if isAlwaysAwake {
            return NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Awake: on")
        }
        if holdsAssertion {
            return NSImage(systemSymbolName: "cup.and.heat.waves.fill", accessibilityDescription: "Awake: on automatically")
                ?? NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Awake: on automatically")
        }
        return NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Awake: off")
    }

    private func toolTip() -> String {
        if isAlwaysAwake { return "Keeping your Mac awake — click to stop" }
        switch (isAudioKeepingAwake, isClaudeKeepingAwake) {
        case (true, true): return "Awake while audio plays and Claude works — click to keep your Mac awake"
        case (true, false): return "Awake while audio plays — click to keep your Mac awake"
        case (false, true): return "Awake while Claude works — click to keep your Mac awake"
        case (false, false): return "Click to keep your Mac awake"
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        addAutomaticItems(to: menu)
        menu.addItem(.separator())
        let openAtLogin = menu.addItem(withTitle: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        openAtLogin.target = self
        openAtLogin.state = loginItem.status == .enabled ? .on : .off
        if Updater.isEnabledInBuild { addUpdateItems(to: menu) }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func addAutomaticItems(to menu: NSMenu) {
        let whileAudioPlays = menu.addItem(withTitle: "Stay Awake While Audio Plays", action: #selector(toggleAwakeWhileAudioPlays), keyEquivalent: "")
        whileAudioPlays.target = self
        whileAudioPlays.state = awakeWhileAudioPlays ? .on : .off
        let whileClaudeWorks = menu.addItem(withTitle: "Stay Awake While Claude Works", action: #selector(toggleAwakeWhileClaudeWorks), keyEquivalent: "")
        whileClaudeWorks.target = self
        whileClaudeWorks.state = awakeWhileClaudeWorks ? .on : .off
    }

    private func addUpdateItems(to menu: NSMenu) {
        let updatesAutomatically = menu.addItem(withTitle: "Update Automatically", action: #selector(toggleUpdatesAutomatically), keyEquivalent: "")
        updatesAutomatically.target = self
        updatesAutomatically.state = updater.updatesAutomatically ? .on : .off
        menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "").target = self
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
