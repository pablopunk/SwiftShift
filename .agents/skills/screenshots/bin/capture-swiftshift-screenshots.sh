#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
ASSET_DIR="$SKILL_DIR/assets"
OUT_DIR="${1:-$REPO_ROOT/www/src/images}"
DEBUG_DIR="${SWIFTSHIFT_SCREENSHOT_DEBUG_DIR:-$REPO_ROOT/.agents/skills/screenshots/debug}"

APP_NAME="Swift Shift Dev"
BUNDLE_ID="com.pablopunk.Swift-Shift.dev"
# Desired top-left for the actual SwiftShift window content in the 843×670 final.
# Window-only captures may include transparent shadow margins; the script accounts for that.
TARGET_X="${SWIFTSHIFT_SCREENSHOT_X:-255}"
TARGET_Y="${SWIFTSHIFT_SCREENSHOT_Y:-31}"

# Crop for the website mouse-buttons feature visual, derived from the final 843×670 composite.
MOUSE_CROP_X="${SWIFTSHIFT_MOUSE_CROP_X:-125}"
MOUSE_CROP_Y="${SWIFTSHIFT_MOUSE_CROP_Y:-260}"
MOUSE_CROP_W="${SWIFTSHIFT_MOUSE_CROP_W:-633}"
MOUSE_CROP_H="${SWIFTSHIFT_MOUSE_CROP_H:-310}"

mkdir -p "$OUT_DIR" "$DEBUG_DIR"
TMP_DIR="$(mktemp -d)"
ORIGINAL_DARK_MODE=""
ORIGINAL_WALLPAPER=""

log() { printf '› %s\n' "$*"; }
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_bin() {
  command -v "$1" >/dev/null 2>&1 || fail "missing '$1'. Install it and retry."
}

apple_bool() {
  osascript -e "$1" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

capture_state() {
  ORIGINAL_DARK_MODE="$(apple_bool 'tell application "System Events" to tell appearance preferences to get dark mode' || true)"
  ORIGINAL_WALLPAPER="$(osascript -e 'tell application "System Events" to get picture of current desktop' 2>/dev/null || true)"
}

restore_state() {
  set +e
  if [[ -n "$ORIGINAL_DARK_MODE" ]]; then
    osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $ORIGINAL_DARK_MODE" >/dev/null 2>&1
  fi
  if [[ -n "$ORIGINAL_WALLPAPER" ]]; then
    osascript -e "tell application \"System Events\" to set picture of every desktop to \"$ORIGINAL_WALLPAPER\"" >/dev/null 2>&1
  fi
  rm -rf "$TMP_DIR"
}
trap restore_state EXIT

set_appearance() {
  local mode="$1"
  local dark=false
  [[ "$mode" == "dark" ]] && dark=true
  osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $dark" >/dev/null
  sleep 1
}

set_wallpaper() {
  local image="$1"
  osascript -e "tell application \"System Events\" to set picture of every desktop to \"$image\"" >/dev/null || true
  sleep 1
}

hide_other_apps() {
  # Keeps the captured SwiftUI material from picking up random windows behind it.
  osascript >/dev/null <<'APPLESCRIPT' || true
tell application "System Events"
  repeat with p in application processes
    try
      if background only of p is false and name of p is not "Swift Shift Dev" then
        set visible of p to false
      end if
    end try
  end repeat
end tell
APPLESCRIPT
  sleep 0.5
}

open_menu() {
  osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "Swift Shift Dev"
    repeat 40 times
      if exists menu bar 2 then exit repeat
      delay 0.25
    end repeat
    if not (exists menu bar 2) then error "Swift Shift menu bar item was not found"

    click menu bar item 1 of menu bar 2
    delay 0.8
    if (count of windows) is 0 then
      click menu bar item 1 of menu bar 2
      delay 0.8
    end if
    if (count of windows) is 0 then error "Swift Shift settings window did not open"
  end tell
end tell
APPLESCRIPT
}

swiftshift_window_info() {
  peekaboo list windows --app "$APP_NAME" --json | python3 -c 'import json,sys; w=json.load(sys.stdin)["data"]["windows"][0]; b=w["bounds"]; print("{},{},{},{},{}".format(w["window_id"], int(b[0][0]), int(b[0][1]), int(b[1][0]), int(b[1][1])))'
}

alpha_bbox() {
  local image="$1"
  magick "$image" -alpha extract -threshold 90% -format '%@' info:
}

bbox_offset_x() {
  printf '%s' "$1" | sed -E 's/^[0-9]+x[0-9]+\+([0-9]+)\+([0-9]+)$/\1/'
}

bbox_offset_y() {
  printf '%s' "$1" | sed -E 's/^[0-9]+x[0-9]+\+([0-9]+)\+([0-9]+)$/\2/'
}

capture_theme() {
  local mode="$1"
  local bg="$ASSET_DIR/bg-$mode.jpg"
  local wallpaper="$ASSET_DIR/wallpaper-$mode.jpg"
  local out="$OUT_DIR/screenshot-$mode.jpg"
  local mouse_out="$OUT_DIR/mouse-$mode.jpg"
  local debug_bg="$DEBUG_DIR/01-backplate-$mode.jpg"
  local full_screen="$TMP_DIR/full-screen-$mode.png"
  local window="$DEBUG_DIR/02-window-alpha-$mode.png"
  local screen_crop="$DEBUG_DIR/03-screen-tint-crop-$mode.png"
  local content_overlay="$DEBUG_DIR/04-content-tint-overlay-$mode.png"
  local tinted_window="$DEBUG_DIR/05-tinted-window-$mode.png"
  local final="$DEBUG_DIR/06-final-$mode.jpg"

  [[ -f "$bg" ]] || fail "missing background asset: $bg"
  [[ -f "$wallpaper" ]] || fail "missing wallpaper asset: $wallpaper"

  log "capturing $mode screenshot"
  cp "$bg" "$debug_bg"
  set_appearance "$mode"
  set_wallpaper "$wallpaper"
  hide_other_apps
  open_menu >/dev/null

  local info window_id x y w h
  info="$(swiftshift_window_info)"
  IFS=',' read -r window_id x y w h <<< "$info"
  [[ -n "$window_id" && -n "$x" && -n "$y" && -n "$w" && -n "$h" ]] || fail "could not parse Swift Shift window info: $info"

  # Window-only capture gives us the real rounded-corner/shadow alpha.
  screencapture -x -l"$window_id" -t png "$window"

  local bbox offset_x offset_y capture_w capture_h crop_x crop_y image_x image_y
  bbox="$(alpha_bbox "$window")"
  offset_x="$(bbox_offset_x "$bbox")"
  offset_y="$(bbox_offset_y "$bbox")"
  capture_w="$(magick identify -format '%w' "$window")"
  capture_h="$(magick identify -format '%h' "$window")"
  crop_x=$((x - offset_x))
  crop_y=$((y - offset_y))
  image_x=$((TARGET_X - offset_x))
  image_y=$((TARGET_Y - offset_y))

  # Full-screen crop has the correct SwiftUI material tint from the real wallpaper.
  peekaboo image --mode screen --screen-index 0 --path "$full_screen" --format png >/dev/null
  magick "$full_screen" -crop "${capture_w}x${capture_h}+${crop_x}+${crop_y}" +repage "$screen_crop"

  # Keep the clean window-only shadow/rounded edges, but replace the opaque window interior
  # with the full-screen crop so SwiftUI glass keeps the real wallpaper tint. The hard
  # threshold prevents real menu-bar pixels from leaking into the top shadow margin.
  magick "$screen_crop" \( "$window" -alpha extract -threshold 90% \) -compose CopyOpacity -composite "$content_overlay"
  magick "$window" "$content_overlay" -compose Over -composite "$tinted_window"

  magick "$bg" "$tinted_window" -geometry "+${image_x}+${image_y}" -composite -quality 92 "$out"
  magick "$out" -crop "${MOUSE_CROP_W}x${MOUSE_CROP_H}+${MOUSE_CROP_X}+${MOUSE_CROP_Y}" +repage -quality 92 "$mouse_out"
  cp "$out" "$final"
  cp "$mouse_out" "$DEBUG_DIR/07-mouse-crop-$mode.jpg"
  log "wrote $out"
  log "wrote $mouse_out"
  log "debug: $debug_bg"
  log "debug: $window"
  log "debug: $screen_crop"
  log "debug: $content_overlay"
  log "debug: $tinted_window"
  log "debug: $final"
  log "debug: $DEBUG_DIR/07-mouse-crop-$mode.jpg"
  # Close the menu extra before switching themes.
  osascript -e 'tell application "System Events" to key code 53' >/dev/null 2>&1 || true
  sleep 0.3
}

main() {
  require_bin osascript
  require_bin make
  require_bin peekaboo
  require_bin magick
  require_bin python3
  require_bin screencapture

  [[ -d "$REPO_ROOT/www/src/images" ]] || fail "could not find repo root from $REPO_ROOT"

  peekaboo permissions --json >/dev/null || fail "Peekaboo needs Screen Recording + Accessibility permissions"
  capture_state

  log "building and running $APP_NAME"
  defaults write "$BUNDLE_ID" showMenuBarIcon -bool true >/dev/null 2>&1 || true
  (cd "$REPO_ROOT" && make build >/dev/null && make run-app >/dev/null)
  sleep 2

  capture_theme light
  capture_theme dark

  log "done"
}

main "$@"
