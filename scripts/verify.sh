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

SCHEME="${SCHEME:-ForgeKit}"

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
