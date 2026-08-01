#!/bin/zsh

set -euo pipefail

commit_message_file="${1:?Commit message file is required}"
commit_source="${2:-}"

if [[ "${commit_source}" == "merge" ]]; then
    exit 0
fi

branch_name="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

if [[ -z "${branch_name}" ]]; then
    exit 0
fi

branch_suffix="${branch_name#feature/}"
branch_identifier="$(printf '%s' "${branch_suffix}" | sed -E 's/^[^0-9]*([0-9]+).*$/\1/')"

if [[ "${branch_identifier}" == "${branch_suffix}" && ! "${branch_suffix}" =~ ^[0-9]+$ ]]; then
    branch_identifier="${branch_suffix}"
fi

first_line="$(head -n 1 "${commit_message_file}")"

if [[ "${first_line}" == Merge\ * || "${first_line}" == \["${branch_identifier}"\]* ]]; then
    exit 0
fi

temporary_file="$(mktemp "${TMPDIR:-/tmp}/bubbly-commit-message.XXXXXX")"
trap 'rm -f "${temporary_file}"' EXIT

printf '[%s] %s\n' "${branch_identifier}" "${first_line}" > "${temporary_file}"
tail -n +2 "${commit_message_file}" >> "${temporary_file}"

description="$(git config --get "branch.${branch_name}.description" || true)"

if [[ -n "${description}" ]]; then
    printf '\n%s\n' "${description}" >> "${temporary_file}"
fi

mv "${temporary_file}" "${commit_message_file}"
trap - EXIT
