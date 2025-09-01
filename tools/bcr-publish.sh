#!/bin/bash
# BCR Publishing Helper Script
# This script assists with publishing to Bazel Central Registry

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
    echo "Usage: $0 <version>"
    echo "  version: The version tag (e.g., bazel-1.0.0)"
    echo ""
    echo "This script prepares BCR submission files for the given version."
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

VERSION_TAG="$1"
VERSION="${VERSION_TAG#bazel-}"

echo "Preparing BCR submission for version: $VERSION"

# Create submission directory
SUBMISSION_DIR="${REPO_ROOT}/bcr-submission/modules/envoy_toolshed/${VERSION}"
mkdir -p "$SUBMISSION_DIR"

# Calculate source archive details
ARCHIVE_URL="https://github.com/mmorel-35/toolshed/archive/${VERSION_TAG}.tar.gz"
echo "Downloading source archive: $ARCHIVE_URL"

TEMP_ARCHIVE=$(mktemp)
curl -L -o "$TEMP_ARCHIVE" "$ARCHIVE_URL"
SHA256=$(sha256sum "$TEMP_ARCHIVE" | cut -d' ' -f1)
rm "$TEMP_ARCHIVE"

STRIP_PREFIX="toolshed-${VERSION}"

echo "Archive SHA256: $SHA256"
echo "Strip prefix: $STRIP_PREFIX"

# Create MODULE.bazel with version
cp "${REPO_ROOT}/bazel/MODULE.bazel" "$SUBMISSION_DIR/MODULE.bazel"
sed -i "s/version = \"\"/version = \"${VERSION}\"/" "$SUBMISSION_DIR/MODULE.bazel"

# Create source.json
cat > "$SUBMISSION_DIR/source.json" << EOF
{
  "integrity": "sha256-${SHA256}",
  "strip_prefix": "${STRIP_PREFIX}",
  "url": "${ARCHIVE_URL}"
}
EOF

# Copy presubmit.yml
cp "${REPO_ROOT}/.bcr/presubmit.yml" "$SUBMISSION_DIR/presubmit.yml"

echo ""
echo "BCR submission files created in: $SUBMISSION_DIR"
echo "Files:"
find "$SUBMISSION_DIR" -type f -printf "  %P\n"

echo ""
echo "Next steps:"
echo "1. Create a fork of https://github.com/bazelbuild/bazel-central-registry"
echo "2. Copy the files from $SUBMISSION_DIR to modules/envoy_toolshed/${VERSION}/ in your fork"
echo "3. Update the versions array in modules/envoy_toolshed/metadata.json"
echo "4. Create a pull request to the BCR repository"