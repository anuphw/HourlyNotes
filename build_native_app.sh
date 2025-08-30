#!/bin/bash

# Build script for native HourlyNotes app

APP_NAME="HourlyNotes"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building native macOS app..."

# Clean up
rm -rf "$APP_BUNDLE"

# Create app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile Swift code
echo "Compiling Swift code..."
swiftc -o "$MACOS_DIR/$APP_NAME" HourlyNotes.swift \
    -framework Cocoa \
    -framework UserNotifications \
    -O

# Copy icon
cp icon.icns "$RESOURCES_DIR/" 2>/dev/null || echo "Icon not found, skipping"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>HourlyNotes</string>
    <key>CFBundleDisplayName</key>
    <string>Hourly Notes</string>
    <key>CFBundleIdentifier</key>
    <string>com.hourly-notes.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>HourlyNotes</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
</dict>
</plist>
EOF

echo "App bundle created: $APP_BUNDLE"

# Create DMG
echo "Creating DMG installer..."
mkdir -p dmg_temp
cp -R "$APP_BUNDLE" dmg_temp/
ln -s /Applications dmg_temp/Applications

hdiutil create -volname "HourlyNotes" \
    -srcfolder dmg_temp \
    -ov -format UDZO \
    "HourlyNotes.dmg"

rm -rf dmg_temp

echo "✅ Build complete!"
echo "- App: $APP_BUNDLE"
echo "- DMG: HourlyNotes.dmg"
echo ""
echo "To run: open $APP_BUNDLE"
echo "To install: Open HourlyNotes.dmg and drag to Applications"