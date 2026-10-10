#!/usr/bin/env bash
# The full local verification for this repository: generate the project from the manifest,
# then build and test it on a simulator. This is what CI runs, so a green run here means a
# green run there.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "required command not found: $1" >&2; exit 1; }
}
require_command tuist
require_command xcodebuild
require_command xcrun

# The installed tuist CLI (brew cask binary) has no auto-switching mechanism: a
# `.tuist-version` file sitting next to it is simply never read (confirmed by pointing one at a
# bogus version and observing tuist ignore it). So the only way to catch local/CI drift is to
# pin the verified-working version here and fail loudly the moment the installed CLI disagrees,
# rather than silently trusting whatever `brew install tuist` happens to resolve that day.
if [ -f .tuist-version ]; then
  REQUIRED_TUIST_VERSION="$(tr -d '[:space:]' < .tuist-version)"
  INSTALLED_TUIST_VERSION="$(tuist version 2>/dev/null | tr -d '[:space:]')"
  if [ "$INSTALLED_TUIST_VERSION" != "$REQUIRED_TUIST_VERSION" ]; then
    echo "tuist version mismatch: .tuist-version pins $REQUIRED_TUIST_VERSION but the installed tuist reports $INSTALLED_TUIST_VERSION" >&2
    echo "install the pinned version, or update .tuist-version once the new version has been verified" >&2
    exit 1
  fi
fi

# The scheme/workspace name is derived from Project.swift's appName rather than hardcoded:
# renaming a product happens by editing that one line, and a literal fallback here would mean
# this script keeps testing "ForgeKit" after the project has been renamed to something else.
DEFAULT_SCHEME=$(grep -m1 '^let appName = ' Project.swift | sed -E 's/^let appName = "(.*)"$/\1/')
if [ -z "$DEFAULT_SCHEME" ]; then
  echo "could not derive appName from Project.swift — set SCHEME explicitly" >&2
  exit 1
fi
SCHEME="${SCHEME:-$DEFAULT_SCHEME}"

echo "==> tuist generate"
tuist generate --no-open || exit 1

# The simulator is resolved rather than hardcoded: a fixed device name is the line that breaks
# on the next machine, and on the CI image, for a reason that has nothing to do with the code.
# Picking the newest installed iPhone keeps this working across Xcode updates.
echo "==> Resolving a simulator"
# awk's two-argument match with RSTART/RLENGTH, not gawk's three-argument capture form:
# macOS ships BSD awk, which rejects the latter outright — and a resolver that errors out
# reports "no simulator available" on a machine that has several.
DESTINATION_ID=$(xcrun simctl list devices available 2>/dev/null \
  | awk '/^-- iOS/ { runtime = $3; next }
         /iPhone/ && match($0, /\([0-9A-F-]+\)/) { print runtime "\t" substr($0, RSTART + 1, RLENGTH - 2) }' \
  | sort -V | tail -1 | cut -f2)

if [ -z "$DESTINATION_ID" ]; then
  echo "no iOS simulator is available — install one in Xcode, or run: xcodebuild -downloadPlatform iOS" >&2
  exit 1
fi
echo "  using simulator $DESTINATION_ID"

echo "==> xcodebuild test"
xcodebuild test \
  -workspace "$SCHEME.xcworkspace" \
  -scheme "$SCHEME" \
  -destination "id=$DESTINATION_ID" \
  || exit 1

echo
echo "Verified: project generates, builds, and tests pass."
