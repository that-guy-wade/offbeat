#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
xcrun swiftc MicrophoneGate.swift tests/MicrophoneGateTests.swift \
    -o "$test_tmp/tests" || exit 1
"$test_tmp/tests" || exit 1
