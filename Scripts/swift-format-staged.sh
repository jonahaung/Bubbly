#!/bin/zsh

set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
configuration="${repository_root}/swift-format.json"

echo "Swift Format starting"

if [[ -x "${repository_root}/.swift-format/swift-format" ]]; then
    formatter="${repository_root}/.swift-format/swift-format"
elif command -v swift-format >/dev/null 2>&1; then
    formatter="$(command -v swift-format)"
elif formatter="$(xcrun --find swift-format 2>/dev/null)" && [[ -x "${formatter}" ]]; then
    formatter="${formatter}"
else
    echo "Swift Format failed: swift-format is not installed" >&2
    exit 1
fi

if [[ ! -f "${configuration}" ]]; then
    echo "Swift Format failed: ${configuration} is missing" >&2
    exit 1
fi

while IFS= read -r -d '' file; do
    echo "${file}"
    "${formatter}" -i "${repository_root}/${file}" --configuration "${configuration}"
    git -C "${repository_root}" add -- "${file}"
done < <(git -C "${repository_root}" diff --cached --diff-filter=ACMR --name-only -z -- '*.swift')

echo "Swift Format finished"
