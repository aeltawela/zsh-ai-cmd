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
  local name=$1 command_text=$2 expected=$3
  local actual=0

  _zsh_ai_cmd_is_valid_syntax "$command_text" || actual=1

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
print "============================================="
print "Results: $PASS passed, $FAIL failed"
((FAIL > 0)) && exit 1
exit 0
