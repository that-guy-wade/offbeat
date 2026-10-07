@main
struct Tests {
    static func main() {
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
        print("Microphone transition tests passed")
    }
}
