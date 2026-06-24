# Tact Website

Static website for `tact.tools`.

The website is dependency-free HTML/CSS so it can be deployed on GitHub Pages,
Netlify, Cloudflare Pages, or any plain static host.

## Local Preview

Open `index.html` directly in a browser, or serve the directory with any static
file server:

```bash
python3 -m http.server 8080
```

## Assets

Android product screenshots are generated from the real Tact keyboard plus
three synthetic host app submodules. Initialize them after cloning:

```bash
git submodule update --init --recursive
```

Then start a disposable emulator and run:

```bash
scripts/capture-android-assets.sh
```

The script requires `curl` and ImageMagick, builds and installs
`tact-keyboard-android`, `tact-mock-editor`, `tact-mock-browser`, and
`tact-mock-terminal`, then captures editor, browser, terminal, clipboard, emoji,
Unicode, OTP source, writing-script, and custom-background OTP states. The OTP
fixture seeds local managed icons from PyPI/npm/Cloudflare site artwork. Raw
PNGs and web-ready derivatives are written under `captures/android-assets/`. See
`docs/android-screenshot-harness.md` for the full workflow and safety notes.

Only commit selected website assets. Keep raw emulator captures, logs, and
local preview output ignored.
