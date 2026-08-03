#!/bin/zsh

set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
configuration="${repository_root}/.swiftlint.yml"
baseline="${repository_root}/swiftlint-baseline.json"

if command -v swiftlint >/dev/null 2>&1; then
    linter="$(command -v swiftlint)"
elif [[ -x /opt/homebrew/bin/swiftlint ]]; then
    linter="/opt/homebrew/bin/swiftlint"
elif [[ -x /usr/local/bin/swiftlint ]]; then
    linter="/usr/local/bin/swiftlint"
else
    echo "SwiftLint failed: swiftlint is not installed" >&2
    exit 1
fi

if [[ ! -f "${configuration}" || ! -f "${baseline}" ]]; then
    echo "SwiftLint failed: configuration or baseline is missing" >&2
    exit 1
fi

echo "SwiftLint starting"
cd "${repository_root}"
"${linter}" lint --config "${configuration}" --quiet
echo "SwiftLint finished"
