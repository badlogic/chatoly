#!/bin/bash

# Chatoly NPM Publishing Script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current version from package.json
VERSION=$(node -p "require('./package.json').version")
log_info "Publishing version $VERSION"

# Ensure git is clean
if [ -n "$(git status --porcelain)" ]; then
    log_error "Git working directory not clean. Commit changes first."
    exit 1
fi

# Tag current commit
log_info "Tagging commit as v$VERSION..."
git tag -a "v$VERSION" -m "Release v$VERSION"

# Build and notarize
log_info "Building and notarizing..."
./build.sh notarize

# Verify the notarized binary exists
if [ ! -f "bin/chatoly" ]; then
    log_error "Notarized binary not found at bin/chatoly"
    exit 1
fi

# Verify the binary is properly signed and notarized
log_info "Verifying notarization..."

# Check code signature
codesign -vv bin/chatoly 2>&1
if [ $? -ne 0 ]; then
    log_error "Binary is not properly signed"
    exit 1
fi

# Check notarization with spctl (Gatekeeper)
spctl -a -vvv -t install bin/chatoly 2>&1
if [ $? -ne 0 ]; then
    log_error "Binary failed Gatekeeper verification - not properly notarized"
    exit 1
fi

# Verify it's executable
if [ ! -x "bin/chatoly" ]; then
    log_error "Binary is not executable"
    exit 1
fi

log_info "✅ Binary is properly signed, notarized, and executable"

# Publish to npm
log_info "Publishing to npm..."
npm publish --access public

# Push tag
log_info "Pushing tag to git..."
git push origin "v$VERSION"

# Bump patch version
log_info "Bumping patch version..."
npm version patch --no-git-tag-version

# Commit version bump
NEW_VERSION=$(node -p "require('./package.json').version")
git add package.json
git commit -m "Bump version to $NEW_VERSION"

log_info "✅ Published v$VERSION successfully!"
log_info "✅ Bumped to v$NEW_VERSION for next release"