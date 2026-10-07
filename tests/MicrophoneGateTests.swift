@main
struct Tests {
    static func main() {
        for id in ["com.openai.codex", "com.openai.codex.helper",
                   "com.anthropic.claudefordesktop", "com.anthropic.claudefordesktop.helper"] {
            precondition(isDictationApp(id), "Supported app and helper identifiers must match")
        }
        for id in ["", "com.spotify.client", "com.anthropic.claude.ios-sim",
                   "com.openai.codex-other", "com.anthropic.claudefordesktop-other"] {
            precondition(!isDictationApp(id), "Unrelated apps and partial identifiers must not match")
        }
        var gate = MicrophoneGate()
        precondition(gate.update(false, at: 0) == nil, "Idle must not trigger playback")
        precondition(gate.update(true, at: 1) == true, "Recording starts immediately")
        precondition(gate.update(true, at: 2) == nil, "Don't repeatedly pause")
        precondition(gate.update(false, at: 3) == nil, "Don't resume on a brief idle sample")
        precondition(gate.update(true, at: 3.5) == nil, "Recording bounce keeps the pause")
        precondition(gate.update(false, at: 4) == nil)
        precondition(gate.update(nil, at: 5) == nil, "Errors cannot trigger resume")
        precondition(gate.update(false, at: 5.5) == nil, "Error interrupts the idle interval")
        precondition(gate.update(false, at: 6.25) == false, "Confirmed idle allows restore")
        precondition(gate.update(false, at: 7) == nil, "Don't repeatedly restore")
        precondition(gate.update(true, at: 8) == true, "Next dictation starts a fresh cycle")
        var overlap = MicrophoneGate()
        for (time, chatGPT, claude) in [(0.0, true, false), (1.0, true, true), (2.0, false, true)] {
            precondition(overlap.update(chatGPT || claude, at: time) == (time == 0 ? true : nil),
                         "Keep the pause while either supported app is recording")
        }
        precondition(overlap.update(false, at: 3) == nil)
        precondition(overlap.update(false, at: 3.75) == false, "Resume only after both apps stop")
        print("App matching and microphone transition tests passed")
    }
}
