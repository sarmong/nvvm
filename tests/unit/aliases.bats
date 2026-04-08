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

  mkdir -p "$LIB_DIR/0.10.2/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.2"\n' >"$LIB_DIR/0.10.2/bin/nvim"
  chmod +x "$LIB_DIR/0.10.2/bin/nvim"
  ln -sf "$LIB_DIR/0.10.2/bin/nvim" "$BIN_DIR/nvim-0.10.2"

  # Stub out XDG asset functions — that behavior is covered in xdg_assets.bats
  _install_xdg_assets() { return 0; }
  _remove_xdg_assets() { return 0; }
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ── resolve_version ──────────────────────────────────────────────────────────

@test "resolve_version: stable resolves to latest non-prerelease semver" {
  result=$(resolve_version "stable")
  [ "$result" = "0.10.4" ]
}

@test "resolve_version: latest resolves same as stable" {
  result=$(resolve_version "latest")
  [ "$result" = "0.10.4" ]
}

@test "resolve_version: nightly passes through unchanged" {
  result=$(resolve_version "nightly")
  [ "$result" = "nightly" ]
}

@test "resolve_version: full semver passes through unchanged" {
  result=$(resolve_version "0.10.3")
  [ "$result" = "0.10.3" ]
}

@test "resolve_version: partial semver resolves to latest matching patch" {
  result=$(resolve_version "0.10")
  [ "$result" = "0.10.4" ]
}

@test "resolve_version: partial semver does not match across minor versions" {
  result=$(resolve_version "0.9")
  [ "$result" = "0.9.5" ]
}

@test "resolve_version: unknown partial semver exits 1 with error" {
  result=$(resolve_version "0.99" 2>&1) && status=0 || status=$?
  [ "$status" -ne 0 ]
  [[ "$result" == *"no release found"* ]]
}

# ── _create_alias_symlinks ───────────────────────────────────────────────────

@test "_create_alias_symlinks: creates nvim-stable and nvim-latest pointing to version binary" {
  _create_alias_symlinks "0.10.4"
  [ -L "$BIN_DIR/nvim-stable" ]
  [ -L "$BIN_DIR/nvim-latest" ]
  [ "$(readlink -f "$BIN_DIR/nvim-stable")" = "$(readlink -f "$LIB_DIR/0.10.4/bin/nvim")" ]
  [ "$(readlink -f "$BIN_DIR/nvim-latest")" = "$(readlink -f "$LIB_DIR/0.10.4/bin/nvim")" ]
}

# ── _create_alias_symlinks_if_needed ─────────────────────────────────────────

@test "_create_alias_symlinks_if_needed: creates symlinks when version matches stable" {
  _create_alias_symlinks_if_needed "0.10.4"
  [ -L "$BIN_DIR/nvim-stable" ]
  [ -L "$BIN_DIR/nvim-latest" ]
}

@test "_create_alias_symlinks_if_needed: does not create symlinks for non-stable version" {
  _create_alias_symlinks_if_needed "0.10.3"
  [ ! -e "$BIN_DIR/nvim-stable" ]
  [ ! -e "$BIN_DIR/nvim-latest" ]
}

# ── use ──────────────────────────────────────────────────────────────────────

@test "use stable: creates nvim-stable symlink and chains nvim -> nvim-stable" {
  use "stable"
  [ -L "$BIN_DIR/nvim-stable" ]
  [ "$(readlink "$BIN_DIR/nvim")" = "nvim-stable" ]
}

@test "use latest: creates nvim-latest symlink and chains nvim -> nvim-latest" {
  use "latest"
  [ -L "$BIN_DIR/nvim-latest" ]
  [ "$(readlink "$BIN_DIR/nvim")" = "nvim-latest" ]
}

@test "use 0.10.4: nvim points directly to binary without alias chain" {
  use "0.10.4"
  target=$(readlink "$BIN_DIR/nvim")
  [[ "$target" != "nvim-stable" ]]
  [[ "$target" != "nvim-latest" ]]
  [ "$(readlink -f "$BIN_DIR/nvim")" = "$(readlink -f "$LIB_DIR/0.10.4/bin/nvim")" ]
}

# ── run ──────────────────────────────────────────────────────────────────────

@test "run stable: executes nvim-stable directly without version resolution" {
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-stable"
  result=$(bash -c "
    source '$SCRIPT'
    get_releases() { echo '[]'; }
    export BIN_DIR='$BIN_DIR' LIB_DIR='$LIB_DIR' CACHE_DIR='$CACHE_DIR'
    run stable
  " 2>&1)
  [[ "$result" == *"NVIM v0.10.4"* ]]
}

# ── resolve_installed_version ────────────────────────────────────────────────

@test "resolve_installed_version: stable returns version from alias symlink" {
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-stable"
  result=$(resolve_installed_version "stable")
  [ "$result" = "0.10.4" ]
}

@test "resolve_installed_version: stable errors when alias symlink absent" {
  result=$(resolve_installed_version "stable" 2>&1) && status=0 || status=$?
  [ "$status" -ne 0 ]
  [[ "$result" == *"has not been installed"* ]]
}

@test "resolve_installed_version: partial semver returns highest installed matching version" {
  result=$(resolve_installed_version "0.10")
  [ "$result" = "0.10.4" ]
}

# ── uninstall ────────────────────────────────────────────────────────────────

@test "uninstall: removes nvim-stable and nvim-latest when uninstalling stable version" {
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-stable"
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-latest"
  uninstall "0.10.4"
  [ ! -e "$BIN_DIR/nvim-stable" ]
  [ ! -e "$BIN_DIR/nvim-latest" ]
}

@test "uninstall: does not remove nvim-stable when uninstalling non-stable version" {
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-stable"
  uninstall "0.10.3"
  [ -L "$BIN_DIR/nvim-stable" ]
}

@test "uninstall: removes nvim when it chained through a removed alias symlink" {
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-stable"
  ln -sf "nvim-stable" "$BIN_DIR/nvim"
  uninstall --force "0.10.4"
  [ ! -e "$BIN_DIR/nvim-stable" ]
  [ ! -e "$BIN_DIR/nvim" ]
}
