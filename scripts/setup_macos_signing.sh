#!/bin/bash

# Setup macOS Code Signing for 1Panel Client
# This script helps configure code signing for local development

set -e

echo "🔐 Setting up macOS Code Signing..."
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

echo "📋 Available signing identities:"
echo ""
security find-identity -v -p codesigning | grep "Apple Development" || echo "No Apple Development certificates found"
echo ""

# Check if user has any signing identity
if ! security find-identity -v -p codesigning | grep -q "Apple Development"; then
    echo "⚠️  No Apple Development certificate found."
    echo ""
    echo "To fix this:"
    echo "1. Open Xcode"
    echo "2. Go to Xcode > Settings > Accounts"
    echo "3. Add your Apple ID if not already added"
    echo "4. Select your Apple ID and click 'Manage Certificates'"
    echo "5. Click '+' and select 'Apple Development'"
    echo ""
    echo "Or simply open the project in Xcode and it will guide you:"
    echo "  open macos/Runner.xcworkspace"
    echo ""
    exit 1
fi

echo "✅ Found Apple Development certificate"
echo ""
echo "Opening project in Xcode..."
echo "Please configure signing in Xcode:"
echo "  1. Select 'Runner' project in left sidebar"
echo "  2. Select 'Runner' target"
echo "  3. Go to 'Signing & Capabilities' tab"
echo "  4. Check 'Automatically manage signing'"
echo "  5. Select your team from dropdown"
echo ""

open macos/Runner.xcworkspace

echo ""
echo "After configuring signing in Xcode, you can run:"
echo "  flutter run -d macos"
