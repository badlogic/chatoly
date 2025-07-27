#!/bin/bash

set -e

PROJECT_NAME="chatoly"
BUILD_DIR=".build"

# Signing configuration
DISTRIBUTION_CERT="Developer ID Application: Mario Zechner (7F5Y92G2Z4)"
TEAM_ID="7F5Y92G2Z4"
APPLE_ID="contact@badlogicgames.com"

function clean() {
    echo "🧹 Cleaning build artifacts..."
    rm -rf $BUILD_DIR
    rm -rf bin
    echo "✅ Clean completed"
}

function build_debug() {
    echo "🔨 Building in debug mode..."
    swift build --configuration debug
    echo "✅ Debug build completed"
    echo "📍 Executable: $BUILD_DIR/debug/$PROJECT_NAME"
}

function build_release() {
    echo "🚀 Building in release mode..."
    swift build --configuration release
    echo "✅ Release build completed"
    echo "📍 Executable: $BUILD_DIR/release/$PROJECT_NAME"
}

function run_executable() {
    local config="${1:-debug}"
    local executable="$BUILD_DIR/$config/$PROJECT_NAME"
    
    if [[ ! -f "$executable" ]]; then
        echo "❌ Executable not found: $executable"
        echo "💡 Building $config mode first..."
        if [[ "$config" == "release" ]]; then
            build_release
        else
            build_debug
        fi
    fi
    
    echo "🚀 Running $executable..."
    exec "$executable"
}

function notarize_build() {
    echo "🔏 Starting notarization build..."
    
    # Check prerequisites
    if [ -z "$NOTARY_TOOL_PASSWORD" ]; then
        echo "❌ NOTARY_TOOL_PASSWORD not set"
        echo "💡 Add 'export NOTARY_TOOL_PASSWORD=\"your-app-specific-password\"' to ~/.zshrc"
        exit 1
    fi
    
    # Clean and build release
    clean
    build_release
    
    # Create bin directory
    mkdir -p bin
    
    # Sign executable
    echo "📝 Signing executable..."
    codesign --force --sign "$DISTRIBUTION_CERT" \
        --options runtime \
        --timestamp \
        "$BUILD_DIR/release/$PROJECT_NAME"
    
    if [ $? -ne 0 ]; then
        echo "❌ Code signing failed"
        exit 1
    fi
    
    # Create zip for notarization
    echo "📦 Creating zip for notarization..."
    zip -j chatoly.zip "$BUILD_DIR/release/$PROJECT_NAME"
    
    # Submit for notarization
    echo "☁️  Submitting for notarization (this may take a few minutes)..."
    xcrun notarytool submit chatoly.zip \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$NOTARY_TOOL_PASSWORD" \
        --wait
    
    if [ $? -ne 0 ]; then
        echo "❌ Notarization failed"
        rm chatoly.zip
        exit 1
    fi
    
    # Extract notarized binary to bin/
    echo "📤 Extracting notarized binary..."
    unzip -o chatoly.zip -d bin/
    rm chatoly.zip
    chmod +x "bin/$PROJECT_NAME"
    
    echo "✅ Notarization completed!"
    echo "📍 Notarized executable: bin/$PROJECT_NAME"
}

function show_help() {
    echo "Usage: $0 [clean] [release] [run] [notarize] [help]"
    echo ""
    echo "Commands can be combined (except notarize):"
    echo "  (no args)          Build debug"
    echo "  release            Build release"
    echo "  run                Build debug (if needed) and run"
    echo "  release run        Build release (if needed) and run"
    echo "  clean              Clean and build debug"
    echo "  clean release      Clean and build release"
    echo "  clean run          Clean, build debug, and run"
    echo "  clean release run  Clean, build release, and run"
    echo "  notarize           Clean, build, sign, and notarize for distribution"
    echo "  help               Show this help message"
}

# Check for notarize first (it must be used alone)
if [[ "$1" == "notarize" ]]; then
    if [[ "$#" -ne 1 ]]; then
        echo "❌ 'notarize' must be used alone"
        show_help
        exit 1
    fi
    notarize_build
    exit 0
fi

# Parse arguments
DO_CLEAN=false
DO_RELEASE=false
DO_RUN=false
DO_HELP=false

for arg in "$@"; do
    case "$arg" in
        "clean")
            DO_CLEAN=true
            ;;
        "release")
            DO_RELEASE=true
            ;;
        "run")
            DO_RUN=true
            ;;
        "help"|"-h"|"--help")
            DO_HELP=true
            ;;
        *)
            echo "❌ Unknown command: $arg"
            show_help
            exit 1
            ;;
    esac
done

# Execute commands
if [[ "$DO_HELP" == true ]]; then
    show_help
    exit 0
fi

# Clean if requested
if [[ "$DO_CLEAN" == true ]]; then
    clean
fi

# Determine build configuration
if [[ "$DO_RUN" == true ]] || [[ "$#" -eq 0 ]] || [[ "$DO_CLEAN" == true && "$DO_RUN" == false && "$DO_RELEASE" == false ]]; then
    # Build is needed
    if [[ "$DO_RELEASE" == true ]]; then
        build_release
        CONFIG="release"
    else
        build_debug
        CONFIG="debug"
    fi
elif [[ "$DO_RELEASE" == true ]]; then
    build_release
    CONFIG="release"
fi

# Run if requested
if [[ "$DO_RUN" == true ]]; then
    run_executable "$CONFIG"
fi