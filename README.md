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

## Deploy

Staging is served by GitHub Pages from the static-only `gh-pages` branch:

```bash
scripts/deploy-github-pages.sh
```

The `main` branch keeps the source files, screenshot harness, and Android/mock
app submodules. Publishing from `gh-pages` avoids GitHub Pages trying to clone
those development-only submodules during its checkout step.

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
