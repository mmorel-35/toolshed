#!/bin/bash
# Test script to verify dependency alignment
# This can be run as part of CI to ensure alignment is maintained

set -e

echo "Testing MODULE.bazel and WORKSPACE dependency alignment..."
echo ""

# Run the verification script
python3 "$(dirname "$0")/verify_version_alignment.py"

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✓ Dependency alignment test PASSED"
    exit 0
else
    echo ""
    echo "✗ Dependency alignment test FAILED"
    echo "Please ensure MODULE.bazel versions match versions.bzl"
    exit 1
fi
