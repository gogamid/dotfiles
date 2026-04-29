import Cocoa
import CoreGraphics
import IOKit
import IOKit.hid

let CORNE_VENDOR_ID: Int = 0x1d50
let CORNE_PRODUCT_ID: Int = 0x615e
let CORNE_WINDOW: TimeInterval = 0.2
let DEBOUNCE_COUNT = 2
let NOTIFY_THROTTLE: TimeInterval = 2.0
let AEROSPACE_CONFIG_DIR = NSHomeDirectory() + "/.config/aerospace"
let AEROSPACE_CONFIG_PATH = AEROSPACE_CONFIG_DIR + "/aerospace.toml"
let INTERNAL_CONFIG_PATH = AEROSPACE_CONFIG_DIR + "/aerospace-internal.toml"
let CORNE_CONFIG_PATH = AEROSPACE_CONFIG_DIR + "/aerospace-corne.toml"

var lastCorneActivity: Date = .distantPast
var currentKeyboard: String = "none"
var debounceKeyboard: String? = nil
var debounceCount: Int = 0
var lastNotifyTime: Date = .distantPast
var corneConnected: Bool = false

func notify(_ message: String) {
    let escaped = message.replacingOccurrences(of: "\"", with: "\\\"")
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", "display notification \"\(escaped)\" with title \"Keyboard Watcher\""]
    try? task.run()
    task.waitUntilExit()
}

func reloadAerospace() {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = ["bash", "-c", "/opt/homebrew/bin/aerospace reload-config 2>&1 || true"]
    try? task.run()
    task.waitUntilExit()
}

func copyConfig(from source: String) -> Bool {
    do {
        let content = try String(contentsOfFile: source, encoding: .utf8)
        try content.write(toFile: AEROSPACE_CONFIG_PATH, atomically: true, encoding: .utf8)
        fputs("Copied \(source) -> \(AEROSPACE_CONFIG_PATH)\n", stderr)
        return true
    } catch {
        fputs("Error copying config: \(error)\n", stderr)
        return false
    }
}

func switchTo(_ keyboard: String) {
    if keyboard != currentKeyboard {
        let prev = currentKeyboard
        currentKeyboard = keyboard
        let now = Date()
        if now.timeIntervalSince(lastNotifyTime) >= NOTIFY_THROTTLE {
            lastNotifyTime = now
            switch keyboard {
            case "corne": notify("Switched to: Corne")
            case "internal": notify("Switched to: Internal (kanata)")
            default: notify("Switched to: \(keyboard)")
            }
        }
        fputs("SWITCH: \(prev) -> \(keyboard)\n", stderr)
        let sourcePath = keyboard == "corne" ? CORNE_CONFIG_PATH : INTERNAL_CONFIG_PATH
        if copyConfig(from: sourcePath) {
            reloadAerospace()
        }
    }
}

func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .keyDown {
        let now = Date()
        let keyboard: String
        if corneConnected && now.timeIntervalSince(lastCorneActivity) <= CORNE_WINDOW {
            keyboard = "corne"
        } else {
            keyboard = "internal"
        }

        if keyboard == debounceKeyboard {
            debounceCount += 1
        } else {
            debounceKeyboard = keyboard
            debounceCount = 1
        }

        if debounceCount >= DEBOUNCE_COUNT {
            switchTo(keyboard)
        }
    }
    return Unmanaged.passRetained(event)
}

let corneReportCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
    lastCorneActivity = Date()
}

let deviceMatchCallback: IOHIDDeviceCallback = { context, result, sender, device in
    corneConnected = true
    fputs("Corne connected\n", stderr)
    notify("Corne detected")
}

let deviceRemovalCallback: IOHIDDeviceCallback = { context, result, sender, device in
    corneConnected = false
    lastCorneActivity = .distantPast
    fputs("Corne disconnected\n", stderr)
    notify("Corne disconnected")
    switchTo("internal")
}

let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
let matching: [String: Int] = [
    kIOHIDVendorIDKey: CORNE_VENDOR_ID,
    kIOHIDProductIDKey: CORNE_PRODUCT_ID
]
IOHIDManagerSetDeviceMatching(hidManager, matching as CFDictionary)

let openResult = IOHIDManagerOpen(hidManager, 0)
if openResult != kIOReturnSuccess {
    fputs("Error: Could not open IOHIDManager: \(openResult)\n", stderr)
    exit(1)
}

IOHIDManagerRegisterInputReportCallback(hidManager, corneReportCallback, nil)
IOHIDManagerRegisterDeviceMatchingCallback(hidManager, deviceMatchCallback, nil)
IOHIDManagerRegisterDeviceRemovalCallback(hidManager, deviceRemovalCallback, nil)
IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

let devices = IOHIDManagerCopyDevices(hidManager) as? Set<IOHIDDevice> ?? []
if !devices.isEmpty {
    corneConnected = true
    fputs("Corne already connected\n", stderr)
}

let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: eventMask,
    callback: handleEvent,
    userInfo: nil
) else {
    fputs("Error: Could not create event tap. Grant Accessibility permission.\n", stderr)
    exit(1)
}

CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0), .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

fputs("Keyboard watcher started.\n", stderr)
CFRunLoopRun()
