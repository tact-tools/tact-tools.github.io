# Android Screenshot Harness

The website keeps the real keyboard and its mock host apps as Git submodules so
product images can be regenerated instead of copied from stale local smoke
artifacts.

## Setup

Initialize the submodules after cloning:

```sh
git submodule update --init --recursive
```

Start a disposable Android emulator, then run:

```sh
scripts/capture-android-assets.sh
```

The script requires `curl` and ImageMagick's `magick` command. `curl` fetches
site favicons and PyPI logo artwork for the OTP fixture, and `magick`
normalizes those icons before they are copied into Tact's managed local OTP
icon directory.

The harness builds and installs:

- `tact-keyboard-android`: the real Tact IME.
- `tact-mock-editor`: a synthetic document editor host.
- `tact-mock-browser`: a synthetic browser/address-bar host.
- `tact-mock-terminal`: a synthetic terminal host.

It seeds screenshot-safe local fixtures for emoji recents, clipboard review,
and one-time-code sources, selects Tact as the active IME, launches each mock
host, focuses its real editable field, and captures nine states:

- `editor`: real Tact over the mock document editor.
- `browser`: real Tact over the mock browser address field.
- `terminal`: real Tact over the mock terminal command field.
- `clipboard`: the keyboard clipboard review panel with synthetic multiline
  clipboard text.
- `emoji`: the emoji browser with a recent-used row.
- `unicode`: the Unicode browser with the default symbol grid.
- `otp-sources`: the one-time-code source browser with synthetic PyPI, npm,
  and Cloudflare sources. The fixture points each source at a local managed icon
  file seeded from those sites' favicons/artwork, including a blue PyPI tile
  that matches an on-device website crop.
- `letter-scripts`: the writing-script chooser with normal, cursive, old
  English, bold, and outline letter modes.
- `otp-background`: the one-time-code browser over a seeded custom keyboard
  background image, showing the OTP HUD and wallpaper support together.

By default it writes raw PNGs and optional WebP derivatives under
`captures/android-assets/`, which is ignored by Git.

The script starts by clearing the live IME process so stale presentation state
does not leak in from a previous manual session. During the scenario run it
keeps one IME session alive and returns tool surfaces to the alphabet layer
after capture, matching the renderer's in-memory presentation-state model.

## Device Behavior

Use an emulator, not a daily driver. The script intentionally changes the
target display and input settings to make screenshots repeatable:

- window size: `1080x2400`
- density: `420`
- font scale: `1.0`
- animations: disabled
- hard-keyboard soft IME visibility: enabled
- selected IME: `tools.tact.keyboard/.inputmethod.TactInputMethodService`

The script refuses non-emulator devices unless `ALLOW_PHYSICAL_DEVICE=1` is set.

## Useful Options

```sh
scripts/capture-android-assets.sh --scenario editor
scripts/capture-android-assets.sh --scenario browser
scripts/capture-android-assets.sh --scenario terminal
scripts/capture-android-assets.sh --scenario clipboard
scripts/capture-android-assets.sh --scenario emoji
scripts/capture-android-assets.sh --scenario unicode
scripts/capture-android-assets.sh --scenario otp-sources
scripts/capture-android-assets.sh --scenario letter-scripts
scripts/capture-android-assets.sh --scenario otp-background
scripts/capture-android-assets.sh --serial emulator-5554
scripts/capture-android-assets.sh --skip-build --skip-install
OUT_DIR=/tmp/tact-shots scripts/capture-android-assets.sh
```

ImageMagick is already required for OTP icon seeding. It also creates cropped
keyboard WebP files:

```sh
magick raw/editor-full.png -gravity South -crop '100%x55%+0+0' +repage web/editor-keyboard.webp
```

Because fixture seeding runs before scenario filtering, the harness expects
ImageMagick for normal runs even when only one scenario is selected.
