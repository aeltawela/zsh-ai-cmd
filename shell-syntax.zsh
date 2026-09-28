# Validate generated commands with the same shell that will run them.
# `-n` parses the command without executing it. Parse-only mode treats end of
# input as closing some unfinished constructs that leave an interactive shell
# waiting for more lines after Enter, so those are rejected before parsing.
_zsh_ai_cmd_is_valid_syntax() {
  # Runs inside the user's interactive shell, where options such as ksh_arrays
  # change indexing and globbing. The helpers below inherit these local options.
  emulate -L zsh
  _zsh_ai_cmd_ends_in_escaped_newline "$1" && return 1

  # Shell-lexer words: quoted strings and $(( )) arithmetic stay single words,
  # so operators inside them are not mistaken for top-level operators.
  local -a words=(${(z)1})
  _zsh_ai_cmd_has_comment "${words[@]}" && return 1
  _zsh_ai_cmd_ends_in_list_operator "${words[-1]:-}" && return 1
  _zsh_ai_cmd_has_heredoc "${words[@]}" && return 1

  command zsh -f -n -c "$1" >/dev/null 2>&1
}

# An odd run of final backslashes escapes Enter, leaving an interactive shell
# at a continuation prompt.
_zsh_ai_cmd_ends_in_escaped_newline() {
  local index=${#1} trailing_backslashes=0
  while (( index > 0 )) && [[ ${1[index]} == $'\\' ]]; do
    trailing_backslashes=$(( trailing_backslashes + 1 ))
    index=$(( index - 1 ))
  done
  (( trailing_backslashes % 2 == 1 ))
}

# Whether # starts a comment depends on the user's interactive_comments
# setting: with it off, text after # is parsed as arguments and an apostrophe
# there opens a quote; with it on, the comment hides whatever it follows, such
# as a trailing &&. A comment cannot be validated either way and a suggestion
# has no need for one. The lexer keeps # inside quotes, ${#x}, $#, and a#b in
# a larger word, so only a word starting with # marks a comment.
_zsh_ai_cmd_has_comment() {
  local word
  for word in "$@"; do
    [[ $word == '#'* ]] && return 0
  done
  return 1
}

# A final && or || leaves the shell at a cmdand> or cmdor> prompt.
_zsh_ai_cmd_ends_in_list_operator() {
  [[ $1 == '&&' || $1 == '||' ]]
}

# Suggestions are sanitized to a single line, so a heredoc body and terminator
# can never follow the operator. Matches <<, <<-, and fd-prefixed forms such as
# 0<<; the <<< here-string is complete on one line and stays allowed.
# A heredoc nested inside $( ) or backticks is one lexer word and is not seen.
_zsh_ai_cmd_has_heredoc() {
  local word
  for word in "$@"; do
    [[ $word == *'<<'(|-) && $word != *'<<<' ]] && return 0
  done
  return 1
}
