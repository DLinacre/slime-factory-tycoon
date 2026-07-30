#!/usr/bin/env bash
# Runs every check CI runs, locally. No GitHub Actions needed.
# Usage: ./tools/verify.sh
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
say() { printf "\n\033[1m== %s\033[0m\n" "$1"; }
ok()  { printf "  \033[32mPASS\033[0m %s\n" "$1"; }
bad() { printf "  \033[31mFAIL\033[0m %s\n" "$1"; fail=1; }
skip(){ printf "  \033[33mSKIP\033[0m %s (not installed)\n" "$1"; }

say "Config validity"
python3 -c "import json;json.load(open('default.project.json'))" \
  && ok "default.project.json" || bad "default.project.json"

say "Balance simulation (gates progression targets)"
if python3 tools/balance_sim.py --hours 6 --check; then
  ok "balance within targets"
else
  bad "balance outside targets -- see warnings above"
fi

say "Luau syntax (all modules must compile)"
if command -v luau-compile >/dev/null 2>&1; then
  syn=0
  while IFS= read -r f; do
    out=$(luau-compile --binary "$f" 2>&1 >/dev/null)
    [ -n "$out" ] && { bad "$f"; echo "$out" | head -3; syn=1; }
  done < <(find src -name '*.luau' | sort)
  [ $syn -eq 0 ] && ok "all $(find src -name '*.luau' | wc -l) modules compile"
else skip "luau-compile"; fi

say "Lint"
if command -v selene >/dev/null 2>&1; then
  selene src && ok "selene" || bad "selene"
else skip "selene"; fi

say "Format"
if command -v stylua >/dev/null 2>&1; then
  stylua --check src && ok "stylua" || bad "stylua (run: stylua src)"
else skip "stylua"; fi

say "Build"
if command -v rojo >/dev/null 2>&1; then
  rojo build default.project.json --output /tmp/_verify.rbxlx >/dev/null \
    && ok "rojo build" || bad "rojo build"
else skip "rojo"; fi

echo
[ $fail -eq 0 ] && printf "\033[32mAll checks passed.\033[0m\n" || printf "\033[31mSome checks failed.\033[0m\n"
exit $fail
