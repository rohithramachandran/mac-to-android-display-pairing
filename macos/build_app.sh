#!/usr/bin/env bash
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
APP_NAME="MacStreamer"
DIST="$(cd "$(dirname "$0")" && pwd)/dist"
APP_BUNDLE="$DIST/$APP_NAME.app"
DMG_PATH="$DIST/$APP_NAME.dmg"

# ── Build ─────────────────────────────────────────────────────────────────────
echo "📦 Building $APP_NAME (release)…"
cd "$(dirname "$0")"
swift build -c release 2>&1

BINARY=".build/release/$APP_NAME"
if [ ! -f "$BINARY" ]; then
    echo "❌ Build failed – binary not found at $BINARY"
    exit 1
fi
echo "✅ Build succeeded"

# ── Bundle ────────────────────────────────────────────────────────────────────
echo "🗂  Creating .app bundle…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"

# Copy icon – prefer .icns (required for dock), fall back to PNG
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "🖼  App icon (icns) copied"
elif [ -f "AppIcon.png" ]; then
    cp AppIcon.png "$APP_BUNDLE/Contents/Resources/AppIcon.png"
    echo "🖼  App icon (png) copied — run sips+iconutil to get a proper dock icon"
fi

echo "✅ Bundle: $APP_BUNDLE"

# ── DMG ───────────────────────────────────────────────────────────────────────
echo "💿 Creating DMG…"
rm -f "$DMG_PATH"
mkdir -p "$DIST"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$APP_BUNDLE" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo ""
echo "🎉 Done!"
echo "   App:  $APP_BUNDLE"
echo "   DMG:  $DMG_PATH"
echo ""
echo "💡 Tip: open $APP_BUNDLE to run instantly, or share $DMG_PATH"
