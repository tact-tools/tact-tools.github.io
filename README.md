# Tact Website

Static website for `tact.tools`.

The first version is dependency-free HTML/CSS so it can be deployed on GitHub
Pages, Netlify, Cloudflare Pages, or any plain static host.

## Local Preview

Open `index.html` directly in a browser, or serve the directory with any static
file server:

```bash
python3 -m http.server 8080
```

## Assets

The screenshots in `assets/screenshots/` are cropped from synthetic Android
emulator smoke-test captures in `../tact-keyboard-android/artifacts/`. They do
not contain private user data.

Current source captures:

- `prose-full.webp`: `current-prose.png`
- `prose-suggestions.webp`: `phase6a-smoke/prose-suggestions.png`
- `terminal-paste-shield.webp`: `phase7-terminal-smoke/paste-shield-paste-without-enter.png`
- `tact-mesh.webp`: `phase5a-mesh/prose-overlay.png`
