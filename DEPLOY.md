# Deploying pauls-site (paulshomemade.co.za)

Static Astro build served by nginx on stl-vps (`ssh stl-vps`, user zee), behind Cloudflare.
A deploy is a change to a live server: it needs Zee's go ("deploy") with the approval card
from `Code/CLAUDE.md`. Check STANDING GATES at the top of the vault's `working-context.md`
for freezes first.

## Per deploy (after the one-time setup below)

```
bash scripts/deploy.sh prod
```

What it does, in order:

1. Stops unless you are on `main` with nothing uncommitted (tracked files, or anything
   untracked under `src/`, `public/` or the config files), so git says exactly what is live.
2. Builds `dist/` from scratch.
3. Stops if the build contains `[ZEE TO CONFIRM` (the privacy notice is still a draft) or
   "Lorem ipsum".
4. Copies `scripts/remote-release.sh` to `~/bin/pauls-site-release.sh` on the server and runs
   its preflight (release folder exists and is writable; `current` is a symlink).
5. Uploads `dist/` into a new folder `releases/<UTC time>-<commit>/`. The live site is not
   touched.
6. Backs up the live release to `~/backups/pauls-site/prod-<release>-<time>.tar.gz` on the
   server, then swaps the `current` symlink to the new release with one rename (atomic: there
   is no moment without a site, unlike delete-then-rename).
7. Checks eight URLs on the server itself (straight to nginx, not through Cloudflare):
   home, events, flavours, story, book, contact, sitemap and one animation, each must return
   200 and contain an expected phrase. If any fails it rolls back by itself and stops.
8. Checks the public homepage through Cloudflare and prints the one-line rollback:
   `ssh stl-vps 'bash ~/bin/pauls-site-release.sh prod rollback'`

Nothing is ever deleted: old releases and backup tarballs stay until Zee says to prune them.

Nothing to restart: nginx reads the files at each request. HTML is not cached by Cloudflare
(cf-cache-status DYNAMIC); images under `/home-assets/` may be cached at the edge for up to
7 days, so a *changed* image should get a new file name (all images in this release are new
names, `.webp`).

The quote and contact forms post to Blaqsuga (`admin.paulshomemade.co.za`). If a deploy goes
with a backend field rename, deploy every site root that posts to it (dev and prod).

Local test of the server half (no server needed): `npm run build`, then
`bash scripts/test-remote-release.sh`.

## One-time setup (not done yet; needs Zee's go, and sudo)

Today nginx serves `/var/www/pauls-prod` directly and it was last updated by a manual rsync.
The new layout keeps that folder untouched as the fallback:

```
/var/www/pauls-prod-site/
  releases/<id>/         one folder per deploy
  current -> releases/<id>
  previous               the release that was live before the last swap
```

Steps (each one is a live-server change; take them on one card):

1. `sudo mkdir /var/www/pauls-prod-site /var/www/pauls-prod-site/releases` and
   `sudo chown -R zee: /var/www/pauls-prod-site`.
2. As zee: copy what is live now into the first release, so the switch changes nothing
   visible: `cp -a /var/www/pauls-prod /var/www/pauls-prod-site/releases/00000000-pre-switch`,
   then `ln -s releases/00000000-pre-switch /var/www/pauls-prod-site/current`.
3. Back up the live nginx file (`/etc/nginx/sites-available/pauls-prod`) and install
   `Code/ops/nginx/pauls-prod.conf` in its place. That file also adds the www -> apex 301 and
   the security headers (HSTS max-age one year without includeSubDomains or preload,
   nosniff, Referrer-Policy).
4. `sudo nginx -t`, then `sudo systemctl reload nginx` (a reload, not a restart).
5. Check: apex pages 200 and unchanged; `https://www.paulshomemade.co.za/x?y=1` answers 301
   to `https://paulshomemade.co.za/x?y=1`; the three headers are on the home page, on an
   image and on a `/_astro/` file.
6. Undo: put the backed-up nginx file back, `nginx -t`, reload. `/var/www/pauls-prod` was
   never touched.

Only then run `bash scripts/deploy.sh prod` for this release.

## Open questions (unverified, check before the one-time setup)

- **Who owns `/var/www/pauls-prod` today, and can zee write `/var/www`?** The July deploys
  were a plain rsync as zee, which suggests zee owns the folder, but nobody has checked since
  the sudo narrowing (vault: zee has no sudo group on stl-vps; `stl-vps-admin` logs in as
  zee-admin). Step 1 needs sudo once; per-deploy runs need none if zee owns
  `/var/www/pauls-prod-site`.
- **Can nginx (www-data) read zee-owned files?** The upload sets folders 755 and files 644,
  so yes if `/var/www/pauls-prod-site` itself is 755.
- **Does the `paulshomemade.co.za` certificate cover `www`?** The live block already serves
  www with it, and the outside review saw a `*.paulshomemade.co.za` wildcard, but check the
  certificate's names before step 3; otherwise www shows a warning before the redirect.
- **Is any other vhost already named `www.paulshomemade.co.za`?** The new file gives www its
  own server block; a second one elsewhere would make `nginx -t` warn about a conflict.
- **Cloudflare SSL mode.** The redirect sends www to `https://` apex; that is safe in every
  mode. Do not add an http -> https redirect on the apex at the origin without checking the
  mode first (with "Flexible" it would loop).
- **Dev site.** `deploy.sh dev` expects `/var/www/pauls-dev-site` and a dev nginx root of
  `/var/www/pauls-dev-site/current`; `ops/nginx/pauls-dev.conf` has not been changed. Until
  then the dev site keeps its manual rsync.
- **robots.txt** is managed by Cloudflare, and there is none in this repo, so nothing was
  added. To point search engines at the new sitemap, add
  `Sitemap: https://paulshomemade.co.za/sitemap.xml` in Cloudflare's robots.txt setting.
- **Privacy notice.** `/privacy/` is in the build and linked from the footer, so the deploy
  is blocked until Zee answers the `[ZEE TO CONFIRM]` items in `PRIVACY_DRAFT.md` (or the page,
  its footer link and its `public/sitemap.xml` entry are removed).
