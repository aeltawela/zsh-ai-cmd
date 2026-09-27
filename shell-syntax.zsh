# Validate generated commands with the same shell that will run them.
# `-n` parses the command without executing it.
_zsh_ai_cmd_is_valid_syntax() {
  # An odd run of final backslashes escapes Enter, leaving an interactive shell
  # at a continuation prompt even though parse-only mode accepts EOF.
  local index=${#1} trailing_backslashes=0
  while (( index > 0 )) && [[ ${1[index]} == $'\\' ]]; do
    trailing_backslashes=$(( trailing_backslashes + 1 ))
    index=$(( index - 1 ))
  done
  (( trailing_backslashes % 2 == 1 )) && return 1
  command zsh -f -n -c "$1" >/dev/null 2>&1
}
