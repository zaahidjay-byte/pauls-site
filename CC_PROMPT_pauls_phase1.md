# CC PROMPT — Paul's Homemade Events: Phase 1 (backend fixes + public site completion)

## Context
Two systems are involved, both already in production on the Hetzner VPS (195.201.100.75):
1. **Blaqsuga 4 backend** — FastAPI + MariaDB (`blaqsuga4_db`), repo `Pauls-Ice-Cream/Fast API System/`, prod `/opt/blaqsuga4`, `blaqsuga4.service`, uvicorn on 127.0.0.1:8002, Nginx vhost `admin.paulshomemade.co.za` (Cloudflare-proxied, origin HTTP). Public `POST /enquiry` exists (Pydantic `EnquiryIn`, slowapi 5/hour, honeypot field `website`), writes to `blaq_events` (status `pending`) + upserts `blaq_venues`. `notify_new_enquiry` emails via Gmail SMTP from env in `/opt/blaqsuga4/.env`.
2. **Public site** — Astro 4 repo at `~/Code/pauls-site/`, pages index/book/contact/events/flavours/story, currently deployed to `dev.paulshomemade.co.za` (Nginx vhost `pauls-dev`, root `/var/www/pauls-dev`).

Goal: hard deadline ~mid-June 2026 (Bridal Expo 27–28 June; printed QR points at paulshomemade.co.za). This session ships the backend fixes, finishes the site on **dev**, and PREPARES (but does not activate) the apex. Confirmed via Cloudflare dashboard: NO DNS record exists for the apex or www — the domain currently resolves to nothing. Therefore creating and enabling an apex Nginx vhost is zero-risk (unreachable until DNS exists). DO NOT touch DNS or Cloudflare in any way — the human adds the DNS records manually as the final cutover step.

## Standing rules (binding)
- **Backup before risky ops:** before any migration or backend deploy, create `mysqldump blaqsuga4_db` + tarball of `/opt/blaqsuga4` into `/mnt/c/Users/User/Documents/Code/backups/` (timestamped).
- **Prod-first-then-git** where applicable; commit on a feature branch `feature/pauls-phase1-intake`.
- **No state-mutating "tests":** do not POST to `/enquiry` or create rows as a test. The human performs the single manual end-to-end test after deploy.
- **Stop and ask** before anything destructive, anything touching the apex domain, or anything not listed below.
- Do not print secrets. When checking `.env`, report only which keys are present/absent.

## PART 1 — Backend (do this first)

### 1.1 Migration (alembic, next revision after 0015)
Add to `blaq_events`:
- `organiser_phone VARCHAR(20) NULL`
- `event_address VARCHAR(512) NULL` (structured address for Phase 2 geocoding)
- `equipment_request TEXT NULL` (JSON array of selected equipment slugs)
- `units_requested INT NULL` (mini-pint units)
- `bains_requested INT NULL`

### 1.2 Schema + mapping (`app/schemas/enquiry.py`, `event_service.create_enquiry`)
- Extend `EnquiryIn`: `equipment: list[str] = []` (validate against allowed slugs: `phicycle`, `scooping-freezer`, `scooping-cart`, `tuk-tuk`, `countertop-freezer`), `units: int | None` (ge=0, le=10000), `bains: int | None` (ge=0, le=50), `address: str | None` (≤512), keep all existing fields.
- Mapping: store email → `organiser_contact` AND phone → `organiser_phone` (both, never either/or). `address` → `event_address`. `equipment` JSON-serialised → `equipment_request`. `units`/`bains` → new columns. `custom_branding` continues to map as today.
- Do not change existing field behaviour otherwise; existing admin enquiry form must keep working (new fields optional).

### 1.3 Rate-limit fix (critical)
slowapi currently keys on `request.client.host`, which behind Cloudflare→nginx is the proxy IP — all real visitors share one 5/hour bucket. Replace the key func with: `CF-Connecting-IP` header if present → else first IP in `X-Forwarded-For` → else `request.client.host`. Apply to the `/enquiry` limit. Keep 5/hour per real client IP.

### 1.4 Notification check (read-only)
Report whether `NOTIFY_TO`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM` are set in `/opt/blaqsuga4/.env` (presence only, no values). If any are missing, STOP and report before deploying — the silent no-op in `notify_new_enquiry` would mean missed leads.

### 1.5 Deploy backend
Backup per standing rule, then `bash deploy/deploy.sh --migrate`, then `systemctl status blaqsuga4.service` and tail logs for clean startup. Verify `GET /` (public form) and admin login page respond 200 via curl on loopback. No test enquiries.

## PART 2 — Public site (Astro, `~/Code/pauls-site/`)

### 2.0 Inspect first
Report current state of each page and the book/enquiry form (if one exists) before changing anything. Reuse what's good; don't rebuild what works.

### 2.1 Brand tokens
- Colours: navy `#11266A`, primary blue `#1D44C2`, magenta `#C40093`, light blue `#BEE8F6`, plus white/neutrals. Navy/blue dominant, magenta as accent only (CTA, highlights).
- Fonts: **Oswald** (headings) and **Mulish** (body) — self-host via Fontsource or Google Fonts. These are the licensed substitutes for the official Adobe faces; do NOT reference any Typekit kit.
- Logo: a hi-res PNG named `Logo.png` already exists in the pauls-site folder — locate it (check repo root and asset dirs; if multiple candidates or not found, STOP and ask). Generate full favicon set + OG image from it. Treat logo as fixed-size raster; no layouts requiring large-scale logo.
- Photos: human will place files in `src/assets/photos/` (mix of franchisor-supplied and own event photography). Use what's present; lazy-load; compress to webp at build.

### 2.2 Pages
- **Home:** hero (people-forward photo, headline "Your big day, scooped to perfection"), equipment overview cards, CTA to /book. 
- **Events:** the five setups below, each with photo, description, capacity, requirements, and a "Get a quote" CTA prefilling that equipment on /book.
- **Story:** company history (existing copy if present; keep adapted, not verbatim from paulshomemade.com) + new short "About the events team" section: Johannesburg-based Paul's Homemade franchise events team, bookings for weddings, corporate and private events. Placeholder marked `<!-- ZEE: review copy -->` for the human to personalise.
- **Contact:** phone/WhatsApp 082 678 3697, Instagram @paulshomemadeevents (link https://www.instagram.com/paulshomemadeevents), enquiry CTA. No other socials.
- **Flavours:** keep existing if present; otherwise minimal gallery, not a priority.
- Footer: franchise attribution line ("An official Paul's Homemade franchise — events division"), Instagram icon only.

### 2.3 Equipment copy (use this wording; items marked [CONFIRM] need the human's numbers — render them but flag in final report)

**The Phicycle** — slug `phicycle`
"No power point? No problem. The Phicycle is our retro ice-cream bicycle, fully self-contained and ready to roll into any space. It serves Paul's mini pints straight from the bike — simple, nostalgic, and zero setup fuss."
Minimum order: 40 units · No electricity required · Handles 200+ guests · Ideal for kids' parties, school and sports days, outdoor gatherings, and corporate functions.

**Scooping Freezer** — slug `scooping-freezer` (optional gazebo)
"A freestanding scooping station with a small footprint and big output. Up to 6 bains of your chosen flavours — around 192 scoops — served fresh, with optional toppings. Slots neatly into indoor or outdoor venues, with a gazebo available for open-air events."
Minimum: 4 bains · 100–250 guests · Requires a standard plug point · Ideal for weddings, corporate events, bar/bat mitzvahs, and large celebrations.

**Scooping Cart** — slug `scooping-cart`
"The classic ice-cream cart, reimagined. Mobile, photogenic, and built for service — up to 6 bains scooped fresh with optional toppings. The centrepiece option for guests who want the full scooping experience."
Minimum: 4 bains · 100–250 guests · Requires a standard plug point · Ideal for weddings, festivals, brand activations, and celebrations.

**The Tuk Tuk** — slug `tuk-tuk`
"Our flagship setup. The Paul's Tuk Tuk carries up to 8 bains — around 256 scoops — and can stock mini-pint units alongside, the biggest capacity we offer, with toppings included as an option. It needs room to shine, so it's best suited to outdoor events and large indoor venues."
Minimum: 4 bains · 200–1,000+ guests · Requires a plug point and a generous setup footprint.

**Countertop Freezer** — slug `countertop-freezer`
"Our most compact option: a branded countertop freezer serving Paul's mini pints from any table or counter. The lowest-footprint setup for intimate gatherings and indoor venues."
Requires a standard plug point · Ideal for small private events, office functions, and intimate celebrations. (Minimum order and guest range not yet confirmed — OMIT those lines from public copy for now; flag in final report so the human adds them later.)

**Custom branding (add-on, shown on Events and Book pages):**
"Want it in your colours? We offer custom branding on our equipment — your logo and brand identity on the setup — for clients who want the experience fully theirs. Available at an additional cost; tell us what you have in mind in your quote request."

### 2.4 Quote form (/book)
Fields → existing+new `/enquiry` schema:
- Name* (`name`), Email (`email`), Phone (`phone`) — require at least one of email/phone client-side
- Event type (`event_type` enum dropdown), Event date* (`event_date`), Start/End time (`start_time`/`end_time`)
- Headcount (`headcount`), Venue name (`venue`), Venue type (`venue_type`), Event address (`address`) — full street address, helper text "for travel calculation in your quote"
- Equipment (`equipment`) — multi-select cards of the five setups; Units (`units`) and Bains (`bains`) numeric steppers shown conditionally on relevant selections (enforce minimums client-side: 40 units / 4 bains)
- Custom branding — checkbox revealing textarea → `custom_branding`
- Special requests (`special_requests`)
- Hidden honeypot input named `website`, visually hidden, empty by default
POST JSON to `https://admin.paulshomemade.co.za/enquiry`. On 201: success state "Thanks — your quote request is in. We'll send your formal quote shortly." On 429: friendly "please try again in a little while" message. On validation error: inline messages. Mobile-first; this will mostly be scanned from a printed QR on phones.

### 2.5 Deploy site (dev) + prepare apex vhost
1. `astro build` → deploy `dist/` to `/var/www/pauls-dev` (existing pauls-dev vhost). Verify https://dev.paulshomemade.co.za renders, form page loads, no console errors.
2. Prepare production: create `/var/www/pauls-prod`, deploy the SAME verified `dist/` build to it. Create Nginx vhost `pauls-prod`: `server_name paulshomemade.co.za www.paulshomemade.co.za`, root `/var/www/pauls-prod`, listen 80 (Cloudflare will terminate SSL, matching the admin vhost pattern), sensible cache headers for static assets, gzip on. `nginx -t` then reload. This is SAFE: confirmed via Cloudflare dashboard that no DNS record exists for apex or www, so this vhost is unreachable until the human creates the records.
3. DO NOT create, modify, or delete any DNS records. DO NOT touch the admin, dev, pos-staging, or scoop vhosts.

## Manual cutover (HUMAN ONLY — after the end-to-end test passes)
Performed by Zee in the Cloudflare dashboard, not by CC:
1. Submit one real enquiry from https://dev.paulshomemade.co.za/book → confirm notification email arrives AND the row appears in the admin pipeline as pending → cancel the test row in the admin UI.
2. In Cloudflare DNS, add: `A` record, name `@`, content `195.201.100.75`, **Proxied** (orange cloud); and `A` record, name `www`, content `195.201.100.75`, **Proxied**.
3. Visit https://paulshomemade.co.za on a phone, scan the actual printed QR from the advert proof, and submit nothing — just confirm it resolves and renders.
Post-launch hardening (not blocking): zone SSL mode is effectively Flexible (origin speaks HTTP only) — schedule a Cloudflare Origin CA cert + nginx 443 + Full (strict) as a follow-up task.

## Final report
List: migration applied, files changed, .env key presence, form→endpoint field mapping table, location of Logo.png used, remaining gaps (countertop freezer minimums), confirmation that the pauls-prod vhost is enabled and awaiting DNS, and a restatement of the human-only cutover steps above.
