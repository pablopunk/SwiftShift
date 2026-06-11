---
name: screenshots
description: Capture and regenerate SwiftShift marketing screenshots for README/website assets. Use when updating light/dark SwiftShift screenshots, especially `www/src/images/screenshot-light.jpg` and `www/src/images/screenshot-dark.jpg`.
---

# SwiftShift screenshots

This skill regenerates the app settings screenshots as clean 843×670 composites:

- clean background + empty menu bar skeletons live in `assets/bg-light.jpg` and `assets/bg-dark.jpg`
- real desktop wallpapers live in `assets/wallpaper-light.jpg` and `assets/wallpaper-dark.jpg`
- fresh Swift Shift Dev settings window is captured from the local build using macOS window capture plus a full-screen tint crop
- full screenshot outputs default to `www/src/images/screenshot-light.jpg` and `www/src/images/screenshot-dark.jpg`
- mouse feature crops default to `www/src/images/mouse-light.jpg` and `www/src/images/mouse-dark.jpg`
- debug step images are written to `.agents/skills/screenshots/debug/`

## Requirements

- macOS
- `peekaboo` with Screen Recording and Accessibility permissions
- ImageMagick (`magick`): `brew install imagemagick`
- `python3` and macOS `screencapture`
- Xcode command line build works for this repo

## Command

From the repo root:

```bash
.agents/skills/screenshots/bin/capture-swiftshift-screenshots.sh
```

Optional output directory:

```bash
.agents/skills/screenshots/bin/capture-swiftshift-screenshots.sh /tmp/swiftshift-screenshots
```

## What the script does

1. Saves current appearance and wallpaper.
2. Builds and runs the local dev app with `make build && make run-app`.
3. Temporarily switches to light mode, applies `assets/wallpaper-light.jpg` as the real desktop wallpaper, hides other apps, and opens the Swift Shift menu bar window.
4. Captures the window-only PNG by CoreGraphics window id for rounded-corner/shadow alpha.
5. Captures a full-screen image and crops the same window rectangle for the true SwiftUI material tint from the real wallpaper.
6. Applies the window-only alpha to the tinted crop and composites that onto `assets/bg-light.jpg`.
7. Repeats for dark mode with `assets/wallpaper-dark.jpg` and `assets/bg-dark.jpg`.
8. Restores the original appearance and wallpaper.

The script intentionally uses clean skeleton backgrounds so the final menu bar contains only the SwiftShift icon, while the app window keeps the real glass tint from the matching wallpaper.

## Layout constants

The app window is placed at `+255+31` in the final 843×670 image. The mouse feature visual is cropped from that final image at `633×310+125+260`.

Override if the design changes:

```bash
SWIFTSHIFT_SCREENSHOT_X=250 SWIFTSHIFT_SCREENSHOT_Y=31 \
SWIFTSHIFT_MOUSE_CROP_X=125 SWIFTSHIFT_MOUSE_CROP_Y=260 \
  .agents/skills/screenshots/bin/capture-swiftshift-screenshots.sh
```

## Notes

- The script will briefly change the Mac appearance/wallpaper and hide visible apps.
- If the app UI gets taller/wider, update the background skeletons and placement constants together.
