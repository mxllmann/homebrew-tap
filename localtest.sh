#!/usr/bin/env bash
# Install a formula straight from the working tree — no tag, no push, no GitHub.
#
#   ./localtest.sh batcycle
#
# Packages ../<formula> into a tarball, points a copy of the real formula at it,
# and drops that into a local tap. What gets exercised is the actual formula:
# the same install block, caveats and test block that ship, so a layout mistake
# surfaces here rather than after tagging.
#
# `bump.sh` is the other half — that one points the formula at a released tag.
set -euo pipefail

cd "$(dirname "$0")"

FORMULA=${1:-batcycle}
SRC=${2:-../$FORMULA}
TAP_NAME=mxllmann/localtest
TAP="$(brew --repo)/Library/Taps/mxllmann/homebrew-localtest"

[ -f "Formula/${FORMULA}.rb" ] || { echo "no such formula: Formula/${FORMULA}.rb" >&2; exit 1; }
[ -d "$SRC" ]                  || { echo "no source tree at: $SRC" >&2; exit 1; }

if [ ! -d "$TAP" ]; then
  echo "local tap missing. Create it once with:" >&2
  echo "    brew tap-new $TAP_NAME" >&2
  exit 1
fi

VERSION=$(/usr/bin/sed -n 's/^__version__ = "\(.*\)"$/\1/p' "$SRC/$FORMULA" | head -1)
[ -n "$VERSION" ] || { echo "could not read __version__ from $SRC/$FORMULA" >&2; exit 1; }

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# GitHub's archives wrap everything in <name>-<version>/, and Homebrew strips one
# leading component. Reproduce that, or the formula's paths are all off by one.
DIR="$STAGE/${FORMULA}-${VERSION}"
mkdir -p "$DIR"
/usr/bin/tar -cf - -C "$SRC" \
  --exclude .git --exclude .build --exclude build --exclude .DS_Store \
  . | /usr/bin/tar -xf - -C "$DIR"

TARBALL="/tmp/${FORMULA}-${VERSION}-localtest.tar.gz"
/usr/bin/tar -czf "$TARBALL" -C "$STAGE" "${FORMULA}-${VERSION}"
SHA=$(/usr/bin/shasum -a 256 "$TARBALL" | cut -d' ' -f1)

mkdir -p "$TAP/Formula"
/usr/bin/sed \
  -e "s|url \".*\"|url \"file://${TARBALL}\"|" \
  -e "s|sha256 \".*\"|sha256 \"${SHA}\"|" \
  "Formula/${FORMULA}.rb" > "$TAP/Formula/${FORMULA}.rb"

echo "packaged  ${FORMULA} ${VERSION}"
echo "tarball   $TARBALL"
echo "sha256    $SHA"
echo "formula   $TAP/Formula/${FORMULA}.rb"
echo
echo "Install with:"
echo "    brew install --build-from-source ${TAP_NAME}/${FORMULA}"
