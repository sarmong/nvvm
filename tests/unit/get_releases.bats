#!/usr/bin/env bats
# shellcheck disable=SC2317  # mock functions inside setup/@test blocks are called indirectly by bats

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"
FIXTURE="$BATS_TEST_DIRNAME/../fixtures/releases.json"

setup() {
  TEST_DIR=$(mktemp -d)
  export XDG_DATA_HOME="$TEST_DIR/data"
  export XDG_CACHE_HOME="$TEST_DIR/cache"
  # shellcheck disable=SC1090
  source "$SCRIPT"
  mkdir -p "$BIN_DIR" "$LIB_DIR" "$CACHE_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Writes fixture to cache with a fresh timestamp (now).
_write_fresh_cache() {
  cp "$FIXTURE" "$CACHE_DIR/releases.json"
  # shellcheck disable=SC2154
  date +%s >"$last_updated_file"
}

# Writes fixture to cache with a stale timestamp (2h ago).
_write_stale_cache() {
  cp "$FIXTURE" "$CACHE_DIR/releases.json"
  # shellcheck disable=SC2154
  echo "$(($(date +%s) - 7200))" >"$last_updated_file"
}

# Overrides curl to copy the fixture into the file named by --output.
_mock_curl_success() {
  curl() {
    local prev=""
    for arg in "$@"; do
      [[ "$prev" == "--output" ]] && {
        cp "$FIXTURE" "$arg"
        return 0
      }
      prev="$arg"
    done
    return 0
  }
}

@test "get_releases: returns cached data without calling curl when cache is fresh" {
  _write_fresh_cache
  curl() {
    echo "unexpected curl call" >&2
    return 1
  }
  result=$(get_releases)
  [[ "$result" == *"0.10.4"* ]]
}

@test "get_releases: fetches and caches fresh data when cache is stale" {
  _write_stale_cache
  _mock_curl_success

  local old_ts
  old_ts=$(cat "$last_updated_file")

  result=$(get_releases)
  [[ "$result" == *"0.10.4"* ]]

  local new_ts
  new_ts=$(cat "$last_updated_file")

  [[ "$new_ts" -gt "$old_ts" ]]
}

@test "get_releases: returns stale cache with warning when curl fails" {
  _write_stale_cache
  curl() { return 1; }
  result=$(get_releases 2>&1)
  [[ "$result" == *"WARNING"* ]]
  [[ "$result" == *"0.10.4"* ]]
}

@test "get_releases: returns stale cache with warning when API returns invalid JSON" {
  _write_stale_cache
  curl() {
    local prev=""
    for arg in "$@"; do
      [[ "$prev" == "--output" ]] && {
        echo "not valid json" >"$arg"
        return 0
      }
      prev="$arg"
    done
  }
  result=$(get_releases 2>&1)
  [[ "$result" == *"WARNING"* ]]
  [[ "$result" == *"0.10.4"* ]]
}

@test "get_releases: exits 1 when curl fails and no cache exists" {
  curl() { return 1; }
  get_releases 2>&1 && status=0 || status=$?
  [ "$status" -ne 0 ]
}
