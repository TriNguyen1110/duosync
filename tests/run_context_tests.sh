#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/duosync-context-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
swiftc -module-cache-path "$test_dir/module-cache" DuoSync/Models.swift tests/ContextValidationTests.swift -o "$test_dir/context-tests"
"$test_dir/context-tests"
