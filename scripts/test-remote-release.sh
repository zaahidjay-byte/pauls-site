#!/bin/bash
# Local test of scripts/remote-release.sh (no server involved). Builds a scratch release
# folder from dist/ (run `npm run build` first), serves it on 127.0.0.1, and checks:
# preflight, backup, a swap to a BROKEN release is caught by verify, rollback restores the
# good release, re-activating the live release is refused, and a missing setup is refused.
#   bash scripts/test-remote-release.sh
set -uo pipefail
cd "$(dirname "$0")/.."
[ -f dist/index.html ] || { echo "run npm run build first" >&2; exit 2; }

T=$(mktemp -d)
PORT=48731
SRV_PID=
cleanup() { [ -n "$SRV_PID" ] && kill "$SRV_PID" 2>/dev/null; rm -rf "$T"; }
trap cleanup EXIT

export PAULS_SITE_BASE="$T/site" PAULS_SITE_BACKUP_DIR="$T/backups" PAULS_SITE_TEST_URL="http://127.0.0.1:$PORT"
R="bash scripts/remote-release.sh prod"
mkdir -p "$T/site/releases"
cp -a dist "$T/site/releases/good"
cp -a dist "$T/site/releases/broken"
printf '<html><body>oops</body></html>\n' > "$T/site/releases/broken/index.html"
ln -s releases/good "$T/site/current"

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$T/site/current" >/dev/null 2>&1 &
SRV_PID=$!
for _ in $(seq 1 50); do curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break; sleep 0.1; done

pass=0; fail=0
check() { # name, expected exit (0/1), command...
  local name=$1 want=$2; shift 2
  if "$@" >"$T/out" 2>&1; then got=0; else got=1; fi
  if [ "$got" = "$want" ]; then pass=$((pass + 1)); echo "PASS $name"
  else fail=$((fail + 1)); echo "FAIL $name (exit $got, wanted $want)"; sed 's/^/     /' "$T/out"; fi
}
live() { basename "$(readlink "$T/site/current")"; }

check "preflight on a set-up folder" 0 $R preflight
check "verify passes on the good release" 0 $R verify
check "backup writes a tarball" 0 $R backup
check "backup tarball exists" 0 bash -c "ls $T/backups/prod-good-*.tar.gz"
check "activate the broken release" 0 $R activate broken
check "live is now broken" 0 test "$(live)" = broken
check "verify FAILS on the broken release" 1 $R verify
check "rollback restores and re-verifies" 0 $R rollback
check "live is good again" 0 test "$(live)" = good
check "activating the live release is refused" 1 $R activate good
check "activating a release without index.html is refused" 1 $R activate nothing-here
rm "$T/site/current"; mkdir "$T/site/current"
check "preflight refuses when current is not a symlink" 1 $R preflight

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
