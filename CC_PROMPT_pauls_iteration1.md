# CC PROMPT — Paul's Phase 1: post-test iteration (dev only)

Continue on the feature branches (backend @ fba64a7+, site @ aa8681a+). All work deploys to DEV ONLY (/var/www/pauls-dev) — do not touch the prod vhost content, DNS, or other vhosts. Backend changes redeploy via the pinned /tmp/pauls-deploy worktree pattern (update it to the new tip first); no migration is expected — if you find yourself needing one, STOP and ask.

## Backend
1. **Client confirmation email:** on successful enquiry creation, send an acknowledgment to the client's email (in addition to the existing NOTIFY_TO notification). From bookings@paulshomemade.co.za. Content: thank them by name, confirm receipt with the EVT reference, summarise what they requested (event type, date, equipment, units/bains if given), say a formal quote will follow shortly, sign off Paul's Homemade Events with phone 061 407 3799. Plain text is fine. Wrap in the same fail-safe pattern as notify_new_enquiry (a send failure must never fail the enquiry write). Only send when an email is present.
2. **Notification template update:** the internal new-enquiry email to NOTIFY_TO currently omits the new fields — add phone, email, equipment list, units, bains, event address, and custom branding note so triage works from the inbox alone.
3. Service restart + journal check after deploy; curl loopback 200s as before.

## Site
4. **Email compulsory:** make email required on /book (client-side + clear inline error). Phone stays optional. Update the helper text accordingly.
5. **Logo fix:** inspect the logo asset(s) now in the repo. If a light-background variant was added, use it on light sections. If only the white/dark-background original exists, place the logo on a navy (#11266A) header band / footer band so it reads correctly. Regenerate favicons/OG from whichever variant has correct contrast on its background. Show no inverted/washed rendering anywhere.
6. **Photos:** wire in everything under src/assets/photos/ — hero (people-forward shot), equipment cards (match photos to setups where obvious from filenames; ask if ambiguous), story page, and a small gallery strip if there are enough. Compress to webp at build, lazy-load below the fold.
7. **Icons:** tastefully place the official brand icons from src/assets/icons/ — section accents, equipment card corners, list bullets. Restraint: decoration, not confetti; never inside form controls or buttons.
8. **Typography pass to mimic the official site's treatment using our licensed faces only (Oswald/Mulish — do NOT reference Adobe/Typekit):** match paulshomemade.com's header casing, weight, letter-spacing, and heading scale/layout rhythm as closely as Oswald allows. Report what you matched and what isn't matchable without their typeface.
9. `npm run build` clean, rsync dist/ to /var/www/pauls-dev only, verify live, commit both repos.

## Report
Files changed, commits, what photo went where, confirmation-email content as deployed, typography deltas, and confirm prod vhost content untouched.
