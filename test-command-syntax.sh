#!/usr/bin/env zsh
# test-command-syntax.sh - Reject commands that leave Zsh parsing incomplete.

set -uo pipefail

SCRIPT_DIR="${0:a:h}"
source "$SCRIPT_DIR/shell-syntax.zsh"

if (( ! $+functions[_zsh_ai_cmd_is_valid_syntax] )); then
  print -u2 "shell syntax validator was not loaded"
  exit 2
fi

PASS=0
FAIL=0

run_test() {
  local name=$1 command_text=$2 expected=$3 user_option=${4:-}
  local actual=0

  # The optional user_option is set in a subshell to mimic an interactive
  # shell's options without leaking into later tests.
  if [[ -n $user_option ]]; then
    ( setopt "$user_option"; _zsh_ai_cmd_is_valid_syntax "$command_text" ) || actual=1
  else
    _zsh_ai_cmd_is_valid_syntax "$command_text" || actual=1
  fi

  printf "%-45s " "$name"
  if (( actual == expected )); then
    print -P "%F{green}PASS%f"
    ((PASS++))
  else
    print -P "%F{red}FAIL%f"
    ((FAIL++))
  fi
}

print "Testing generated command syntax validation"
print "============================================="
run_test "valid command is accepted" 'echo "hello"' 0
run_test "unclosed double quote is rejected" 'echo "hello' 1
run_test "unclosed single quote is rejected" "echo 'hello" 1
run_test "dangling continuation is rejected" $'echo hello \\' 1
run_test "escaped trailing backslashes are accepted" 'echo hello \\\\' 0
run_test "trailing && is rejected" 'echo a &&' 1
run_test "trailing && with spaces is rejected" 'echo a &&   ' 1
run_test "trailing && without space is rejected" 'echo a&&' 1
run_test "trailing || is rejected" 'echo a ||' 1
run_test "&& between commands is accepted" 'echo a && ls' 0
run_test "|| between commands is accepted" 'echo a || true' 0
run_test "background & is accepted" 'echo a &' 0
run_test "quoted trailing && is accepted" 'echo "&&"' 0
run_test "heredoc is rejected" 'cat <<EOF' 1
run_test "heredoc without space is rejected" 'cat<<EOF' 1
run_test "tab-stripping heredoc is rejected" 'cat <<-EOF' 1
run_test "fd-prefixed heredoc is rejected" 'cat 0<<EOF' 1
run_test "heredoc mid-pipeline is rejected" 'cat <<EOF | wc -l' 1
run_test "here-string is accepted" 'cat <<< "hi"' 0
run_test "here-string without space is accepted" 'cat <<<hi' 0
run_test "quoted << is accepted" 'echo "a << b"' 0
run_test "arithmetic shift is accepted" 'echo $(( 1 << 2 ))' 0
run_test "arithmetic command shift is accepted" '(( x = 1 << 2 ))' 0
run_test "ksh_arrays: continuation is rejected" 'echo "x" \' 1 ksh_arrays
run_test "ksh_arrays: trailing && is rejected" 'echo a &&' 1 ksh_arrays
run_test "ksh_arrays: heredoc is rejected" 'cat <<EOF' 1 ksh_arrays
run_test "ksh_arrays: valid command is accepted" 'echo a && ls' 0 ksh_arrays
run_test "comment with apostrophe is rejected" "ls -la # don't show hidden" 1
run_test "comment after trailing && is rejected" 'make && # then deploy' 1
run_test "interactive_comments: comment is rejected" 'make && # then deploy' 1 interactive_comments
# Any comment is rejected, including one that would otherwise be harmless
run_test "comment containing << is rejected" 'git log --oneline # compare <<older' 1
run_test "# inside a word is accepted" 'echo a#b' 0
run_test "\${#x} length is accepted" 'echo ${#x}' 0
run_test "\$# argument count is accepted" 'echo $#' 0
run_test "# inside single quotes is accepted" "print -P '%F{red}#x'" 0
run_test "# inside quoted option is accepted" "git log --format='%h #%s'" 0
run_test "ksh_arrays: # inside a word is accepted" 'echo a#b' 0 ksh_arrays
print "============================================="
print "Results: $PASS passed, $FAIL failed"
((FAIL > 0)) && exit 1
exit 0
