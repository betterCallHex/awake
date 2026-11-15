import AppKit
import IOKit.pwr_mgt
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let defaults = UserDefaults.standard
    private let loginItem = SMAppService.mainApp
    private var assertionID: IOPMAssertionID = 0
    private var isAwake = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        enableOpenAtLoginOnFirstLaunch()
        setAwake(defaults.bool(forKey: "isAwake"))
        render()
    }

    @objc private func handleClick() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            setAwake(!isAwake)
            defaults.set(isAwake, forKey: "isAwake")
        }
    }

    private func setAwake(_ awake: Bool) {
        guard awake != isAwake else { return }
        if awake {
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Awake is keeping your Mac awake" as CFString,
                &assertionID
            )
            isAwake = result == kIOReturnSuccess
        } else {
            IOPMAssertionRelease(assertionID)
            isAwake = false
        }
        render()
    }

    private func enableOpenAtLoginOnFirstLaunch() {
        guard !defaults.bool(forKey: "didSetUpOpenAtLogin") else { return }
        try? loginItem.register()
        defaults.set(true, forKey: "didSetUpOpenAtLogin")
    }

    @objc private func toggleOpenAtLogin() {
        if loginItem.status == .enabled {
            try? loginItem.unregister()
        } else {
            try? loginItem.register()
        }
    }

    private func render() {
        let symbol = isAwake ? "cup.and.saucer.fill" : "cup.and.saucer"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: isAwake ? "Awake: on" : "Awake: off")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = isAwake ? "Keeping your Mac awake — click to stop" : "Click to keep your Mac awake"
    }

    private func showMenu() {
        let menu = NSMenu()
        let openAtLogin = menu.addItem(withTitle: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        openAtLogin.target = self
        openAtLogin.state = loginItem.status == .enabled ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
