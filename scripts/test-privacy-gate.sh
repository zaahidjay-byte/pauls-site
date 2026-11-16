#!/bin/bash
# Test the privacy-notice switch and its deploy gate (scripts/check-privacy-gate.sh).
# Builds three scratch copies of the working tree:
#   1. PRIVACY_NOTICE_LIVE = false (as committed): no /privacy/ page, not in the sitemap,
#      no footer link anywhere, gate ALLOWS.
#   2. PRIVACY_NOTICE_LIVE = true, draft markers still in the page: gate REFUSES.
#   3. PRIVACY_NOTICE_LIVE = true, markers resolved: page built, linked, in sitemap, gate ALLOWS.
#   bash scripts/test-privacy-gate.sh        (about a minute: three builds)
set -uo pipefail
cd "$(dirname "$0")/.."
SRC=$(pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

pass=0; fail=0
ok() { if [ "$1" = 0 ]; then pass=$((pass + 1)); echo "PASS $2"; else fail=$((fail + 1)); echo "FAIL $2"; fi; }
expect() { # expect <0|1> <name> <command...>
  local want=$1 name=$2; shift 2
  if "$@" >"$T/out" 2>&1; then got=0; else got=1; fi
  [ "$name" = "${name#  ...}" ] && cp "$T/out" "$T/last"   # "  ..." checks read the previous output
  if [ "$got" = "$want" ]; then ok 0 "$name"; else ok 1 "$name (exit $got, wanted $want)"; sed 's/^/     /' "$T/out"; fi
}

make_copy() { # make_copy <dir> <live:true|false> <resolve-markers:yes|no>
  local d=$1
  mkdir -p "$d"
  cp -a src public scripts astro.config.mjs tailwind.config.mjs package.json tsconfig.json "$d/"
  ln -s "$SRC/node_modules" "$d/node_modules"
  if [ "$2" = true ]; then
    perl -pi -e 's/^export const PRIVACY_NOTICE_LIVE = false;$/export const PRIVACY_NOTICE_LIVE = true;/' "$d/src/config/site.ts"
  fi
  if [ "$3" = yes ]; then
    perl -pi -e 's/ZEE TO CONFIRM/confirmed/g' "$d/src/pages/privacy/[...slug].astro"
  fi
  (cd "$d" && npx astro build >"$d/build.log" 2>&1) || { echo "build failed in $d"; tail -20 "$d/build.log"; exit 2; }
}

echo "== 1. switch OFF (committed state)"
grep -qE '^export const PRIVACY_NOTICE_LIVE = false;$' src/config/site.ts; ok $? "committed switch is false"
make_copy "$T/off" false no
expect 1 "no dist/privacy page" test -e "$T/off/dist/privacy"
expect 1 "sitemap does not list /privacy/" grep -q '/privacy/' "$T/off/dist/sitemap.xml"
expect 0 "sitemap lists the home page" grep -q '<loc>https://paulshomemade.co.za/</loc>' "$T/off/dist/sitemap.xml"
expect 1 "no page links to /privacy/" grep -rlq --include='*.html' 'href="/privacy/"' "$T/off/dist"
expect 1 "no [ZEE TO CONFIRM] anywhere in the build" grep -rlq 'ZEE TO CONFIRM' "$T/off/dist"
expect 0 "gate ALLOWS with the switch off" bash scripts/check-privacy-gate.sh "$T/off"

echo "== 2. switch ON, draft markers still there"
make_copy "$T/on-draft" true no
expect 0 "dist/privacy page is built" test -f "$T/on-draft/dist/privacy/index.html"
expect 0 "footer links to /privacy/" grep -q 'href="/privacy/"' "$T/on-draft/dist/index.html"
expect 1 "gate REFUSES: switch on + markers" bash scripts/check-privacy-gate.sh "$T/on-draft"
expect 0 "  ...naming the markers" grep -q 'ZEE TO CONFIRM' "$T/last"

echo "== 3. switch ON, markers resolved"
make_copy "$T/on-ok" true yes
expect 0 "sitemap lists /privacy/" grep -q '/privacy/' "$T/on-ok/dist/sitemap.xml"
expect 0 "gate ALLOWS: switch on, no markers" bash scripts/check-privacy-gate.sh "$T/on-ok"

echo "== 4. inconsistent build: switch off but a privacy page present"
mkdir -p "$T/off/dist/privacy" && cp "$T/on-ok/dist/privacy/index.html" "$T/off/dist/privacy/"
expect 1 "gate REFUSES a stray /privacy/ page with the switch off" bash scripts/check-privacy-gate.sh "$T/off"

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
