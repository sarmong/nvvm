#!/usr/bin/env bats
# shellcheck disable=SC2317  # mock functions inside @test blocks are called indirectly by bats

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"

setup() {
  TEST_DIR=$(mktemp -d)
  export XDG_DATA_HOME="$TEST_DIR/data"
  export XDG_CACHE_HOME="$TEST_DIR/cache"
  # shellcheck disable=SC1090
  source "$SCRIPT"
  mkdir -p "$BIN_DIR" "$LIB_DIR" "$CACHE_DIR"

  # File with known content; hash computed at runtime for use in assertions.
  TEST_FILE="$TEST_DIR/test_archive.tar.gz"
  echo "fake archive content" >"$TEST_FILE"
  TEST_FILE_HASH=$(sha256sum "$TEST_FILE" | awk '{print $1}')
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ── get_checksum_from_digest ─────────────────────────────────────────────────

@test "get_checksum_from_digest: strips sha256: prefix and returns hex hash" {
  get_release_asset() {
    echo '{"digest": "sha256:abc123def456abc123def456abc123def456abc123def456abc123def456abc1"}'
  }
  result=$(get_checksum_from_digest "0.10.4")
  [ "$result" = "abc123def456abc123def456abc123def456abc123def456abc123def456abc1" ]
}

@test "get_checksum_from_digest: returns 1 when digest field is null" {
  get_release_asset() { echo '{"digest": null}'; }
  get_checksum_from_digest "0.10.4" 2>&1 && status=0 || status=$?
  [ "$status" -ne 0 ]
}

@test "get_checksum_from_digest: returns 1 when digest field is absent" {
  get_release_asset() { echo '{"name": "nvim-linux-x86_64.tar.gz"}'; }
  get_checksum_from_digest "0.10.4" 2>&1 && status=0 || status=$?
  [ "$status" -ne 0 ]
}

# ── check_checksum ────────────────────────────────────────────────────────────

@test "check_checksum: passes and prints confirmation when digest hash matches file" {
  get_checksum_from_digest() { echo "$TEST_FILE_HASH"; }
  result=$(check_checksum "0.10.4" "$TEST_FILE")
  [[ "$result" == *"passed"* ]]
}

@test "check_checksum: returns 1 when hash does not match file" {
  get_checksum_from_digest() { echo "0000000000000000000000000000000000000000000000000000000000000000"; }
  check_checksum "0.10.4" "$TEST_FILE" 2>&1 && status=0 || status=$?
  [ "$status" -ne 0 ]
}

@test "check_checksum: warns and returns 0 when all three checksum sources fail" {
  get_checksum_from_digest() { return 1; }
  get_checksum_from_file() { return 1; }
  get_checksum_from_description() { return 1; }
  result=$(check_checksum "0.10.4" "$TEST_FILE" 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
  [[ "$result" == *"warning"* ]]
}

@test "check_checksum: falls through to file method when digest fails" {
  get_checksum_from_digest() { return 1; }
  get_checksum_from_file() { echo "$TEST_FILE_HASH"; }
  result=$(check_checksum "0.10.4" "$TEST_FILE")
  [[ "$result" == *"passed"* ]]
}

@test "check_checksum: falls through to description method when digest and file fail" {
  get_checksum_from_digest() { return 1; }
  get_checksum_from_file() { return 1; }
  get_checksum_from_description() { echo "$TEST_FILE_HASH"; }
  result=$(check_checksum "0.10.4" "$TEST_FILE")
  [[ "$result" == *"passed"* ]]
}
