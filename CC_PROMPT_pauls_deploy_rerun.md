# CC PROMPT — Paul's Phase 1: gated deployment, re-run (consolidated)

Continue from the prior session. Branches: monorepo `feature/pauls-phase1-intake` @ f3d4b23, pauls-site `feature/pauls-phase1-intake` @ c2b5d2e. SSH to zee@195.201.100.75 authorized for these steps only. No DNS/Cloudflare changes ever. Stop and ask on any gate failure. Do not print secrets — report .env keys by presence only.

## Pre-deploy code changes (commit on the feature branches)

1. **SMTP transport check:** confirm `SMTP_HOST` and `SMTP_PORT` are read from env in `app/config.py` (not hardcoded to Gmail). Live config is now cPanel mail: mail.paulshomemade.co.za:587. If `send_email()` only supports STARTTLS, that's correct for 587 — but add SSL support anyway (use `smtplib.SMTP_SSL` when port == 465, STARTTLS otherwise) as a resilience fallback.
2. **Site — bookings email:** add `bookings@paulshomemade.co.za` as a mailto link on the contact page and footer, alongside phone/WhatsApp/Instagram.
3. **Site — 60-unit minimum:** enforce client-side when Countertop Freezer is the only unit-serving equipment selected; if Phicycle is also selected, the highest applicable minimum wins.
4. `npm run build` clean; verify the email and enforcement in `dist/`; commit both repos.

## Gated deployment

**Gate 1 — .env check (HARD STOP):** all of `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `NOTIFY_TO` present in `/opt/blaqsuga4/.env`. Any missing → STOP, report which.

**Gate 1b — SMTP smoke test (HARD STOP):** via the app's `send_email()` (or equivalent one-off reading live env), send ONE email to NOTIFY_TO, subject "Blaqsuga4 SMTP smoke test". No DB writes. Failure → STOP, report the error verbatim minus credentials. On success, PAUSE and ask the human to confirm receipt in the bookings@ inbox before continuing.

**Gate 2 — backup (verify):** mysqldump `blaqsuga4_db` + tarball `/opt/blaqsuga4` → timestamped files in `Code/backups/`. Report sizes; a near-zero dump → STOP.

**Step 3 — backend deploy, worktree-pinned:** create a `/tmp` git worktree of the monorepo at the feature-branch tip (f3d4b23 or later if amended above), verify worktree HEAD immediately before deploying, run `bash deploy/deploy.sh --migrate` FROM THE WORKTREE. Then: `systemctl status blaqsuga4.service` clean, tail logs for errors, confirm migration 0016 applied, curl admin login on loopback for 200. Failure → STOP; restore plan is Gate 2 backup.

**Step 4 — site to dev:** from a pinned worktree of pauls-site at the feature tip: `rsync -az --delete dist/ zee@195.201.100.75:/var/www/pauls-dev/`. Verify https://dev.paulshomemade.co.za renders and /book loads.

**Step 5 — prod vhost (dark):** `/var/www/pauls-prod` + same dist/, Nginx vhost `pauls-prod` (server_name paulshomemade.co.za www.paulshomemade.co.za, root /var/www/pauls-prod, listen 80, gzip, static cache headers), `nginx -t`, reload. No DNS records exist for apex/www, so this stays unreachable. Touch no other vhosts.

## Final report
Gate outcomes, backup sizes, migration state, dev URL status, prod vhost enabled-and-dark, commits made, and restate: git merge/push deferred until the human's end-to-end test passes; DNS cutover is human-only.
