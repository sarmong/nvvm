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

  mkdir -p "$LIB_DIR/0.10.3/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.3"\n' >"$LIB_DIR/0.10.3/bin/nvim"
  chmod +x "$LIB_DIR/0.10.3/bin/nvim"
  ln -sf "$LIB_DIR/0.10.3/bin/nvim" "$BIN_DIR/nvim-0.10.3"

  # Empty dir with no fzf — used by tests that need fzf absent from PATH
  mkdir -p "$TEST_DIR/no_fzf_bin"
  NO_FZF_PATH="$TEST_DIR/no_fzf_bin"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Helper: run a snippet in a clean subprocess that sources the script.
# Usage: nvvm_eval <extra_setup> <command>
nvvm_eval() {
  local extra="$1"
  local cmd="$2"
  bash -c "
    source '$SCRIPT'
    get_releases() { cat '$BATS_TEST_DIRNAME/../fixtures/releases.json'; }
    _install_xdg_assets() { :; }
    _remove_xdg_assets() { :; }
    export XDG_DATA_HOME='$XDG_DATA_HOME' XDG_CACHE_HOME='$XDG_CACHE_HOME'
    $extra
    $cmd
  " 2>&1
}

# ── install no-arg ─────────────────────────────────────────────────────────

@test "install no-arg: exits 1 with usage when fzf not in PATH" {
  result=$(nvvm_eval "" "PATH='$NO_FZF_PATH' install") && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"Usage"* ]]
}

@test "install no-arg: pipes only uninstalled versions to _pick" {
  result=$(nvvm_eval \
    "_pick() { cat >'$TEST_DIR/pick_input'; return 1; }" \
    "install") || true
  local input
  input=$(cat "$TEST_DIR/pick_input" 2>/dev/null || echo "")
  [[ "$input" == *"nightly"* ]]
  [[ ! "$input" == *"0.10.4"* ]]
  [[ ! "$input" == *"0.10.3"* ]]
}

@test "install no-arg: exits with message when no uninstalled versions available" {
  # Override releases to only contain versions already installed in setup
  result=$(nvvm_eval \
    "get_releases() { echo '[{\"tag_name\": \"v0.10.4\"}, {\"tag_name\": \"v0.10.3\"}]'; }; _pick() { return 1; }" \
    "install") && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"No"* ]]
}

# ── use no-arg ─────────────────────────────────────────────────────────────

@test "use no-arg: exits 1 with usage when fzf not in PATH" {
  result=$(nvvm_eval "" "PATH='$NO_FZF_PATH' use") && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"Usage"* ]]
}

@test "use no-arg: switches to version selected via _pick" {
  nvvm_eval \
    "ln -sf '$LIB_DIR/0.10.4/bin/nvim' '$BIN_DIR/nvim'; _pick() { echo '0.10.3'; }" \
    "use"
  [ "$(readlink -f "$BIN_DIR/nvim")" = "$(readlink -f "$LIB_DIR/0.10.3/bin/nvim")" ]
}

@test "use no-arg: excludes currently active version from _pick list" {
  nvvm_eval \
    "ln -sf '$LIB_DIR/0.10.4/bin/nvim' '$BIN_DIR/nvim'; _pick() { cat >'$TEST_DIR/pick_input'; echo '0.10.3'; }" \
    "use"
  local input
  input=$(cat "$TEST_DIR/pick_input")
  [[ ! "$input" == *"0.10.4"* ]]
  [[ "$input" == *"0.10.3"* ]]
}

@test "use no-arg: exits with message when no non-active versions installed" {
  result=$(nvvm_eval \
    "rm -rf '$LIB_DIR/0.10.3' '$BIN_DIR/nvim-0.10.3'; ln -sf '$LIB_DIR/0.10.4/bin/nvim' '$BIN_DIR/nvim'; _pick() { return 1; }" \
    "use") && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"No"* ]]
}

# ── run no-arg ─────────────────────────────────────────────────────────────

@test "run no-arg: exits 1 with usage when fzf not in PATH" {
  result=$(nvvm_eval "" "PATH='$NO_FZF_PATH' run") && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"Usage"* ]]
}

@test "run no-arg: marks active version with (current) in _pick list" {
  nvvm_eval \
    "ln -sf '$LIB_DIR/0.10.4/bin/nvim' '$BIN_DIR/nvim'; _pick() { cat >'$TEST_DIR/pick_input'; return 1; }" \
    "run" || true
  local input
  input=$(cat "$TEST_DIR/pick_input" 2>/dev/null || echo "")
  [[ "$input" == *"0.10.4 (current)"* ]]
  [[ "$input" == *"0.10.3"* ]]
  [[ ! "$input" == *"0.10.3 (current)"* ]]
}

@test "run no-arg: strips (current) suffix before executing binary" {
  result=$(nvvm_eval \
    "ln -sf '$LIB_DIR/0.10.4/bin/nvim' '$BIN_DIR/nvim'; _pick() { echo '0.10.4 (current)'; }" \
    "run")
  [[ "$result" == *"NVIM v0.10.4"* ]]
}

@test "run no-arg: exits with message when no versions installed" {
  result=$(nvvm_eval \
    "rm -rf '$LIB_DIR' && mkdir -p '$LIB_DIR'; _pick() { return 1; }" \
    "run") && status=0 || status=$?
  [ "$status" -eq 1 ]
  [[ "$result" == *"No"* ]]
}
