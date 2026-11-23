#!/bin/bash
#
# Self-check for this project: lint, fault injection and mutation tests.
#
# 1. Lints every shell and JavaScript file.
# 2. Builds a sandbox HOME with a fake game folder and a stub runtime, so the
#    installer runs fully offline: no download, no network, no Steam, and no
#    chance of touching a real installation.
# 3. Feeds the installer wrong inputs on purpose and checks it refuses as promised.
# 4. Mutation tests: breaks one guard in a COPY of the installer and proves the
#    matching fault is then no longer caught. A guard nobody tests is a comment.
#
# HOW TO RUN
#   ./test/run-tests.sh
#
# Exits non-zero if anything fails.

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL  %s%s\n' "$1" "${2:+ :: $2}"; }

# check <label> <command...> — runs the command, reports pass or fail from its
# exit status. Using a command rather than a trailing $? keeps shellcheck honest
# (SC2319) and makes the intent obvious at the call site.
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; fi
}

BASEPATH="/usr/bin:/bin:/usr/sbin:/sbin"

echo "lint"

for f in install.sh uninstall.sh Install.command Uninstall.command test/run-tests.sh; do
  if bash -n "$REPO/$f" 2>/dev/null; then ok "bash -n $f"; else bad "bash -n $f"; fi
done

for f in files/shim.js files/preload.js; do
  if node --check "$REPO/$f" 2>/dev/null; then ok "node --check $f"; else bad "node --check $f"; fi
done

if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning "$REPO/install.sh" "$REPO/uninstall.sh" "$REPO/Install.command" "$REPO/Uninstall.command" "$REPO/test/run-tests.sh" 2>/dev/null; then
    ok "shellcheck (warnings and above)"
  else
    bad "shellcheck (warnings and above)"
  fi
else
  printf '  skip  shellcheck (not installed)\n'
fi

# ---------------------------------------------------------------------------
# Sandbox: a fake HOME with a game and an already-installed stub runtime. With
# the runtime present the installer skips both downloads and never uses the net.
# ---------------------------------------------------------------------------
make_sandbox() {
  SB="$(mktemp -d)"
  GAME="$SB/Library/Application Support/Steam/steamapps/common/The Curious Expedition"
  RT="$SB/Library/Application Support/CuriousExpedition-Metal"
  FAKEBIN="$SB/bin"
  mkdir -p "$GAME/app" "$RT/electron/Electron.app/Contents/MacOS" "$RT/node_modules/@electron/remote" "$FAKEBIN"
  : > "$GAME/app/play-electron.html"
  printf '#!/bin/bash\necho "v45.4.1"\n' > "$RT/electron/Electron.app/Contents/MacOS/Electron"
  chmod +x "$RT/electron/Electron.app/Contents/MacOS/Electron"
  printf '#!/bin/bash\necho "ORIGINAL LAUNCHER"\n' > "$GAME/run_app.sh"
  chmod +x "$GAME/run_app.sh"
}

run_install() {
  env -i HOME="$SB" PATH="$FAKEBIN:$BASEPATH" /bin/bash "${INSTALLER:-$REPO/install.sh}" "$@" >"$SB/out.txt" 2>&1
}

fake_uname()  { printf '#!/bin/bash\necho "%s"\n' "$1" > "$FAKEBIN/uname"; chmod +x "$FAKEBIN/uname"; }
fake_swvers() { printf '#!/bin/bash\necho "ProductVersion:\t%s"\n' "$1" > "$FAKEBIN/sw_vers"; chmod +x "$FAKEBIN/sw_vers"; }
fake_wrong_runtime() {
  printf '#!/bin/bash\necho "v3.0.9"\n' > "$RT/electron/Electron.app/Contents/MacOS/Electron"
  chmod +x "$RT/electron/Electron.app/Contents/MacOS/Electron"
}

echo "happy path"

make_sandbox
run_install; code=$?
check "installs with a valid environment" test "$code" -eq 0
check "reports Steam integration by default" grep -q "Steam's Play button now starts" "$SB/out.txt"
check "creates an executable launcher" test -x "$SB/Applications/Curious Expedition (Metal).app/Contents/MacOS/launch"
check "repoints Steam's launcher" grep -q "Electron.app/Contents/MacOS/Electron" "$GAME/run_app.sh"
check "backs up the original launcher" test -f "$GAME/run_app.sh.pre-metal"
check "records the game path" test "$(cat "$RT/game-path")" = "$GAME"
rm -rf "$SB"

echo "fault injection"

make_sandbox; fake_uname "x86_64"
run_install; code=$?
check "refuses on an Intel Mac" test "$code" -ne 0
check "says why it refused" grep -q "not Apple Silicon" "$SB/out.txt"
check "writes no launcher when refusing" test -z "$(ls -A "$SB/Applications" 2>/dev/null)"
rm -rf "$SB"

make_sandbox; fake_swvers "10.15.7"
run_install; code=$?
check "refuses on macOS older than 11" test "$code" -ne 0
check "names the requirement" grep -q "macOS 11" "$SB/out.txt"
rm -rf "$SB"

make_sandbox; rm -rf "$GAME"
run_install; code=$?
check "refuses when the game is absent" test "$code" -ne 0
check "names the missing game path" grep -q "was not found" "$SB/out.txt"
rm -rf "$SB"

make_sandbox; fake_wrong_runtime
run_install; code=$?
check "refuses when the runtime reports the wrong version" test "$code" -ne 0
check "reports the runtime failure" grep -q "did not start" "$SB/out.txt"
rm -rf "$SB"

make_sandbox; rm -f "$GAME/run_app.sh"
run_install; code=$?
check "still installs when run_app.sh is missing" test "$code" -eq 0
check "explains that Steam was left alone" grep -q "no run_app.sh" "$SB/out.txt"
rm -rf "$SB"

make_sandbox
run_install --no-steam; code=$?
check "--no-steam installs" test "$code" -eq 0
check "--no-steam leaves the launcher untouched" grep -q "ORIGINAL LAUNCHER" "$GAME/run_app.sh"
check "--no-steam creates no backup" test ! -f "$GAME/run_app.sh.pre-metal"
rm -rf "$SB"

make_sandbox
ALT="$SB/Elsewhere/The Curious Expedition"
mkdir -p "$ALT/app"; : > "$ALT/app/play-electron.html"
printf '#!/bin/bash\necho "alt"\n' > "$ALT/run_app.sh"; chmod +x "$ALT/run_app.sh"
env -i HOME="$SB" PATH="$FAKEBIN:$BASEPATH" TCE_GAME_DIR="$ALT" /bin/bash "$REPO/install.sh" >"$SB/out.txt" 2>&1
code=$?
check "honours TCE_GAME_DIR" test "$code" -eq 0
check "records the overridden game path" test "$(cat "$RT/game-path")" = "$ALT"
rm -rf "$SB"

echo "uninstall"

make_sandbox
run_install >/dev/null 2>&1
env -i HOME="$SB" PATH="$FAKEBIN:$BASEPATH" /bin/bash "$REPO/uninstall.sh" >"$SB/un.txt" 2>&1
code=$?
check "uninstall succeeds after a normal install" test "$code" -eq 0
check "removes the runtime" test ! -d "$RT"
check "removes the launcher" test ! -d "$SB/Applications/Curious Expedition (Metal).app"
check "restores the original launcher" grep -q "ORIGINAL LAUNCHER" "$GAME/run_app.sh"
env -i HOME="$SB" PATH="$FAKEBIN:$BASEPATH" /bin/bash "$REPO/uninstall.sh" >"$SB/un2.txt" 2>&1
code=$?
check "uninstall is idempotent" test "$code" -eq 0
check "second uninstall leaves the launcher alone" grep -q "ORIGINAL LAUNCHER" "$GAME/run_app.sh"
rm -rf "$SB"

echo "mutation"

# mutant <label> <find> <replace> <setup> <caught|notcaught>
#
# The mutation is a literal string replacement done in node. sed escaping produced
# mutants that were syntax errors rather than mutants. An empty find-string means
# CONTROL: the script runs unmutated, so a passing mutant is distinguishable from
# a check that never ran. A find-string that is absent FAILS the test rather than
# silently testing the original file.
mutant() {
  local label="$1" find="$2" replace="$3" setup="$4" want="$5"
  local dir; dir="$(mktemp -d)"
  cp "$REPO/install.sh" "$dir/install.sh"
  cp -R "$REPO/files" "$dir/files"

  if [ -n "$find" ]; then
    if ! FIND="$find" REPL="$replace" node -e '
      const fs = require("fs");
      const p = process.argv[1];
      const s = fs.readFileSync(p, "utf8");
      const f = process.env.FIND, r = process.env.REPL;
      if (!s.includes(f)) { console.error("mutation target not found"); process.exit(3) }
      fs.writeFileSync(p, s.replace(f, r));
    ' "$dir/install.sh"; then
      bad "$label" "the mutation target was not found in install.sh"
      rm -rf "$dir"; return
    fi
  fi

  make_sandbox
  eval "$setup"
  INSTALLER="$dir/install.sh" run_install >/dev/null 2>&1
  local code=$?
  rm -rf "$SB" "$dir"

  local caught=0 want_caught=0
  [ "$code" -ne 0 ] && caught=1
  [ "$want" = "caught" ] && want_caught=1
  check "$label" test "$caught" -eq "$want_caught"
}

CPU_GUARD='[ "$(uname -m)" = "arm64" ]'
MACOS_GUARD='[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 11 ]'
VERSION_GUARD='[ "$got" = "v$ELECTRON_VERSION" ]'

mutant "control: unmutated installer catches the Intel fault" "" "" "fake_uname x86_64" caught
mutant "mutant: neutered CPU guard stops catching the Intel fault" "$CPU_GUARD" "[ 1 = 1 ]" "fake_uname x86_64" notcaught
mutant "mutant: neutered macOS guard stops catching an old system" "$MACOS_GUARD" "[ 1 = 1 ]" "fake_swvers 10.15.7" notcaught
mutant "mutant: accepting any runtime version stops catching the wrong build" "$VERSION_GUARD" "[ 1 = 1 ]" "fake_wrong_runtime" notcaught

echo "documents"

check_claim() {
  local claim="$1"
  if head -c 300 "$REPO/README.md" | grep -q "$claim"; then
    ok "README first 300 chars name '$claim'"
  else
    bad "README first 300 chars name '$claim'"
  fi
}
check_claim "vibecoded"
check_claim "no human took part"
check_claim "Metal"
check_claim "M1 through M6"
check "README records the Rosetta deadline" grep -q "macOS 27" "$REPO/README.md"

# Attribution: every shipped file names the game, so every shipped file must carry
# the credit. Checked with the exact phrase, not a loose match on the studio name.
for f in README.md DESCRIPTION.md KNOWN-ISSUES.md docs/STEAM-GUIDE.md LICENSE \
         install.sh uninstall.sh Install.command Uninstall.command \
         files/shim.js files/preload.js .gitignore; do
  check "attribution in $f" grep -q "Curious Expedition by Maschinen-Mensch" "$REPO/$f"
done

# test/ is excluded: this file contains the search pattern itself, and would
# otherwise report forever that the repository contains an identity.
if grep -rq -i "localhost\|rundellredhaed" "$REPO" --exclude-dir=test --exclude-dir=.git --include="*.md" --include="*.sh" --include="*.js" 2>/dev/null; then
  bad "no personal identity in shipped files"
else
  ok "no personal identity in shipped files"
fi

if grep -rq -E "@(name|description|tags):" "$REPO" --exclude-dir=test --exclude-dir=.git --include="*.sh" --include="*.js" 2>/dev/null; then
  bad "no script metadata headers"
else
  ok "no script metadata headers"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "all checks passed ($PASS)"
  exit 0
fi
echo "$FAIL failed, $PASS passed"
exit 1
