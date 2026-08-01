#!/bin/zsh

set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
formatter="${repository_root}/.swift-format/swift-format"
configuration="${repository_root}/swift-format.json"

echo "Swift Format starting"

if "${formatter}" --version >/dev/null 2>&1; then
    if [[ ! -f "${configuration}" ]]; then
        echo "Swift Format failed: ${configuration} is missing" >&2
        exit 1
    fi

    while IFS= read -r -d '' file; do
        echo "${file}"
        "${formatter}" -i "${repository_root}/${file}" --configuration "${configuration}"
        git -C "${repository_root}" add -- "${file}"
    done < <(git -C "${repository_root}" diff --cached --diff-filter=ACMR --name-only -z -- '*.swift')
fi

echo "Swift Format finished"
