# display-disconnect

Cut the video signal of a USB-C (DisplayPort Alt Mode) external display from software, while the cable keeps charging your Mac. Reconnect it later and the display layout comes back.

It is an open-source take on BetterDisplay Pro's "Disconnect Display", for Apple Silicon Macs. It ships as a menu bar app and a CLI, `dispctl`.

> **Uses a private macOS API.** There is no public API to take a display out of the layout. This tool calls `CGSConfigureDisplayEnabled`, which Apple can change or remove in any macOS update. If the symbol is missing, the tool reports an `unsupported` error instead of crashing. See [Tested on](#tested-on).

## Features

- Disconnect and reconnect an external display from the menu bar or the terminal.
- Charging over the same USB-C cable continues while the display is disconnected.
- Display position and size are restored on reconnect.
- The disconnected state survives quitting the app, sleep and closing the lid. No background process is needed.
- Safety rules: the last active display and the built-in display are never disconnected.
- Scriptable: `dispctl list --json` and meaningful exit codes.

## Requirements

- Apple Silicon Mac (arm64)
- macOS 14 or later
- Swift 6 toolchain (Xcode or the Command Line Tools) to build from source

## Install

### Download

Grab the latest build from the [Releases](https://github.com/jasyuiop/display-disconnect/releases) page:

- `DisplayDisconnect-<version>-arm64.zip`: the menu bar app. Unzip it and move `DisplayDisconnect.app` to `/Applications`.
- `dispctl-<version>-arm64.tar.gz`: the CLI. Extract it and put `dispctl` somewhere on your `PATH`.
- `SHA256SUMS`: verify with `shasum -a 256 -c SHA256SUMS`.

The builds are ad-hoc signed, not notarized (there is no Apple Developer ID behind this project), so macOS blocks them on first launch. After checking the checksum, remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/DisplayDisconnect.app
xattr -d com.apple.quarantine /path/to/dispctl
```

Or build from source, which never gets a quarantine flag.

### Build from source

```sh
git clone https://github.com/jasyuiop/display-disconnect.git
cd display-disconnect
swift build -c release
.build/release/dispctl list
```

To build the menu bar app bundle:

```sh
scripts/bundle-app.sh --configuration release
open .build/bundle/DisplayDisconnect.app
```

## Usage

### Menu bar app

Open `DisplayDisconnect.app`. A menu bar icon lists your displays, each with a **Disconnect** or **Connect** button. The list refreshes automatically when displays are plugged in or out. There is no Dock icon.

### CLI

```sh
dispctl list              # connected displays, plus ones this tool disconnected
dispctl list --json       # same, machine-readable
dispctl disconnect <id>   # cut the video signal (charging continues)
dispctl connect <id>      # bring it back and restore its layout
```

`<id>` comes from `dispctl list`.

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Unexpected error |
| 2 | Refused by a safety rule (unknown display, not disconnected, last display, built-in display) |
| 3 | Unsupported: the private symbol could not be resolved on this macOS |
| 4 | State file problem |
| 5 | The system rejected the display change |
| 64 | Invalid command-line usage |

## How it works

`disconnect` records the display (matched by UUID) and its layout in `~/Library/Application Support/display-disconnect/state.json`, then disables the display for the session. `connect` re-enables it, waits for it to come back, restores its origin if it moved, and removes the record. The app and the CLI share the same core and the same state file.

## If a display does not come back

Try these in order:

1. `dispctl connect <id>` (find the id with `dispctl list`).
2. Make sure the display is plugged in and powered, then try again. Connecting an unplugged display fails with a system error.
3. Replug the cable. This sometimes brings the display back, but not reliably.
4. Log out and back in, or restart the Mac.

## Known limitations

- A display you physically unplug while it is disconnected stays listed as "disconnected"; macOS gives no way to tell that apart from a disconnected display that is still plugged in.
- If you disconnect a display and later change the setup, the restored layout is best effort: position is restored, size differences are only reported.
- Logout and reboot behavior is untested.

## Tested on

| macOS | Hardware | Status |
|-------|----------|--------|
| 26 | Apple Silicon, one external monitor on USB-C, charging over the same cable | Works |
| 14, 15 | not tested | Expected to work, unverified |

CI builds the project and runs the tests against fake displays only; it cannot touch real hardware.

## Development

```sh
./scripts/check.sh   # format, layer rules, build, tests, app bundle
```

The code is split into `DisplayCore` (pure logic), `DisplayBackendCG` (CoreGraphics adapter; the only place that touches the private symbol), `DisplayStorage`, `dispctl` and `DisplayDisconnectApp`.

## License

MIT, see [LICENSE](LICENSE).
