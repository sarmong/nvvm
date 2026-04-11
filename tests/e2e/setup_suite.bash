#!/usr/bin/env bash

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"

setup_suite() {
  SUITE_CACHE_DIR=$(mktemp -d)
  export SUITE_CACHE_DIR
  export XDG_CACHE_HOME="$SUITE_CACHE_DIR/cache"
  # shellcheck disable=SC1090
  source "$SCRIPT"
  mkdir -p "$CACHE_DIR"
  get_releases >/dev/null
}

teardown_suite() {
  rm -rf "$SUITE_CACHE_DIR"
}
