#!/usr/bin/env bash
set -euo pipefail

# Simulate hms providing starship in a user profile which ns later removes.
profile_dir="$TMPDIR/transient-profile/bin"
mkdir -p "$profile_dir"
export PATH="$profile_dir:$PATH"
export STARSHIP_CONFIG="$TMPDIR/starship.toml"
export STARSHIP_CACHE="$TMPDIR/starship-cache"
export TERM=xterm-256color COLUMNS=80
cat > "$STARSHIP_CONFIG" <<'EOF'
format = '$character'
[character]
success_symbol = 'PROMPT_OK'
error_symbol = 'PROMPT_ERROR'
EOF

for shell in zsh bash nu; do
  ln -s "$originalStarship/bin/starship" "$profile_dir/starship"
  init_args=("$shell")
  if [[ "$shell" == bash ]]; then
    init_args+=(--print-full-init)
  fi
  "$starshipPackage/bin/starship" init "${init_args[@]}" > "init.$shell"
  case "$shell" in
    zsh)
      zsh -f -c '
        source ./init.zsh
        rm "$1/starship"
        prompt_starship_precmd
        print -r -- "${(e)PROMPT}"
      ' test "$profile_dir" > prompt.out 2> prompt.err
      ;;
    bash)
      bash --noprofile --norc -c '
        source ./init.bash
        rm "$1/starship"
        starship_precmd
        printf "%s\n" "$PS1"
      ' test "$profile_dir" > prompt.out 2> prompt.err
      ;;
    nu)
      nu --no-config-file -c '
        use ./init.nu
        rm ($env.PATH | first | path join "starship")
        $env.CMD_DURATION_MS = 0
        $env.LAST_EXIT_CODE = 0
        do $env.PROMPT_COMMAND
      ' > prompt.out 2> prompt.err
      ;;
  esac || { cat prompt.err >&2; exit 1; }
  cat prompt.err
  test ! -s prompt.err
  grep -q PROMPT_OK prompt.out
  echo "$shell: prompt survives profile removal"
done
