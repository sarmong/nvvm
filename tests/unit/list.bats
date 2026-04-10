#!/usr/bin/env bats
# shellcheck disable=SC2317  # mock functions inside setup/@test blocks are called indirectly by bats

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"

setup() {
  TEST_DIR=$(mktemp -d)
  export XDG_DATA_HOME="$TEST_DIR/data"
  export XDG_CACHE_HOME="$TEST_DIR/cache"
  # shellcheck disable=SC1090
  source "$SCRIPT"
  get_releases() { cat "$BATS_TEST_DIRNAME/../fixtures/releases.json"; }
  mkdir -p "$BIN_DIR" "$LIB_DIR" "$CACHE_DIR"

  mkdir -p "$LIB_DIR/0.10.4/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.4"\n' >"$LIB_DIR/0.10.4/bin/nvim"
  chmod +x "$LIB_DIR/0.10.4/bin/nvim"
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-0.10.4"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "list --all: shows all entries from fixture" {
  result=$(list --all)
  [[ "$result" == *"0.10.4"* ]]
  [[ "$result" == *"0.10.3"* ]]
  [[ "$result" == *"0.10.2"* ]]
  [[ "$result" == *"0.9.5"* ]]
  [[ "$result" == *"nightly"* ]]
}

@test "list -a: same output as --all" {
  [ "$(list --all)" = "$(list -a)" ]
}

@test "list: default shows at most 20 entries" {
  big_fixture=$(jq -n '[range(25) | {tag_name: ("v1." + (. | tostring) + ".0"), prerelease: false, draft: false, name: ("NVIM v1." + (. | tostring) + ".0"), assets: []}]')
  get_releases() { echo "$big_fixture"; }
  count=$(list | wc -l)
  [ "$count" -eq 20 ]
}

@test "list: installed non-active version shown with * prefix" {
  result=$(list --all)
  [[ "$result" == *"* 0.10.4"* ]]
}

@test "list: active version shown with * and (current)" {
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim"
  result=$(list --all)
  [[ "$result" == *"* 0.10.4 (current)"* ]]
}

@test "list: non-installed version shown with leading spaces" {
  result=$(list --all)
  [[ "$result" == *"  0.10.3"* ]]
}
