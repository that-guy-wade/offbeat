import AppKit
import CoreAudio

let chatGPTBundleID = "com.openai.codex"
let spotifyBundleID = "com.spotify.client"

func chatGPTRecording() throws -> Bool {
    for process in try AudioHardwareSystem.shared.processes {
        let id = try process.bundleID ?? ""
        if id == chatGPTBundleID || id.hasPrefix(chatGPTBundleID + ".") {
            if try process.isRunningInput { return true }
        }
    }
    return false
}

// Only fixed AppleScript commands and a quoted Spotify track URI are used.
// No shell commands, network requests, microphone capture, or stored history.
func appleScript(_ source: String) throws -> NSAppleEventDescriptor {
    var error: NSDictionary?
    guard let result = NSAppleScript(source: "with timeout of 3 seconds\n" + source + "\nend timeout")?
        .executeAndReturnError(&error) else {
        throw NSError(domain: "DictationPause", code: 1, userInfo: [
            NSLocalizedDescriptionKey: error?[NSAppleScript.errorMessage] as? String
                ?? "Spotify control failed. Check Automation permission in System Settings."
        ])
    }
    return result
}

struct PausedPlayback {
    let pid: pid_t
    let track: String
    let position: Double
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let status = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
    private let enabled = NSMenuItem(title: "Enabled", action: #selector(toggle), keyEquivalent: "")
    private var timer: Timer?
    private var gate = MicrophoneGate()
    private var paused: PausedPlayback?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        menu.addItem(status)
        menu.addItem(.separator())
        enabled.target = self
        enabled.state = .on
        menu.addItem(enabled)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Dictation Pause", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        setStatus("Ready")
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer?.tolerance = 0.05
    }

    private func setStatus(_ text: String) {
        guard status.title != text || statusItem.button?.image == nil else { return }
        status.title = text
        statusItem.button?.image = NSImage(systemSymbolName: paused == nil ? "pause.circle" : "mic.fill",
                                          accessibilityDescription: "Dictation Pause")
        statusItem.button?.toolTip = "Dictation Pause: " + text
    }

    private func tick() {
        guard enabled.state == .on else { return }
        let active = try? chatGPTRecording()
        let transition = gate.update(active, at: ProcessInfo.processInfo.systemUptime)
        guard let active else {
            setStatus("Waiting for microphone status")
            return
        }
        do {
            if transition == true {
                if let spotify = NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundleID).first {
                    let result = try appleScript("""
                        tell application id "com.spotify.client"
                            if player state is not playing then return {}
                            set trackID to id of current track
                            set pausedPosition to player position
                            pause
                            return {trackID, pausedPosition}
                        end tell
                        """)
                    if result.numberOfItems == 2, let track = result.atIndex(1)?.stringValue,
                       let position = result.atIndex(2)?.doubleValue, position.isFinite {
                        paused = PausedPlayback(pid: spotify.processIdentifier, track: track, position: position)
                    }
                }
            } else if transition == false {
                try restore()
            }
            setStatus(paused != nil ? "Spotify paused for dictation"
                : active ? "ChatGPT is using the microphone" : "Ready")
        } catch {
            // Stop retrying a denied Apple Event every polling interval.
            enabled.state = .off
            setStatus(error.localizedDescription)
        }
    }

    private func restore() throws {
        guard let saved = paused else { return }
        paused = nil
        guard NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundleID)
            .contains(where: { $0.processIdentifier == saved.pid }) else { return }
        let quotedTrack = saved.track.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        // Leave manual playback, track changes, seeking, and restarted Spotify alone.
        _ = try appleScript("""
            tell application id "com.spotify.client"
                if player state is paused and id of current track is "\(quotedTrack)" then
                    set currentPosition to player position
                    if currentPosition >= \(saved.position - 0.5) and currentPosition <= \(saved.position + 0.5) then
                        play
                    end if
                end if
            end tell
            """)
    }

    @objc private func toggle() {
        do {
            try restore()
            enabled.state = enabled.state == .on ? .off : .on
            gate = MicrophoneGate()
            setStatus(enabled.state == .on ? "Ready" : "Disabled")
        } catch {
            enabled.state = .off
            setStatus(error.localizedDescription)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        try? restore()
    }
}

if CommandLine.arguments.contains("--diagnose") {
    // Read flags only. This mode never sends Apple Events or opens an input device.
    do {
        print("ChatGPT microphone active: \(try chatGPTRecording())")
    } catch {
        fputs("Microphone status unavailable: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
