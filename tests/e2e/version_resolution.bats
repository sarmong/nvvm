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

@test "resolve_version latest: resolves to a valid semver string" {
  result=$(resolve_version "latest")
  [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "resolve_version latest: resolves same semver as stable" {
  stable=$(resolve_version "stable")
  latest=$(resolve_version "latest")
  [ "$stable" = "$latest" ]
}

@test "resolve_version partial '0.10': resolves to 0.10.x semver" {
  result=$(resolve_version "0.10")
  [[ "$result" =~ ^0\.10\.[0-9]+$ ]]
}

@test "resolve_version partial '0.9': resolves to 0.9.x semver" {
  result=$(resolve_version "0.9")
  [[ "$result" =~ ^0\.9\.[0-9]+$ ]]
}

@test "resolve_version full semver: passes through unchanged" {
  result=$(resolve_version "0.10.2")
  [ "$result" = "0.10.2" ]
}
