# djilink

Turns the **Link** button on a DJI Mic Mini 2 USB receiver into a keystroke on macOS, so you can use it as a dictation trigger (Wispr Flow, Superwhisper, etc.). No Bluetooth.

The receiver exposes a HID Consumer Control interface and sends **Volume Up** when Link is pressed. `djilink` seizes that device (so the volume doesn't change) and posts the key you choose.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/tusharxclaude/djilink/main/install.sh | sh
```

Builds from source into `~/.local/bin/djilink`; needs the Xcode Command Line Tools (`xcode-select --install`). To also start at login:

```sh
curl -fsSL https://raw.githubusercontent.com/tusharxclaude/djilink/main/install.sh | DJILINK_AGENT=1 sh
```

macOS will ask for **Accessibility** and **Input Monitoring** permission (System Settings > Privacy & Security). Grant it to the `djilink` binary (or to your terminal if you launch it from there).

## Usage

```sh
djilink --list                                   # show DJI HID devices and product IDs
djilink                                          # Link -> Option+Space
djilink --keycode 105 --flags ""                 # Link -> F13
djilink --keycode 49 --flags command,shift       # Link -> Cmd+Shift+Space
djilink --product 0x4011                         # pick a different receiver
```

- `--keycode N`: macOS virtual key code (Space 49, Return 36, F13 105, F14 107, F15 113).
- `--flags a,b`: `option`, `command`, `control`, `shift`.
- `--no-seize`: don't seize the device (volume will also change).

## Limits

- Only Link sends an event. Power sends nothing to the host.
- Link is a single tap: no hold or double-press events, so push-to-talk (hold) won't work; use a toggle hotkey.
- Modifier-only shortcuts (e.g. right Option alone) and `fn` aren't supported.
- Tested on the Mic Mini 2 receiver (vendor `0x2ca3`, product `0x4011`). Other DJI receivers may differ; run `--list` and open an issue.

## Uninstall

```sh
sh uninstall.sh
```
