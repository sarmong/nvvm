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

@test "get_release_asset x86_64: filename matches expected pattern" {
  stable=$(resolve_version "stable")
  name=$(get_release_asset "$stable" | jq -r '.name')
  [[ "$name" == "nvim-linux-x86_64.tar.gz" || "$name" == "nvim-linux64.tar.gz" ]]
}

@test "get_release_asset x86_64: download url contains the asset filename" {
  stable=$(resolve_version "stable")
  result=$(get_release_asset "$stable")
  url=$(echo "$result" | jq -r '.browser_download_url')
  name=$(echo "$result" | jq -r '.name')
  [[ "$url" == *"$name"* ]]
}

@test "get_release_asset arm64: returns nvim-linux-arm64.tar.gz for stable" {
  get_arch() { echo "arm64"; }
  stable=$(resolve_version "stable")
  name=$(get_release_asset "$stable" | jq -r '.name')
  [ "$name" = "nvim-linux-arm64.tar.gz" ]
}

@test "get_release_asset arm64: download url contains arm64" {
  get_arch() { echo "arm64"; }
  stable=$(resolve_version "stable")
  url=$(get_release_asset "$stable" | jq -r '.browser_download_url')
  [[ "$url" == *"arm64"* ]]
}

@test "get_release_asset nightly: returns object with browser_download_url" {
  result=$(get_release_asset "nightly")
  echo "$result" | jq -e '.browser_download_url' >/dev/null
}
