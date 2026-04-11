#!/usr/bin/env bats
# shellcheck disable=SC2317  # mock functions inside @test blocks are called indirectly by bats

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"

setup() {
  TEST_DIR=$(mktemp -d)
  export XDG_DATA_HOME="$TEST_DIR/data"
  export XDG_CACHE_HOME="$SUITE_CACHE_DIR/cache"
  # shellcheck disable=SC1090
  source "$SCRIPT"
  mkdir -p "$BIN_DIR" "$LIB_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "get_releases: returns a non-empty JSON array from GitHub" {
  result=$(get_releases)
  echo "$result" | jq -e 'type == "array" and length > 0' >/dev/null
}

@test "get_releases: second call within 1h reads from cache without network" {
  # Cold start — populates cache
  get_releases >/dev/null
  [ -f "$CACHE_DIR/releases.json" ]
  # shellcheck disable=SC2154
  [ -f "$last_updated_file" ]

  # Override curl to fail; if cache is hit, the test passes
  curl() {
    echo "unexpected curl call" >&2
    return 1
  }
  result=$(get_releases 2>&1)
  echo "$result" | jq -e 'type == "array"' >/dev/null
}
