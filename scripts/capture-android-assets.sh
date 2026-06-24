#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="${ANDROID_DIR:-"$ROOT_DIR/tact-keyboard-android"}"
MOCK_EDITOR_DIR="${MOCK_EDITOR_DIR:-"$ROOT_DIR/tact-mock-editor"}"
MOCK_BROWSER_DIR="${MOCK_BROWSER_DIR:-"$ROOT_DIR/tact-mock-browser"}"
MOCK_TERMINAL_DIR="${MOCK_TERMINAL_DIR:-"$ROOT_DIR/tact-mock-terminal"}"
OUT_DIR="${OUT_DIR:-"$ROOT_DIR/captures/android-assets"}"
RAW_DIR="$OUT_DIR/raw"
WEB_DIR="$OUT_DIR/web"
ADB="${ADB:-adb}"
ANDROID_SERIAL="${ANDROID_SERIAL:-}"
PACKAGE="tools.tact.keyboard"
IME_ID="$PACKAGE/.inputmethod.TactInputMethodService"
TACT_APK_PATH="${TACT_APK_PATH:-"$ANDROID_DIR/app/build/outputs/apk/debug/tools.tact.keyboard-debug.apk"}"
WM_SIZE="${WM_SIZE:-1080x2400}"
WM_DENSITY="${WM_DENSITY:-420}"
CAPTURE_SETTLE_SECONDS="${CAPTURE_SETTLE_SECONDS:-2}"
KEYBOARD_CROP="${KEYBOARD_CROP:-100%x55%+0+0}"
WEBP_QUALITY="${WEBP_QUALITY:-92}"
ALLOW_PHYSICAL_DEVICE="${ALLOW_PHYSICAL_DEVICE:-0}"
KEYBOARD_STDDEV_THRESHOLD="${KEYBOARD_STDDEV_THRESHOLD:-0.04}"

SKIP_BUILD=0
SKIP_INSTALL=0
SKIP_CONVERT=0
SELECTED_SCENARIOS=()

SCENARIOS=(
  "editor|tact-mock-editor|tools.tact.mock.editor|.EditorActivity|540|720|none|Synthetic editor"
  "browser|tact-mock-browser|tools.tact.mock.browser|.BrowserActivity|540|160|none|Synthetic browser"
  "terminal|tact-mock-terminal|tools.tact.mock.terminal|.TerminalActivity|540|900|none|Synthetic terminal"
  "clipboard|tact-mock-editor|tools.tact.mock.editor|.EditorActivity|540|720|open_clipboard|Clipboard manager"
  "emoji|tact-mock-editor|tools.tact.mock.editor|.EditorActivity|540|720|open_emoji_recents|Emoji browser with recent-used grid"
  "unicode|tact-mock-editor|tools.tact.mock.editor|.EditorActivity|540|720|open_unicode|Unicode browser"
  "otp-sources|tact-mock-editor|tools.tact.mock.editor|.EditorActivity|540|720|open_otp_sources|One-time-code source browser"
)

usage() {
  cat <<USAGE
Usage: scripts/capture-android-assets.sh [options]

Builds the Tact Android app and the mock host apps from submodules, installs
them on a running emulator, selects the Tact IME, launches polished synthetic
host surfaces, and captures product screenshots.

Options:
  --serial SERIAL       adb device serial. Also supported by ANDROID_SERIAL.
  --out-dir DIR         output directory. Default: captures/android-assets.
  --scenario NAME       capture only one scenario. Repeatable.
                        Known: editor, browser, terminal, clipboard, emoji,
                               unicode, otp-sources.
  --skip-build          reuse the existing debug APK.
  --skip-install        reuse apps already installed on the emulator.
  --no-convert          skip optional WebP/crop generation.
  -h, --help            show this help.

Environment:
  WM_SIZE=1080x2400             emulator size forced before capture.
  WM_DENSITY=420                emulator density forced before capture.
  CAPTURE_SETTLE_SECONDS=2      delay after the IME appears.
  KEYBOARD_CROP=100%x55%+0+0    ImageMagick crop geometry from screen bottom.
  WEBP_QUALITY=92               WebP quality for ImageMagick/cwebp.
  ALLOW_PHYSICAL_DEVICE=1       allow non-emulator devices.
  TACT_APK_PATH=...              Tact debug APK to install after building.
  KEYBOARD_STDDEV_THRESHOLD=0.04 lower-screen variance threshold for capture.

Output:
  Raw PNGs:    \$OUT_DIR/raw/*-full.png
  Web assets:  \$OUT_DIR/web/*-full.webp and *-keyboard.webp when magick exists.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

adb_cmd() {
  if [[ -n "$ANDROID_SERIAL" ]]; then
    "$ADB" -s "$ANDROID_SERIAL" "$@"
  else
    "$ADB" "$@"
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --serial)
        [[ $# -ge 2 ]] || fail "--serial requires a value"
        ANDROID_SERIAL="$2"
        shift 2
        ;;
      --out-dir)
        [[ $# -ge 2 ]] || fail "--out-dir requires a value"
        OUT_DIR="$2"
        RAW_DIR="$OUT_DIR/raw"
        WEB_DIR="$OUT_DIR/web"
        shift 2
        ;;
      --scenario)
        [[ $# -ge 2 ]] || fail "--scenario requires a value"
        SELECTED_SCENARIOS+=("$2")
        shift 2
        ;;
      --skip-build)
        SKIP_BUILD=1
        shift
        ;;
      --skip-install)
        SKIP_INSTALL=1
        shift
        ;;
      --no-convert)
        SKIP_CONVERT=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "unknown option: $1"
        ;;
    esac
  done
}

scenario_selected() {
  local name="$1"
  if [[ ${#SELECTED_SCENARIOS[@]} -eq 0 ]]; then
    return 0
  fi
  local selected
  for selected in "${SELECTED_SCENARIOS[@]}"; do
    if [[ "$selected" == "$name" ]]; then
      return 0
    fi
  done
  return 1
}

validate_selected_scenarios() {
  local selected known scenario name
  for selected in "${SELECTED_SCENARIOS[@]}"; do
    known=0
    for scenario in "${SCENARIOS[@]}"; do
      IFS='|' read -r name _ _ _ <<<"$scenario"
      if [[ "$selected" == "$name" ]]; then
        known=1
        break
      fi
    done
    [[ "$known" -eq 1 ]] || fail "unknown scenario: $selected"
  done
}

mock_dir_for_submodule() {
  case "$1" in
    tact-mock-editor) echo "$MOCK_EDITOR_DIR" ;;
    tact-mock-browser) echo "$MOCK_BROWSER_DIR" ;;
    tact-mock-terminal) echo "$MOCK_TERMINAL_DIR" ;;
    *) fail "unknown mock submodule: $1" ;;
  esac
}

ensure_submodules() {
  if [[ ! -x "$ANDROID_DIR/gradlew" ]]; then
    echo "Initializing tact-keyboard-android submodule..."
    git -C "$ROOT_DIR" submodule update --init --recursive tact-keyboard-android
  fi
  [[ -x "$ANDROID_DIR/gradlew" ]] || fail "Android submodule is missing gradlew"

  local scenario name submodule package activity tap_x tap_y action description dir
  for scenario in "${SCENARIOS[@]}"; do
    IFS='|' read -r name submodule package activity tap_x tap_y action description <<<"$scenario"
    dir="$(mock_dir_for_submodule "$submodule")"
    if [[ ! -x "$dir/gradlew" ]]; then
      echo "Initializing $submodule submodule..."
      git -C "$ROOT_DIR" submodule update --init --recursive "$submodule"
    fi
    [[ -x "$dir/gradlew" ]] || fail "$submodule is missing gradlew"
  done
}

build_android_projects() {
  if [[ "$SKIP_BUILD" -eq 1 ]]; then
    return
  fi
  echo "Building Tact debug APK..."
  (cd "$ANDROID_DIR" && ./gradlew :app:assembleDebug)

  local built_submodules=" "
  local scenario name submodule package activity tap_x tap_y action description dir
  for scenario in "${SCENARIOS[@]}"; do
    IFS='|' read -r name submodule package activity tap_x tap_y action description <<<"$scenario"
    if [[ "$built_submodules" == *" $submodule "* ]]; then
      continue
    fi
    built_submodules+="$submodule "
    dir="$(mock_dir_for_submodule "$submodule")"
    echo "Building $submodule debug APK..."
    (cd "$dir" && ./gradlew :app:assembleDebug)
  done
}

install_apk() {
  local apk_path="$1"
  [[ -f "$apk_path" ]] || fail "debug APK not found: $apk_path"
  echo "Installing $apk_path..."
  adb_cmd install -r -d "$apk_path" >/dev/null
}

install_android_projects() {
  if [[ "$SKIP_INSTALL" -eq 1 ]]; then
    return
  fi
  install_apk "$TACT_APK_PATH"

  local installed_submodules=" "
  local scenario name submodule package activity tap_x tap_y action description dir
  for scenario in "${SCENARIOS[@]}"; do
    IFS='|' read -r name submodule package activity tap_x tap_y action description <<<"$scenario"
    if [[ "$installed_submodules" == *" $submodule "* ]]; then
      continue
    fi
    installed_submodules+="$submodule "
    dir="$(mock_dir_for_submodule "$submodule")"
    install_apk "$dir/app/build/outputs/apk/debug/app-debug.apk"
  done
}

ensure_emulator_target() {
  require_command "$ADB"
  adb_cmd get-state >/dev/null 2>&1 || \
    fail "adb target is not available; start an emulator or pass --serial"

  local qemu model
  qemu="$(adb_cmd shell getprop ro.kernel.qemu | tr -d '\r')"
  model="$(adb_cmd shell getprop ro.product.model | tr -d '\r')"
  if [[ "$qemu" != "1" && "$ALLOW_PHYSICAL_DEVICE" != "1" ]]; then
    fail "target '$model' does not look like an emulator; set ALLOW_PHYSICAL_DEVICE=1 to override"
  fi
}

prepare_device() {
  echo "Preparing emulator display and keyboard settings..."
  adb_cmd shell input keyevent KEYCODE_WAKEUP >/dev/null || true
  adb_cmd shell wm dismiss-keyguard >/dev/null || true
  adb_cmd shell settings put global window_animation_scale 0
  adb_cmd shell settings put global transition_animation_scale 0
  adb_cmd shell settings put global animator_duration_scale 0
  adb_cmd shell settings put system font_scale 1.0
  adb_cmd shell settings put secure show_ime_with_hard_keyboard 1 || true
  adb_cmd shell cmd uimode night no >/dev/null || true
  if [[ -n "$WM_SIZE" ]]; then
    adb_cmd shell wm size "$WM_SIZE"
  fi
  if [[ -n "$WM_DENSITY" ]]; then
    adb_cmd shell wm density "$WM_DENSITY"
  fi
}

rebind_tact_ime() {
  adb_cmd shell cmd package unstop "$PACKAGE" >/dev/null || true
  adb_cmd shell ime disable "$IME_ID" >/dev/null 2>&1 || true
  adb_cmd shell ime enable "$IME_ID" >/dev/null || true
  adb_cmd shell ime set "$IME_ID" >/dev/null
}

select_tact_ime() {
  adb_cmd shell cmd package unstop "$PACKAGE" >/dev/null || true
  adb_cmd shell ime enable "$IME_ID" >/dev/null || true
  adb_cmd shell ime set "$IME_ID" >/dev/null
}

reload_tact_process() {
  adb_cmd shell am force-stop "$PACKAGE" >/dev/null || true
  adb_cmd shell cmd package unstop "$PACKAGE" >/dev/null || true
  sleep 0.5
}

seed_fixture_data() {
  seed_emoji_recents
  seed_otp_source_icons
  seed_otp_sources
  reload_tact_process
}

seed_emoji_recents() {
  local emoji_recents_base64
  emoji_recents_base64="8J+OiQrinaTvuI8K8J+RjfCfj70K8J+agArinKgK8J+UpQo="
  printf '%s' "$emoji_recents_base64" | \
    adb_cmd shell "run-as $PACKAGE sh -c 'mkdir -p files/emoji-recents && base64 -d > files/emoji-recents/recents.txt'"
}

seed_otp_source_icons() {
  require_command curl
  require_command magick

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  adb_cmd shell "run-as $PACKAGE sh -c 'rm -rf files/otp-source-icons && mkdir -p files/otp-source-icons'"
  seed_pypi_otp_source_icon "$tmp_dir" "source-pypi" "1780800000000"
  seed_otp_source_icon "$tmp_dir" "source-npm" "1780800002000" "https://static-production.npmjs.com/1996fcfdf7ca81ea795f67f093d7f449.png" ""
  seed_otp_source_icon "$tmp_dir" "source-cloudflare" "1780800004000" "https://www.cloudflare.com/favicon.ico" ""

  rm -rf "$tmp_dir"
}

seed_pypi_otp_source_icon() {
  local tmp_dir="$1"
  local source_id="$2"
  local updated_at="$3"
  local logo_svg="$tmp_dir/$source_id-logo.svg"
  local logo_png="$tmp_dir/$source_id-logo.png"
  local converted="$tmp_dir/$source_id.png"
  local filename="$source_id-$updated_at.png"

  curl -L --fail --silent --show-error \
    -A "Mozilla/5.0" \
    "https://pypi.org/static/images/logo-small.8998e9d1.svg" \
    -o "$logo_svg"
  magick -background none "$logo_svg" -resize 304x268 "$logo_png"
  magick -size 512x512 gradient:'#128bc0-#006a98' \
    "$logo_png" \
    -gravity center \
    -geometry +0-24 \
    -compose over \
    -composite \
    "$converted"
  base64 "$converted" | \
    adb_cmd shell "run-as $PACKAGE sh -c 'base64 -d > files/otp-source-icons/$filename'"
}

seed_otp_source_icon() {
  local tmp_dir="$1"
  local source_id="$2"
  local updated_at="$3"
  local favicon_url="$4"
  local magick_frame="$5"
  local flatten_background="${6:-}"
  local download_extension="${favicon_url%%\?*}"
  download_extension="${download_extension##*.}"
  local downloaded="$tmp_dir/$source_id.$download_extension"
  local converted="$tmp_dir/$source_id.png"
  local filename="$source_id-$updated_at.png"

  curl -L --fail --silent --show-error \
    -A "Mozilla/5.0" \
    "$favicon_url" \
    -o "$downloaded"
  if [[ -n "$flatten_background" ]]; then
    magick "$downloaded$magick_frame" \
      -background "$flatten_background" \
      -alpha remove \
      -alpha off \
      -resize 512x512 \
      -gravity center \
      -extent 512x512 \
      "$converted"
  else
    magick "$downloaded$magick_frame" \
      -background transparent \
      -resize 512x512 \
      -gravity center \
      -extent 512x512 \
      "$converted"
  fi
  base64 "$converted" | \
    adb_cmd shell "run-as $PACKAGE sh -c 'base64 -d > files/otp-source-icons/$filename'"
}

seed_otp_sources() {
  adb_cmd shell "run-as $PACKAGE sh -c 'mkdir -p shared_prefs && cat > shared_prefs/tact_otp_vault.xml'" <<'XML'
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <string name="otp_vault_records_json">[
        {
            "schema": 1,
            "id": "source-pypi",
            "issuer": "PyPI",
            "accountName": "release@tact.tools",
            "type": "TOTP",
            "algorithm": "SHA1",
            "digits": 6,
            "periodSeconds": 30,
            "counter": null,
            "imageUrl": "file:///data/user/0/tools.tact.keyboard/files/otp-source-icons/source-pypi-1780800000000.png",
            "colorHex": "3775A9",
            "createdAtMillis": 1780800000000,
            "updatedAtMillis": 1780800000000,
            "encryptedSecret": {
                "scheme": "plaintext-base64-v1",
                "keyAlias": "none",
                "ivBase64": "none",
                "ciphertextBase64": "c2NyZWVuc2hvdC1zZWNyZXQ="
            },
            "codeRecipe": {
                "kind": "codeOnly"
            }
        },
        {
            "schema": 1,
            "id": "source-npm",
            "issuer": "npm",
            "accountName": "packages@tact.tools",
            "type": "TOTP",
            "algorithm": "SHA1",
            "digits": 6,
            "periodSeconds": 30,
            "counter": null,
            "imageUrl": "file:///data/user/0/tools.tact.keyboard/files/otp-source-icons/source-npm-1780800002000.png",
            "colorHex": "C9382C",
            "createdAtMillis": 1780800002000,
            "updatedAtMillis": 1780800002000,
            "encryptedSecret": {
                "scheme": "plaintext-base64-v1",
                "keyAlias": "none",
                "ivBase64": "none",
                "ciphertextBase64": "c2NyZWVuc2hvdC1zZWNyZXQ="
            },
            "codeRecipe": {
                "kind": "codeOnly"
            }
        },
        {
            "schema": 1,
            "id": "source-cloudflare",
            "issuer": "Cloudflare",
            "accountName": "edge@tact.tools",
            "type": "TOTP",
            "algorithm": "SHA1",
            "digits": 6,
            "periodSeconds": 30,
            "counter": null,
            "imageUrl": "file:///data/user/0/tools.tact.keyboard/files/otp-source-icons/source-cloudflare-1780800004000.png",
            "colorHex": "F38020",
            "createdAtMillis": 1780800004000,
            "updatedAtMillis": 1780800004000,
            "encryptedSecret": {
                "scheme": "plaintext-base64-v1",
                "keyAlias": "none",
                "ivBase64": "none",
                "ciphertextBase64": "c2NyZWVuc2hvdC1zZWNyZXQ="
            },
            "codeRecipe": {
                "kind": "codeOnly"
            }
        }
    ]</string>
</map>
XML
}

wait_for_ime() {
  local served_package="$1"
  local attempt dumpsys
  for attempt in $(seq 1 30); do
    dumpsys="$(adb_cmd shell dumpsys input_method 2>/dev/null | tr -d '\r' || true)"
    if grep -q "packageName=$served_package" <<<"$dumpsys" &&
      grep -Eq "mInputShown=true|mIsInputViewShown=true|inputShown=true" <<<"$dumpsys"; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

focus_input_for_capture() {
  local mock_package="$1"
  local tap_x="$2"
  local tap_y="$3"

  adb_cmd shell input tap "$tap_x" "$tap_y" >/dev/null
  if wait_for_ime "$mock_package"; then
    return 0
  fi

  echo "warning: IME did not report visible after focus; retrying" >&2
  rebind_tact_ime
  sleep 0.5
  adb_cmd shell input tap "$tap_x" "$tap_y" >/dev/null
  wait_for_ime "$mock_package" || fail "IME did not become visible for $mock_package"
}

write_metadata() {
  mkdir -p "$OUT_DIR"
  {
    echo "captured_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "website_root=$ROOT_DIR"
    echo "android_dir=$ANDROID_DIR"
    echo "android_rev=$(git -C "$ANDROID_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "mock_editor_rev=$(git -C "$MOCK_EDITOR_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "mock_browser_rev=$(git -C "$MOCK_BROWSER_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "mock_terminal_rev=$(git -C "$MOCK_TERMINAL_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    echo "adb_serial=${ANDROID_SERIAL:-default}"
    echo "device_model=$(adb_cmd shell getprop ro.product.model | tr -d '\r')"
    echo "android_release=$(adb_cmd shell getprop ro.build.version.release | tr -d '\r')"
    echo "android_sdk=$(adb_cmd shell getprop ro.build.version.sdk | tr -d '\r')"
    echo "wm_size=$(adb_cmd shell wm size | tr -d '\r')"
    echo "wm_density=$(adb_cmd shell wm density | tr -d '\r')"
    echo "output_raw=$RAW_DIR"
    echo "output_web=$WEB_DIR"
  } > "$OUT_DIR/run.txt"
}

convert_asset() {
  local name="$1"
  local png="$2"
  if [[ "$SKIP_CONVERT" -eq 1 ]]; then
    return
  fi
  mkdir -p "$WEB_DIR"
  if command -v magick >/dev/null 2>&1; then
    magick "$png" -strip -quality "$WEBP_QUALITY" "$WEB_DIR/$name-full.webp"
    magick "$png" -gravity South -crop "$KEYBOARD_CROP" +repage \
      -strip -quality "$WEBP_QUALITY" "$WEB_DIR/$name-keyboard.webp"
  elif command -v cwebp >/dev/null 2>&1; then
    cwebp -quiet -q "$WEBP_QUALITY" "$png" -o "$WEB_DIR/$name-full.webp"
    echo "warning: install ImageMagick for cropped keyboard WebP output" >&2
  else
    echo "warning: install ImageMagick or cwebp for WebP output" >&2
  fi
}

wait_and_capture_screen() {
  local output_png="$1"
  local tmp_png="$OUT_DIR/.capture-check.png"
  local attempt stddev

  if ! command -v magick >/dev/null 2>&1; then
    sleep "$CAPTURE_SETTLE_SECONDS"
    adb_cmd exec-out screencap -p > "$output_png"
    return
  fi

  for attempt in $(seq 1 20); do
    adb_cmd exec-out screencap -p > "$tmp_png"
    stddev="$(
      magick "$tmp_png" \
        -gravity South \
        -crop '100%x35%+0+0' \
        +repage \
        -colorspace Gray \
        -format '%[fx:standard_deviation]' \
        info:
    )"
    if awk "BEGIN { exit !($stddev >= $KEYBOARD_STDDEV_THRESHOLD) }"; then
      mv "$tmp_png" "$output_png"
      return
    fi
    sleep 0.5
  done

  echo "warning: lower screen did not visually match keyboard before capture" >&2
  mv "$tmp_png" "$output_png"
}

capture_scenario() {
  local name="$1"
  local submodule="$2"
  local mock_package="$3"
  local activity="$4"
  local tap_x="$5"
  local tap_y="$6"
  local action="$7"
  local description="$8"
  local png="$RAW_DIR/$name-full.png"

  echo "Capturing $name: $description"
  adb_cmd shell am force-stop "$mock_package" >/dev/null || true
  select_tact_ime

  adb_cmd shell am start -W -n "$mock_package/$activity" >/dev/null
  sleep 0.8
  focus_input_for_capture "$mock_package" "$tap_x" "$tap_y"
  sleep "$CAPTURE_SETTLE_SECONDS"
  run_capture_action "$action"
  wait_and_capture_screen "$png"
  cleanup_capture_action "$action"
  convert_asset "$name" "$png"
}

run_capture_action() {
  case "$1" in
    none) ;;
    open_clipboard)
      adb_cmd shell input tap 990 2120 >/dev/null
      sleep 1
      adb_cmd shell input tap 445 2315 >/dev/null
      sleep 1
      ;;
    open_emoji_recents)
      adb_cmd shell input tap 990 2120 >/dev/null
      sleep 1
      adb_cmd shell input tap 425 1990 >/dev/null
      sleep 1
      ;;
    open_unicode)
      adb_cmd shell input tap 105 2245 >/dev/null
      sleep 0.8
      adb_cmd shell input tap 70 2115 >/dev/null
      sleep 4
      ;;
    open_otp_sources)
      adb_cmd shell input tap 990 2120 >/dev/null
      sleep 1
      adb_cmd shell input tap 690 1625 >/dev/null
      sleep 3
      ;;
    *) fail "unknown capture action: $1" ;;
  esac
}

cleanup_capture_action() {
  case "$1" in
    none) ;;
    open_clipboard)
      adb_cmd shell input tap 1000 1685 >/dev/null || true
      sleep 0.5
      ;;
    open_emoji_recents)
      adb_cmd shell input tap 105 2245 >/dev/null || true
      sleep 0.5
      ;;
    open_unicode)
      adb_cmd shell input tap 105 2245 >/dev/null || true
      sleep 0.5
      ;;
    open_otp_sources)
      adb_cmd shell input tap 1000 1685 >/dev/null || true
      sleep 0.5
      ;;
    *) fail "unknown capture action: $1" ;;
  esac
}

main() {
  parse_args "$@"
  validate_selected_scenarios
  ensure_submodules
  ensure_emulator_target
  build_android_projects
  install_android_projects
  seed_fixture_data
  prepare_device
  rebind_tact_ime
  mkdir -p "$RAW_DIR" "$WEB_DIR"
  write_metadata

  local scenario name submodule package activity tap_x tap_y action description
  for scenario in "${SCENARIOS[@]}"; do
    IFS='|' read -r name submodule package activity tap_x tap_y action description <<<"$scenario"
    if scenario_selected "$name"; then
      capture_scenario \
        "$name" \
        "$submodule" \
        "$package" \
        "$activity" \
        "$tap_x" \
        "$tap_y" \
        "$action" \
        "$description"
    fi
  done

  echo "Capture complete: $OUT_DIR"
}

main "$@"
