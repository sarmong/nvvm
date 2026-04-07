# bash completion for nvvm

_nvvm_versions() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/nvvm/releases.json"
  [[ -f "$cache" ]] && command -v jq &>/dev/null && jq -r '.[].tag_name | ltrimstr("v")' "$cache"
}

_nvvm_installed() {
  local lib="${XDG_DATA_HOME:-$HOME/.local/share}/nvvm/lib"
  [[ -d "$lib" ]] && ls "$lib"
}

_nvvm() {
  local cur prev words cword
  _init_completion || return

  case $cword in
    1)
      mapfile -t COMPREPLY < <(compgen -W "install uninstall use list run refresh help --help --version" -- "$cur")
      ;;
    2)
      case $prev in
        install|use)  mapfile -t COMPREPLY < <(compgen -W "$(_nvvm_versions)" -- "$cur") ;;
        uninstall)    mapfile -t COMPREPLY < <(compgen -W "--force -f $(_nvvm_installed)" -- "$cur") ;;
        run)          mapfile -t COMPREPLY < <(compgen -W "$(_nvvm_installed)" -- "$cur") ;;
      esac
      ;;
    *)
      case ${words[1]} in
        uninstall)
          mapfile -t COMPREPLY < <(compgen -W "--force -f $(_nvvm_installed)" -- "$cur")
          ;;
        run)
          COMP_WORDS=("nvim" "${COMP_WORDS[@]:3}")
          COMP_CWORD=$(( COMP_CWORD - 2 ))
          _command_offset 0
          ;;
      esac
      ;;
  esac
}

complete -F _nvvm nvvm
