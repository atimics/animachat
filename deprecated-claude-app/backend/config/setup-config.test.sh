#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_script="$script_dir/setup-config.sh"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/setup-config-test.XXXXXX")"
trap 'rm -rf -- "$test_dir"' EXIT

cp "$source_script" "$test_dir/setup-config.sh"
printf '%s\n' \
    'sk-ant-api03-YOUR-KEY-HERE' \
    'sk-or-v1-YOUR-KEY-HERE' \
    'AKIAIOSFODNN7EXAMPLE' \
    'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' \
    > "$test_dir/config.json"

output="$(
    cd "$test_dir"
    printf '%s\n' \
        'test-anthropic-key' \
        'test-openrouter-key' \
        'test-access-key' \
        'test-secret-key' |
        bash ./setup-config.sh
)"

expected_lines=(
    'Sonnet models: ~83% subsidized ($0.50/$2.50 vs $3/$15)'
    'Opus models: 80% subsidized ($3/$15 vs $15/$75)'
    'GPT-4: 80% subsidized ($2/$6 vs $10/$30)'
)

for expected in "${expected_lines[@]}"; do
    if ! grep -Fqx -- "$expected" <<< "$output"; then
        printf 'missing literal pricing line: %s\n' "$expected" >&2
        exit 1
    fi
done

if ! grep -Fqx -- 'test-secret-key' "$test_dir/config.json"; then
    printf 'setup script did not update its temporary config fixture\n' >&2
    exit 1
fi

printf 'setup-config pricing output test passed\n'
