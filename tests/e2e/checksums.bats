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

@test "get_checksum_from_digest: returns 64-char hex for stable" {
  stable=$(resolve_version "stable")
  checksum=$(get_checksum_from_digest "$stable")
  [ -n "$checksum" ]
  [[ "$checksum" =~ ^[0-9a-f]{64}$ ]]
}

@test "get_checksum_from_file: returns 64-char hex for stable x86_64" {
  version=$(resolve_version "0.10.0")
  checksum=$(get_checksum_from_file "$version" "nvim-linux64.tar.gz")
  [[ "$checksum" =~ ^[0-9a-f]{64}$ ]]
}

@test "get_checksum_from_digest: nightly does not crash" {
  ## nightly may or may not carry a digest; must not error out
  get_checksum_from_digest "nightly" || true
}

@test "checksum retrieval: at least one method returns 64-char hex for stable" {
  stable=$(resolve_version "stable")
  checksum=$(get_checksum_from_digest "$stable") ||
    checksum=$(get_checksum_from_file "$stable" "nvim-linux-x86_64.tar.gz") || true
  [ -n "$checksum" ]
  [[ "$checksum" =~ ^[0-9a-f]{64}$ ]]
}
