# Chatoly

A simple macOS YouTube chat overlay application that displays YouTube live stream chat in an always-on-top window. Perfect for live-streams where you want to actually see on screen when chat presses F.

https://github.com/user-attachments/assets/ecc489bd-8649-4321-aa45-ccf3c0eb5415

*<sub>Watch this thing get built from scratch in [2 hours](https://www.youtube.com/watch?v=0YsGtKKWEn4)</sub>*

## Installation

```bash
npm install -g @mariozechner/chatoly
chatoly
```

## Features

- **Always on top** - Chat window stays above all other applications
- **Movable & Resizable** - Position and size the chat window exactly where you need it
- **YouTube live stream chat** - Works with any YouTube live stream or video with chat

## Development

### Building

```bash
# Build debug mode (default)
./build.sh

# Build release mode
./build.sh release

# Clean and build
./build.sh clean

# Build and run the main app
./build.sh run

# Build release and run
./build.sh release run

# Build for distribution (signs and notarizes both executables)
./build.sh notarize
```

### Executables

The project builds two executables:

1. **`chatoly`** - The main GUI application with the overlay window
2. **`chatoly-stream`** - A CLI tool for streaming YouTube chat to console (useful for debugging/testing)

After building, executables are located in:
- Debug: `./.build/debug/chatoly` and `./.build/debug/chatoly-stream`
- Release: `./.build/release/chatoly` and `./.build/release/chatoly-stream`

```bash
# Run the stream CLI tool after building
./build.sh
./.build/debug/chatoly-stream

# Or use Swift directly
swift build
swift run chatoly-stream
```

For notarization to work, you need an Apple Developer account with a valid Developer ID certificate. Set the `NOTARY_TOOL_PASSWORD` environment variable with an app-specific password generated from your Apple ID account. The build script expects your certificate to be named "Developer ID Application" in your keychain. You'll also need your Team ID from your Apple Developer account. Without these, use the regular build commands which produce unsigned binaries that work locally but may trigger Gatekeeper warnings when shared.

### Requirements

- macOS 13.0+
- Swift 6.0+
