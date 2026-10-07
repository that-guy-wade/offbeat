func isDictationApp(_ bundleID: String) -> Bool {
    ["com.openai.codex", "com.anthropic.claudefordesktop"].contains {
        bundleID == $0 || bundleID.hasPrefix($0 + ".")
    }
}

// Require continuous idle readings before restoring music. A failed reading
// cannot masquerade as the microphone being switched off.
struct MicrophoneGate {
    private var recording = false
    private var idleSince: Double?

    mutating func update(_ active: Bool?, at time: Double) -> Bool? {
        guard let active else {
            idleSince = nil
            return nil
        }
        if active {
            idleSince = nil
            guard !recording else { return nil }
            recording = true
            return true
        }
        guard recording else { return nil }
        if idleSince == nil { idleSince = time }
        guard time - idleSince! >= 0.75 else { return nil }
        recording = false
        idleSince = nil
        return false
    }
}
