#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"

@test "no args: prints usage and exits 1" {
  result=$(bash "$SCRIPT" 2>&1) && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"Usage"* ]]
}

@test "--help: prints usage and exits 0" {
  result=$(bash "$SCRIPT" --help 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
  [[ "$result" == *"Usage"* ]]
}

@test "-h: prints usage and exits 0" {
  result=$(bash "$SCRIPT" -h 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
  [[ "$result" == *"Usage"* ]]
}

@test "help: prints usage and exits 0" {
  result=$(bash "$SCRIPT" help 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
  [[ "$result" == *"Usage"* ]]
}

@test "--version: prints 'nvvm <semver>' and exits 0" {
  result=$(bash "$SCRIPT" --version 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
  [[ "$result" =~ ^nvvm\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "-v: prints 'nvvm <semver>' and exits 0" {
  result=$(bash "$SCRIPT" -v 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
  [[ "$result" =~ ^nvvm\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "unknown command: prints command name in error and exits 1" {
  result=$(bash "$SCRIPT" foobar 2>&1) && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"Unknown command"* ]]
  [[ "$result" == *"foobar"* ]]
}

@test "check_deps: exits 1 and names jq when it is absent from PATH" {
  fake_path=$(mktemp -d)
  ln -sf "$(command -v bash)" "$fake_path/bash"
  printf '#!/bin/sh\n' >"$fake_path/curl"
  printf '#!/bin/sh\n' >"$fake_path/sha256sum"
  chmod +x "$fake_path/curl" "$fake_path/sha256sum"
  result=$(PATH="$fake_path" bash -c "source '$SCRIPT'; check_deps" 2>&1) && status=0 || status=$?
  rm -rf "$fake_path"
  [ "$status" -ne 0 ]
  [[ "$result" == *"jq"* ]]
}

@test "check_deps: exits 0 when all deps present" {
  result=$(bash -c "source '$SCRIPT'; check_deps" 2>&1) && status=0 || status=$?
  [ "$status" -eq 0 ]
}
