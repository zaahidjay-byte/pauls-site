#!/bin/bash
# Deploy pauls-site to stl-vps. Read DEPLOY.md first: it needs Zee's go, and the
# one-time server setup must already be done.
#
#   bash scripts/deploy.sh prod     # https://paulshomemade.co.za
#   bash scripts/deploy.sh dev      # https://dev.paulshomemade.co.za (needs its own setup)
#
# Steps: refuse unless the tree is clean and committed -> build -> refuse if the build still
# holds placeholders -> upload to a NEW release folder -> back up the live release ->
# swap the live symlink atomically -> check key pages -> roll back by itself if a check fails.
# It never deletes anything on the server.
set -euo pipefail

TARGET=${1:-}
case "$TARGET" in
  prod) BASE=/var/www/pauls-prod-site; PUBLIC=https://paulshomemade.co.za ;;
  dev)  BASE=/var/www/pauls-dev-site;  PUBLIC=https://dev.paulshomemade.co.za ;;
  *) echo "usage: bash scripts/deploy.sh <prod|dev>" >&2; exit 2 ;;
esac
SSH_HOST=stl-vps                       # ~/.ssh/config: zee@195.201.100.75
REMOTE_TOOL='~/bin/pauls-site-release.sh'

cd "$(dirname "$0")/.."
die() { echo "STOP: $*" >&2; exit 1; }

# 1. Only committed code goes live, so git says exactly what is on the server.
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || die "not on main"
git diff --quiet HEAD -- || die "uncommitted changes to tracked files"
[ -z "$(git status --porcelain -- src public astro.config.mjs tailwind.config.mjs package.json)" ] \
  || die "untracked or changed files under src/ or public/ would be built"
SHA=$(git rev-parse --short HEAD)
ID="$(date -u +%Y%m%dT%H%M%SZ)-$SHA"
echo "==> release $ID ($TARGET)"

# 2. Build from scratch.
rm -rf dist
npm run build >/dev/null
[ -f dist/index.html ] || die "build produced no dist/index.html"

# 3. Nothing unfinished goes live.
if grep -rlq 'ZEE TO CONFIRM' dist; then
  die "the build still contains [ZEE TO CONFIRM] markers (privacy notice not approved). Resolve them, or remove the privacy page, its footer link and its sitemap.xml entry, then commit."
fi
if grep -rliq 'lorem ipsum' dist; then die "the build contains Lorem ipsum"; fi

# 4. Server tool + preflight (release folder exists and is writable, current is a symlink).
ssh "$SSH_HOST" 'mkdir -p ~/bin'
scp -q scripts/remote-release.sh "$SSH_HOST:bin/pauls-site-release.sh"
ssh "$SSH_HOST" "bash $REMOTE_TOOL $TARGET preflight"

# 5. Upload into a brand-new folder; the live site is untouched until the swap.
rsync -a --chmod=D755,F644 dist/ "$SSH_HOST:$BASE/releases/$ID/"
ssh "$SSH_HOST" "printf '%s\n' $(git rev-parse HEAD) > $BASE/releases/$ID.sha"

# 6. Backup of what is live now, then the atomic swap.
ssh "$SSH_HOST" "bash $REMOTE_TOOL $TARGET backup"
ssh "$SSH_HOST" "bash $REMOTE_TOOL $TARGET activate $ID"

# 7. Check on the server; if anything fails, put the previous release back at once.
if ! ssh "$SSH_HOST" "bash $REMOTE_TOOL $TARGET verify"; then
  echo "==> checks failed on release $ID: rolling back" >&2
  if ssh "$SSH_HOST" "bash $REMOTE_TOOL $TARGET rollback"; then
    die "DEPLOY FAILED, ROLLED BACK: the previous release is live again and answered its checks (above). $ID stays on the server, unused."
  else
    die "DEPLOY FAILED AND THE ROLLBACK DID NOT VERIFY: read the lines above, check $PUBLIC/ by hand now, and stop for Zee."
  fi
fi

# 8. One public check through Cloudflare (HTML is not cached there).
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$PUBLIC/")
echo "public $PUBLIC/ -> $code"

echo
echo "LIVE: $ID"
echo "Rollback (one line): ssh $SSH_HOST 'bash $REMOTE_TOOL $TARGET rollback'"
