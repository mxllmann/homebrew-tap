#!/usr/bin/env bash
# Point the formula at a released tag and fill in its sha256.
#
#   ./bump.sh batcycle 0.1.0
#
# Run it after the tag exists on GitHub (git tag v0.1.0 && git push --tags).
set -euo pipefail

FORMULA=${1:?usage: ./bump.sh <formula> <version>}
VERSION=${2:?usage: ./bump.sh <formula> <version>}
OWNER=mxllmann

FILE="Formula/${FORMULA}.rb"
URL="https://github.com/${OWNER}/${FORMULA}/archive/refs/tags/v${VERSION}.tar.gz"

[ -f "$FILE" ] || { echo "no such formula: $FILE" >&2; exit 1; }

echo "fetching $URL"
if ! SHA=$(curl -fsSL "$URL" | shasum -a 256 | cut -d' ' -f1); then
  echo "could not fetch the tarball — is the tag pushed?" >&2
  exit 1
fi

/usr/bin/sed -i '' \
  -e "s|url \".*\"|url \"${URL}\"|" \
  -e "s|sha256 \".*\"|sha256 \"${SHA}\"|" \
  "$FILE"

echo "$FILE → v${VERSION}"
echo "  sha256 ${SHA}"
echo
echo "verify with: brew install --build-from-source ./${FILE}"
