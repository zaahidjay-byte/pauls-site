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
# Usage: remote-release.sh [--test] <prod|dev> <preflight|backup|activate <id>|verify|rollback>
#
# --test is only for scripts/test-remote-release.sh on the laptop: it skips the server
# identity check and allows the PAULS_SITE_* overrides (scratch folder, local URL).
#
# It never deletes anything. Old releases and backups stay until Zee says otherwise.
set -euo pipefail
umask 022

die() { echo "ERROR: $*" >&2; exit 1; }

TEST_MODE=0
if [ "${1:-}" = --test ]; then TEST_MODE=1; shift; fi
TARGET=${1:-}
ACTION=${2:-}
case "$TARGET" in
  prod) BASE=/var/www/pauls-prod-site; HOST=paulshomemade.co.za ;;
  dev)  BASE=/var/www/pauls-dev-site;  HOST=dev.paulshomemade.co.za ;;
  *) echo "usage: $0 [--test] <prod|dev> <action>" >&2; exit 2 ;;
esac
BACKUP_DIR=$HOME/backups/pauls-site
TEST_URL=

EXPECT_HOST=smarttech-vps   # stl-vps hostname, as in ops/d8-sudo and the stl-api deploy guards
EXPECT_USER=zee
if [ "$TEST_MODE" = 1 ]; then
  BASE=${PAULS_SITE_BASE:?--test needs PAULS_SITE_BASE}
  BACKUP_DIR=${PAULS_SITE_BACKUP_DIR:?--test needs PAULS_SITE_BACKUP_DIR}
  TEST_URL=${PAULS_SITE_TEST_URL:-}
else
  for v in PAULS_SITE_BASE PAULS_SITE_TEST_URL PAULS_SITE_BACKUP_DIR; do
    [ -z "${!v:-}" ] || die "$v is set: test overrides are refused without --test"
  done
  [ "$(hostname)" = "$EXPECT_HOST" ] || die "wrong host: $(hostname), expected $EXPECT_HOST"
  [ "$(id -un)" = "$EXPECT_USER" ] || die "wrong user: $(id -un), expected $EXPECT_USER"
fi

PRE_SWITCH_SUFFIX=-pre-switch   # the copy of the old hand-deployed site made at one-time setup

current_release() {
  [ -L "$BASE/current" ] || die "$BASE/current is not a symlink: one-time setup not done (DEPLOY.md)"
  basename "$(readlink "$BASE/current")"
}

# path|visible text the page must show (HTML comments are stripped before matching).
# The animation has no visible text, so it is checked for its image element instead.
CHECKS=(
  "/|How It Works"
  "/|Ingredients"
  "/events/|Our Setups"
  "/flavours/|Flavours"
  "/story/|The man. The scoop. The story."
  "/book/|Request My Quote"
  "/contact/|Send Message"
  "/sitemap.xml|<urlset"
  '/home-assets/how-it-works/anim/3-setup.html|<img class="tuktuk"'
)
# The pre-switch release is the OLD site: it cannot pass the new site's checks.
LIGHT_CHECKS=("/|")

verify() { # verify full|light
  local fails=0 entry path want code body page
  local -a list
  if [ "${1:-full}" = light ]; then list=("${LIGHT_CHECKS[@]}"); else list=("${CHECKS[@]}"); fi
  for entry in "${list[@]}"; do
    path=${entry%%|*}; want=${entry#*|}
    # straight to this server's nginx (no Cloudflare cache), real hostname and certificate
    if [ -n "$TEST_URL" ]; then
      body=$(curl -s --max-time 15 -w '\n%{http_code}' "$TEST_URL$path" || true)
    else
      body=$(curl -s --max-time 15 --resolve "$HOST:443:127.0.0.1" -w '\n%{http_code}' "https://$HOST$path" || true)
    fi
    code=${body##*$'\n'}
    page=$(perl -0777 -pe 's/<!--.*?-->//gs' <<<"${body%$'\n'*}")
    if [ "$code" = 200 ] && { [ -z "$want" ] || grep -qF -- "$want" <<<"$page"; }; then
      echo "  ok   $code $path"
    else
      echo "  FAIL $code $path (expected 200${want:+ showing: $want})"
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
    echo "host $(hostname) as $(id -un); live release: $cur"
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
    cur=$(current_release)
    echo "checking https://$HOST on this server (release $cur):"
    if [[ "$cur" == *"$PRE_SWITCH_SUFFIX" ]]; then verify light; else verify full; fi
    ;;
  rollback)
    [ -f "$BASE/previous" ] || die "no previous release recorded"
    prev=$(cat "$BASE/previous")
    cur=$(current_release)
    swap_to "$prev"
    printf '%s\n' "$cur" > "$BASE/previous"
    echo "rolled back: live release is $prev (was $cur)"
    if [[ "$prev" == *"$PRE_SWITCH_SUFFIX" ]]; then
      echo "previous release is the pre-switch copy of the old site: home page check only; check the old site by hand"
      verify light || die "ROLLBACK DONE BUT THE OLD SITE IS NOT ANSWERING: home page check failed"
    else
      verify full || die "ROLLBACK DONE BUT THE SITE IS STILL FAILING its checks"
    fi
    echo "rollback verified"
    ;;
  *) die "unknown action: $ACTION" ;;
esac
