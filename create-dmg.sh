#!/bin/zsh

export_root="$HOME/Downloads"
export_dmg="$export_root/Swift Shift.dmg"
export_folder="$export_root/Swift Shift $datetime"
source=$1

if [[ -z $source ]]; then
  echo "Usage: ./create-dmg.sh <folder containing 'Swift Shift.app'>"
  exit 1
fi

if ! command -v create-dmg &> /dev/null; then
  echo "create-dmg not found, installing with brew..."
  brew install create-dmg > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "create-dmg installed successfully!"
  else
    echo "Failed to install create-dmg. Please check your homebrew installation."
    exit 1
  fi
fi

code_sign="$(security find-identity | awk '/1\)/ {print $2}' | head -n1)"

create-dmg \
  --volname "Swift Shift Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon "Swift Shift.app" 200 190 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  --codesign $code_sign \
  --notarize "pablopunk" \
  "$export_dmg" \
  $source

if [[ ! $? -eq 0 ]]; then
  exit 1
fi

mkdir -p "$export_folder"
mv "$export_dmg" "$export_folder"

# To create a notary profile:
# xcrun notarytool store-credentials "whatever" --apple-id "your-apple-id-email" --password "password from https://appleid.apple.com/account/manage" --team-id "team id from https://developer.apple.com/account/#!/membership/"

~/Library/Developer/Xcode/DerivedData/Swift_Shift-bndpbztptwctfnfyomhnqxdebrcp/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast $export_folder
