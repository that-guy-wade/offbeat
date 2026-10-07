# Dictation Pause

A tiny, free macOS menu bar app that pauses Spotify while you dictate in the
ChatGPT desktop app, then resumes the music it paused.

About 200 lines of Swift. No dependencies, subscriptions, network requests,
audio recording, updater, or playback history.

**Compatibility:** macOS 15+, Spotify desktop, and the ChatGPT/Codex desktop app
using the `com.openai.codex` bundle identifier. Other ChatGPT distributions with
a different identifier are not currently supported. The download is universal
for Apple Silicon and Intel Macs.

## Install

1. [Download the latest release](https://github.com/that-guy-wade/dictation-pause/releases/latest)
   and extract the ZIP.
2. Move **Dictation Pause.app** to Applications and open it.
3. Play Spotify and start dictation in ChatGPT. When macOS asks whether
   Dictation Pause may control Spotify, choose **Allow**.

The pause-circle icon in the menu bar shows status and lets you disable the app
or quit. It checks microphone activity every 0.25 seconds and waits at least
0.75 seconds of idle readings before restoring playback.

### First-launch warning

The release is locally signed with an ad hoc signature. It is **not notarized**
or signed with an Apple Developer ID. If macOS blocks it, first attempt to open
the app, then go to **System Settings → Privacy & Security → Open Anyway → Open**.
See [Apple's instructions](https://support.apple.com/en-us/102445).

You can also inspect the source and build it locally using the commands below.

## Build and test

Requires Apple's Command Line Tools or Xcode with a macOS 15+ SDK and its Swift
CoreAudio overlay. No package manager or network access is used by these scripts.

```sh
git clone https://github.com/that-guy-wade/dictation-pause.git
cd dictation-pause
bash test.sh
bash build.sh
open "Dictation Pause.app"
```

The build produces a universal app for Apple Silicon and Intel. To read the
microphone flag without controlling Spotify:

```sh
"Dictation Pause.app/Contents/MacOS/DictationPause" --diagnose
```

## Behavior and permissions

- Only **Spotify Automation** permission is needed. The app reads CoreAudio's
  process input-use flag without opening the microphone or reading audio samples.
  It needs no Microphone, Accessibility, or Screen Recording permission.
- It detects `com.openai.codex` and its helper processes. Voice chats and
  microphone use in other windows of that app also trigger it; other apps do not.
- It restores playback only if Spotify is still paused on the same process,
  track, and position. Initially paused music stays paused. Disabling or quitting
  also restores an unchanged pause it owns.
- Manual changes followed by a return to the same paused track and position
  are indistinguishable from its own pause. Position is checked within half a
  second; the app does not monitor every Spotify interaction.
- If Spotify control fails, the app disables itself and shows the error. Review
  **System Settings → Privacy & Security → Automation**, then enable it again.
  Failed microphone queries never trigger playback restoration.
- No automatic start at login. Open it when needed. Spotify Web is not supported.

## Verification

Live Spotify pause/resume was confirmed on an Apple Silicon Mac running macOS
26.2. The microphone transition tests cover immediate start, repeated readings,
brief idle gaps, query failures, and confirmed stop. The embedded Spotify scripts
also passed simulated checks for paused music, track changes, and seeking.
Intel and older macOS versions have not been tested live.

## License

[MIT](LICENSE). Inspired by [HushMic](https://github.com/location-txl/HushMic)'s
behavior. No HushMic source or downloaded binary is included.
