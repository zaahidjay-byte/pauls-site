#!/bin/bash
# Privacy-notice gate, run by scripts/deploy.sh on a fresh build (and by
# scripts/test-privacy-gate.sh). Reads PRIVACY_NOTICE_LIVE from src/config/site.ts.
#   live = true : /privacy/ must be built, and NO [ZEE TO CONFIRM] marker may be in dist/.
#   live = false: /privacy/ must not be built, not in sitemap.xml, not linked from any page.
# Usage: bash scripts/check-privacy-gate.sh [siteRoot]   (exit 0 = ok to deploy)
set -uo pipefail
ROOT=${1:-.}
CFG="$ROOT/src/config/site.ts"
DIST="$ROOT/dist"
die() { echo "PRIVACY GATE: $*" >&2; exit 1; }

[ -f "$DIST/index.html" ] || die "no build in $DIST"
n=$(grep -cE '^export const PRIVACY_NOTICE_LIVE = (true|false);$' "$CFG" 2>/dev/null)
[ "$n" = 1 ] || die "cannot read PRIVACY_NOTICE_LIVE from $CFG (expected one line: export const PRIVACY_NOTICE_LIVE = true|false;)"
if grep -qE '^export const PRIVACY_NOTICE_LIVE = true;$' "$CFG"; then LIVE=true; else LIVE=false; fi

if [ "$LIVE" = true ]; then
  [ -f "$DIST/privacy/index.html" ] || die "PRIVACY_NOTICE_LIVE is true but dist has no /privacy/ page"
  if grep -rlq 'ZEE TO CONFIRM' "$DIST"; then
    die "PRIVACY_NOTICE_LIVE is true but the build still contains [ZEE TO CONFIRM] markers: resolve them (PRIVACY_DRAFT.md) or set it back to false"
  fi
  echo "privacy gate: notice LIVE, no markers in the build"
else
  [ ! -e "$DIST/privacy" ] || die "PRIVACY_NOTICE_LIVE is false but dist has a /privacy/ page"
  if grep -q '/privacy/' "$DIST/sitemap.xml" 2>/dev/null; then die "PRIVACY_NOTICE_LIVE is false but sitemap.xml lists /privacy/"; fi
  if grep -rlq --include='*.html' 'href="/privacy/"' "$DIST"; then die "PRIVACY_NOTICE_LIVE is false but a page links to /privacy/"; fi
  if grep -rlq 'ZEE TO CONFIRM' "$DIST"; then die "a [ZEE TO CONFIRM] marker is in the build outside the privacy page"; fi
  echo "privacy gate: notice OFF (not built, not in sitemap, not linked)"
fi
