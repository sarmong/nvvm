#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../../nvvm"

setup() {
  TEST_DIR=$(mktemp -d)
  export XDG_DATA_HOME="$TEST_DIR/data"
  export XDG_CACHE_HOME="$TEST_DIR/cache"

  # shellcheck disable=SC1090
  source "$SCRIPT"

  mkdir -p "$BIN_DIR" "$LIB_DIR" "$CACHE_DIR"

  # Fake share assets for version 0.10.4
  mkdir -p "$LIB_DIR/0.10.4/share/applications"
  mkdir -p "$LIB_DIR/0.10.4/share/icons/hicolor/16x16/apps"
  mkdir -p "$LIB_DIR/0.10.4/share/icons/hicolor/256x256/apps"
  mkdir -p "$LIB_DIR/0.10.4/share/man/man1"
  echo "[Desktop Entry]" >"$LIB_DIR/0.10.4/share/applications/nvim.desktop"
  touch "$LIB_DIR/0.10.4/share/icons/hicolor/16x16/apps/nvim.png"
  touch "$LIB_DIR/0.10.4/share/icons/hicolor/256x256/apps/nvim.png"
  touch "$LIB_DIR/0.10.4/share/man/man1/nvim.1"

  # Fake 0.10.3 for inactive-version tests (no share dir)
  mkdir -p "$LIB_DIR/0.10.3/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.3"\n' >"$LIB_DIR/0.10.3/bin/nvim"
  chmod +x "$LIB_DIR/0.10.3/bin/nvim"
  ln -sf "$LIB_DIR/0.10.3/bin/nvim" "$BIN_DIR/nvim-0.10.3"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# ── _install_xdg_assets ──────────────────────────────────────────────────────

@test "_install_xdg_assets: installs desktop file to XDG_DATA_HOME/applications" {
  _install_xdg_assets "0.10.4"
  [ -f "$XDG_DATA_HOME/applications/nvim.desktop" ]
}

@test "_install_xdg_assets: installs icon files preserving hicolor tree structure" {
  _install_xdg_assets "0.10.4"
  [ -f "$XDG_DATA_HOME/icons/hicolor/16x16/apps/nvim.png" ]
  [ -f "$XDG_DATA_HOME/icons/hicolor/256x256/apps/nvim.png" ]
}

@test "_install_xdg_assets: installs man page to XDG_DATA_HOME/man/man1" {
  _install_xdg_assets "0.10.4"
  [ -f "$XDG_DATA_HOME/man/man1/nvim.1" ]
}

@test "_install_xdg_assets: silently skips when share assets are absent" {
  mkdir -p "$LIB_DIR/0.9.0/bin"
  # No share dir for 0.9.0
  _install_xdg_assets "0.9.0" && status=0 || status=$?
  [ "$status" -eq 0 ]
}

# ── _remove_xdg_assets ───────────────────────────────────────────────────────

@test "_remove_xdg_assets: removes desktop file" {
  _install_xdg_assets "0.10.4"
  _remove_xdg_assets
  [ ! -e "$XDG_DATA_HOME/applications/nvim.desktop" ]
}

@test "_remove_xdg_assets: removes nvim icon files" {
  _install_xdg_assets "0.10.4"
  _remove_xdg_assets
  [ ! -e "$XDG_DATA_HOME/icons/hicolor/16x16/apps/nvim.png" ]
  [ ! -e "$XDG_DATA_HOME/icons/hicolor/256x256/apps/nvim.png" ]
}

@test "_remove_xdg_assets: removes man page" {
  _install_xdg_assets "0.10.4"
  _remove_xdg_assets
  [ ! -e "$XDG_DATA_HOME/man/man1/nvim.1" ]
}

@test "_remove_xdg_assets: succeeds when assets were never installed" {
  _remove_xdg_assets && status=0 || status=$?
  [ "$status" -eq 0 ]
}

# ── use integration ──────────────────────────────────────────────────────────

@test "use: installs xdg assets for switched version" {
  mkdir -p "$LIB_DIR/0.10.4/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.4"\n' >"$LIB_DIR/0.10.4/bin/nvim"
  chmod +x "$LIB_DIR/0.10.4/bin/nvim"
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-0.10.4"

  use "0.10.4"
  [ -f "$XDG_DATA_HOME/applications/nvim.desktop" ]
}

# ── uninstall integration ────────────────────────────────────────────────────

@test "uninstall --force: removes xdg assets when uninstalling active version" {
  _install_xdg_assets "0.10.4"
  [ -f "$XDG_DATA_HOME/applications/nvim.desktop" ]

  mkdir -p "$LIB_DIR/0.10.4/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.4"\n' >"$LIB_DIR/0.10.4/bin/nvim"
  chmod +x "$LIB_DIR/0.10.4/bin/nvim"
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-0.10.4"
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim"

  uninstall --force "0.10.4"

  [ ! -e "$XDG_DATA_HOME/applications/nvim.desktop" ]
  [ ! -e "$XDG_DATA_HOME/man/man1/nvim.1" ]
}

@test "uninstall: does not remove xdg assets when uninstalling inactive version" {
  _install_xdg_assets "0.10.4"

  mkdir -p "$LIB_DIR/0.10.4/bin"
  printf '#!/usr/bin/env bash\necho "NVIM v0.10.4"\n' >"$LIB_DIR/0.10.4/bin/nvim"
  chmod +x "$LIB_DIR/0.10.4/bin/nvim"
  ln -sf "$LIB_DIR/0.10.4/bin/nvim" "$BIN_DIR/nvim-0.10.4"

  # 0.10.3 is active
  ln -sf "$LIB_DIR/0.10.3/bin/nvim" "$BIN_DIR/nvim"

  uninstall "0.10.4"

  [ -f "$XDG_DATA_HOME/applications/nvim.desktop" ]
}
