#!/bin/zsh
set -euo pipefail

APP_NAME="Swift Shift"
APP_NAME_NO_SPACE="SwiftShift"
SCHEME="Swift Shift"
NOTARY_PROFILE="SwiftShift"
TEAM_ID=$(grep -m1 'DEVELOPMENT_TEAM' "$APP_NAME.xcodeproj/project.pbxproj" | sed 's/.*= //;s/;.*//')
BUILD_DIR="$(pwd)/build/release"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME_NO_SPACE.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"

# --- Parse arguments ---
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: make release VERSION=x.y.z"
    exit 1
fi

echo "🚀 Releasing $APP_NAME v$VERSION"
echo ""

# --- 1. Bump version in project.pbxproj ---
echo "📝 Bumping version to $VERSION..."
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" "$APP_NAME.xcodeproj/project.pbxproj"
sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $VERSION;/g" "$APP_NAME.xcodeproj/project.pbxproj"

# --- Patch ExportOptions.plist with team ID ---
sed -i '' "s/REPLACE_TEAM_ID/$TEAM_ID/g" ExportOptions.plist
trap 'sed -i "" "s/$TEAM_ID/REPLACE_TEAM_ID/g" ExportOptions.plist' EXIT

# --- 2. Archive ---
echo "📦 Archiving..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
xcodebuild archive \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    2>&1 | tail -1

# --- 3. Export ---
echo "📤 Exporting..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath "$EXPORT_DIR" \
    2>&1 | tail -1

# --- 4. Notarize ---
echo "🔏 Notarizing (this may take a few minutes)..."
ZIP_PATH="$EXPORT_DIR/$APP_NAME_NO_SPACE.zip"
pushd "$EXPORT_DIR" > /dev/null
zip -9 -y -r -q "$APP_NAME_NO_SPACE.zip" "$APP_NAME.app"
popd > /dev/null

xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

# --- 5. Staple ---
echo "📎 Stapling..."
xcrun stapler staple "$EXPORT_DIR/$APP_NAME.app"

# Re-zip after stapling
rm "$ZIP_PATH"
pushd "$EXPORT_DIR" > /dev/null
zip -9 -y -r -q "$APP_NAME_NO_SPACE.zip" "$APP_NAME.app"
popd > /dev/null

# --- 6. Generate appcast ---
echo "📡 Generating appcast..."
cp ./appcast.xml "$EXPORT_DIR"

generate_appcast=$(find ~/Library/Developer/Xcode/DerivedData/Swift* -type f -name "*generate_appcast" | head -1)
bin_folder=$(dirname "$generate_appcast")

"$generate_appcast" "$EXPORT_DIR"
"$bin_folder/sign_update" "$ZIP_PATH"

sed -i '' 's|https://pablopunk.github.io/SwiftShift/SwiftShift.zip|https://github.com/pablopunk/SwiftShift/releases/latest/download/SwiftShift.zip|g' "$EXPORT_DIR/appcast.xml"
cp "$EXPORT_DIR/appcast.xml" .

# --- 7. Git: branch, commit, tag, push ---
echo "🔖 Creating branch, commit, and tag..."
git checkout -b "release/$VERSION"
git add -A
git commit -m "$VERSION"
git tag "$VERSION"
git push -u origin "release/$VERSION"
git push --tags

# --- 8. Create PR with auto-merge ---
echo "🔀 Creating PR..."
PR_URL=$(gh pr create --title "$VERSION" --body "Release $VERSION" --base main)
gh pr merge "$PR_URL" --squash

# --- 9. Create GitHub release ---
echo "🎉 Creating GitHub release..."
gh release create "$VERSION" "$ZIP_PATH" \
    --title "$VERSION" \
    --generate-notes

echo ""
echo "✅ Release $VERSION complete!"
echo "   PR: $PR_URL"
echo "   Release: https://github.com/pablopunk/SwiftShift/releases/tag/$VERSION"
