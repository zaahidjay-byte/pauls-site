#!/bin/bash
# Server half of the pauls-site deploy. Copied to stl-vps by scripts/deploy.sh and run as
# zee (no sudo). Works only inside the release folder of one target:
#
#   /var/www/pauls-prod-site/            (dev: /var/www/pauls-dev-site/)
#     releases/<release-id>/             one folder per deploy, never edited after upload
#     releases/<release-id>.sha          the git commit it was built from
#     current -> releases/<release-id>   what nginx serves (root .../current)
#     previous                           text file: the release that was live before
#
# Usage: remote-release.sh <prod|dev> <preflight|backup|activate <id>|verify|rollback>
#
# It never deletes anything. Old releases and backups stay until Zee says otherwise.
set -euo pipefail
umask 022

TARGET=${1:-}
ACTION=${2:-}
case "$TARGET" in
  prod) BASE=/var/www/pauls-prod-site; HOST=paulshomemade.co.za ;;
  dev)  BASE=/var/www/pauls-dev-site;  HOST=dev.paulshomemade.co.za ;;
  *) echo "usage: $0 <prod|dev> <action>" >&2; exit 2 ;;
esac
# Test-only overrides (scripts/test-remote-release.sh): a scratch folder and a local URL.
BASE=${PAULS_SITE_BASE:-$BASE}
TEST_URL=${PAULS_SITE_TEST_URL:-}
BACKUP_DIR=${PAULS_SITE_BACKUP_DIR:-$HOME/backups/pauls-site}

die() { echo "ERROR: $*" >&2; exit 1; }

current_release() {
  [ -L "$BASE/current" ] || die "$BASE/current is not a symlink: one-time setup not done (DEPLOY.md)"
  basename "$(readlink "$BASE/current")"
}

# path|text the page must contain
CHECKS=(
  "/|How It Works"
  "/events/|Our Setups"
  "/flavours/|Flavours"
  "/story/|The man. The scoop. The story."
  "/book/|Request My Quote"
  "/contact/|Send Message"
  "/sitemap.xml|<urlset"
  "/home-assets/how-it-works/anim/3-setup.html|tuk-tuk"
)

verify() {
  local fails=0 entry path want code body
  for entry in "${CHECKS[@]}"; do
    path=${entry%%|*}; want=${entry#*|}
    # straight to this server's nginx (no Cloudflare cache), real hostname and certificate
    if [ -n "$TEST_URL" ]; then
      body=$(curl -s --max-time 15 -w '\n%{http_code}' "$TEST_URL$path" || true)
    else
      body=$(curl -s --max-time 15 --resolve "$HOST:443:127.0.0.1" -w '\n%{http_code}' "https://$HOST$path" || true)
    fi
    code=${body##*$'\n'}
    if [ "$code" = 200 ] && grep -qF -- "$want" <<<"${body%$'\n'*}"; then
      echo "  ok   $code $path"
    else
      echo "  FAIL $code $path (expected 200 containing: $want)"
      fails=$((fails + 1))
    fi
  done
  [ "$fails" -eq 0 ]
}

swap_to() {
  local id=$1
  [ -f "$BASE/releases/$id/index.html" ] || die "release $id has no index.html"
  ln -sfn "releases/$id" "$BASE/current.new"
  mv -T "$BASE/current.new" "$BASE/current"   # rename(2): atomic, no window without a site
}

case "$ACTION" in
  preflight)
    [ -d "$BASE/releases" ] && [ -w "$BASE/releases" ] || die "$BASE/releases missing or not writable by $(id -un)"
    cur=$(current_release)   # assignment, so a failure here stops the script (set -e)
    echo "live release: $cur"
    ;;
  backup)
    cur=$(current_release)
    mkdir -p "$BACKUP_DIR"
    out="$BACKUP_DIR/$TARGET-$cur-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
    tar -czf "$out" -C "$BASE/releases" "$cur"
    n=$(tar -tzf "$out" | wc -l)
    [ "$n" -gt 10 ] || die "backup $out looks empty ($n entries)"
    echo "backup: $out ($n entries, $(du -h "$out" | cut -f1))"
    ;;
  activate)
    id=${3:-}; [ -n "$id" ] || die "activate needs a release id"
    cur=$(current_release)
    [ "$cur" != "$id" ] || die "$id is already live"
    printf '%s\n' "$cur" > "$BASE/previous"
    swap_to "$id"
    echo "live release: $id (was $cur)"
    ;;
  verify)
    echo "checking https://$HOST on this server:"
    verify
    ;;
  rollback)
    [ -f "$BASE/previous" ] || die "no previous release recorded"
    prev=$(cat "$BASE/previous")
    cur=$(current_release)
    swap_to "$prev"
    printf '%s\n' "$cur" > "$BASE/previous"
    echo "rolled back: live release is $prev (was $cur)"
    verify || die "site still failing after rollback"
    ;;
  *) die "unknown action: $ACTION" ;;
esac
