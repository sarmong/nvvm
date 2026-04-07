# nvvm — Neovim Version Manager

A simple bash script to manage multiple Neovim versions.

## Requirements

- `curl`, `jq`, `sha256sum`
- `fzf` _(optional)_ — enables interactive version picker

## Installation

**Via make:**

```sh
git clone https://github.com/sarmong/nvvm.git
cd nvvm
make install
```

Detects your shell and installs completions for zsh or bash automatically.

**Manual:**

```sh
git clone https://github.com/sarmong/nvvm.git
cp nvvm/nvvm ~/.local/bin/nvvm
```

## PATH setup

Add to your shell config (`~/.zshrc` or `~/.bashrc`):

```sh
export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvvm/bin:$PATH"
```

**Zsh completions**:

```sh
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
autoload -Uz compinit && compinit
```

## Usage

| Command                                  | Description                                                                          |
| ---------------------------------------- | ------------------------------------------------------------------------------------ |
| `nvvm install <version>`                 | Install a Neovim version                                                             |
| `nvvm use <version>`                     | Switch to a version (installs it if not present)                                     |
| `nvvm list [-a\|--all]`                  | List available versions (installed marked with `*`); shows 20 most recent by default |
| `nvvm run <version> [args...]`           | Run a specific version without switching                                             |
| `nvvm uninstall [-f\|--force] <version>` | Remove an installed version (`--force` required to uninstall the active version)     |
| `nvvm refresh`                           | Refresh the releases cache                                                           |

`<version>` accepts `stable`, `latest`, full semver (`0.10.0`), partial semver
(`0.10`), or `nightly`. Omitting `<version>` for `install`, `use`, `run`, and
`uninstall` opens an fzf picker.

## Uninstall

**Via make:**

```sh
make uninstall
```

**Manual:**

```sh
rm ~/.local/bin/nvvm
rm ~/.local/share/zsh/site-functions/_nvvm
rm ~/.local/share/bash-completion/completions/nvvm
```

To also remove all installed Neovim versions and nvvm data:

```sh
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nvvm"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/nvvm"
```
