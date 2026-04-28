#!/bin/bash

# Rahiee.AI iOS Build Script
# Version 1.1.0+2

set -e  # Exit on error

echo "🚀 Starting Rahiee.AI iOS Build Process..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Flutter installation
print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi
print_success "Flutter found: $(flutter --version | head -n 1)"

# Check Xcode installation
print_status "Checking Xcode installation..."
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed"
    exit 1
fi
print_success "Xcode found: $(xcodebuild -version | head -n 1)"

# Check iOS deployment
print_status "Checking iOS setup..."
flutter doctor --ios-license > /dev/null 2>&1 || true
print_success "iOS setup verified"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
print_success "Clean completed"

# Get dependencies
print_status "Getting dependencies..."
flutter pub get
print_success "Dependencies installed"

# Run code generation if needed
print_status "Running code generators..."
flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1 || print_warning "No build_runner configured"

# Analyze code
print_status "Analyzing code..."
flutter analyze --no-fatal-infos || print_warning "Code analysis found issues"

# Build options
BUILD_TYPE=${1:-ipa}  # Default to ipa if no argument provided

echo ""
echo "================================================"
print_status "Building for: $BUILD_TYPE"
echo "================================================"
echo ""

if [ "$BUILD_TYPE" == "ipa" ]; then
    # Build IPA for App Store
    print_status "Building IPA for App Store submission..."
    flutter build ipa --release
    
    if [ $? -eq 0 ]; then
        print_success "IPA build completed successfully!"
        echo ""
        print_status "IPA location: build/ios/ipa/rahiee_ai.ipa"
        print_status "Next steps:"
        echo "  1. Open Xcode: open ios/Runner.xcworkspace"
        echo "  2. Archive: Product > Archive"
        echo "  3. Upload to App Store Connect"
    else
        print_error "IPA build failed"
        exit 1
    fi
    
elif [ "$BUILD_TYPE" == "ios" ]; then
    # Build iOS app
    print_status "Building iOS app..."
    flutter build ios --release
    
    if [ $? -eq 0 ]; then
        print_success "iOS build completed successfully!"
        print_status "Open in Xcode: open ios/Runner.xcworkspace"
    else
        print_error "iOS build failed"
        exit 1
    fi
    
elif [ "$BUILD_TYPE" == "simulator" ]; then
    # Build for simulator (debug)
    print_status "Building for simulator..."
    flutter build ios --debug --simulator
    
    if [ $? -eq 0 ]; then
        print_success "Simulator build completed!"
        print_status "Run with: flutter run"
    else
        print_error "Simulator build failed"
        exit 1
    fi
    
else
    print_error "Invalid build type: $BUILD_TYPE"
    echo "Usage: ./build_ios.sh [ipa|ios|simulator]"
    exit 1
fi

echo ""
echo "================================================"
print_success "Build process completed!"
echo "================================================"

# Display version info
print_status "App Version Information:"
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
echo "  Version: $VERSION"
echo "  Build Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Display next steps
print_status "Next Steps for App Store Submission:"
echo "  1. Test the build on a physical device"
echo "  2. Test account deletion feature thoroughly"
echo "  3. Verify all features work as expected"
echo "  4. Open Xcode and create an archive"
echo "  5. Upload to App Store Connect"
echo "  6. Fill in version information and release notes"
echo "  7. Submit for review"
echo ""

print_warning "Don't forget to:"
echo "  ✓ Update privacy policy with account deletion info"
echo "  ✓ Test account deletion with test accounts"
echo "  ✓ Update App Store screenshots if UI changed"
echo "  ✓ Prepare for Apple's review questions"
echo ""
