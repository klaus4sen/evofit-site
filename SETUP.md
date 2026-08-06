# EVO FIT — Backend Setup & Publishing Guide

Your site supports real client accounts (email login), PR tracking, progress photos,
promo codes, an announcement bar, a photo gallery, a sponsors ticker, and an
uploadable technique video library. All of it runs on a free **Supabase** project.

This takes about 15–20 minutes if you're starting fresh. If you already have a
Supabase project connected (check — your keys may already be filled in near the
top of the `<script>` tag in `evofit.html`), skip to Step 3.

## 1. Create your project
1. Go to [supabase.com](https://supabase.com) → sign up → **New Project**.
2. Pick a name, a database password (save it somewhere), and a region close to
   Saudi Arabia (e.g. `eu-central` or `ap-south`).
3. Wait ~2 minutes for it to spin up.

## 2. Get your keys
In your project: **Settings → API**. Copy:
- **Project URL**
- **anon public key**

Open `evofit.html`, find this near the top of the `<script>` tag, and paste them in:
```js
const SUPABASE_URL = "YOUR_SUPABASE_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

## 3. Client login — no SMS setup needed
Clients log in with a one-time **6-digit code sent to their email**, not SMS.
Supabase's built-in email provider handles this automatically — there is
**nothing to turn on and no Twilio/SMS provider required.** (An earlier version
of this guide mentioned phone/SMS login — that's no longer accurate; ignore it
if you saw it before.)

Optional polish: **Authentication → Email Templates** lets you customize the
"Magic Link / OTP" email your clients receive (subject line, wording, your logo).

## 4. Run the database setup script
Open **`supabase-setup.sql`** (in this same folder) → copy all of it → in your
Supabase project go to **SQL Editor → New query** → paste it → **Run**.

It's safe to run even if some tables already exist — every statement uses
`if not exists` / `drop policy if exists` so it won't error out or duplicate data.

This creates:
- `site_data` — generic storage for programs, prices, trainer profile, gallery, partners, announcement bar, coach notes
- `profiles` — one row per client (name, email, phone, program, PRs, progress photos)
- `orders` — created automatically when a client checks out
- `discounts` — your promo codes

## 5. Create the storage buckets
Go to **Storage** → create three buckets, all set to **Public**:
- `review-photos` (also used for your trainer photo and Gallery uploads)
- `progress-photos`
- `exercise-videos`

For each bucket, go to **Policies** and add:
```sql
create policy "public read" on storage.objects for select using (bucket_id = 'review-photos');
create policy "public upload" on storage.objects for insert with check (bucket_id = 'review-photos');
```
(Repeat for `progress-photos` and `exercise-videos`, swapping the bucket name.)

> Free tier gives you 1GB of storage and a 50MB per-file upload limit — fine for
> photos and short technique clips. For longer/higher-res videos, consider
> uploading to YouTube unlisted and just linking instead.

## 6. Test it
1. Reload `evofit.html` in your browser (as a real hosted page, or open the file
   directly — Supabase features work either way once your keys are set).
2. Click the person-icon in the nav → log in with your own email → check you
   receive a real code.
3. Add a PR, upload a progress photo → check they appear in Supabase's
   **Table Editor** and **Storage**.
4. Log in as coach (footer → "Coach Login" → your `ADMIN_PASSWORD`) → try each
   tab, especially the new ones: Trainer Profile, Gallery, Partners, and the
   announcement bar at the top of Discounts.

---

## 7. Publishing the site live — Vercel

`evofit.html` is a single self-contained file — nothing to build, no server needed.
Just rename it to `index.html` before deploying (Vercel serves `index.html` as
the homepage automatically).

**Fastest — Vercel CLI, no GitHub needed:**
1. Make sure [Node.js](https://nodejs.org) is installed on your computer.
2. Put `index.html` (renamed from `evofit.html`) alone in its own folder.
3. Open a terminal in that folder and run:
   ```
   npx vercel login
   ```
   Follow the prompt — it'll email/browser-verify you, then log in.
4. Then run:
   ```
   npx vercel --prod
   ```
   Answer the setup questions (project name, etc. — defaults are fine; when it
   asks about a framework, "Other" is correct since this is plain HTML).
5. You'll get a live `https://your-project.vercel.app` URL immediately.
6. To use your own domain: Vercel dashboard → your project → **Settings → Domains**
   → add your domain and follow the DNS instructions it gives you (usually just
   adding an A or CNAME record with your domain registrar).

**Alternative — via GitHub:**
1. Create a GitHub repo, upload `index.html` to it.
2. [vercel.com](https://vercel.com) → **Add New → Project → Import** your repo → **Deploy**.
3. Every future push to that repo auto-redeploys the live site.

The file works exactly the same locally and once live — nothing needs to change,
since it's already pointed at your real Supabase project.

## 8. Before you go live — quick checklist
- [ ] Ran `supabase-setup.sql` in your Supabase project (Step 4)
- [ ] Created the 3 storage buckets with policies (Step 5)
- [ ] Tested email login, PR tracking, and photo upload work (Step 6)
- [ ] **Changed `ADMIN_PASSWORD`** in `evofit.html` from the demo value —
      search for `evofit2026` in the file and replace both the constant and
      any leftover reference to it with your own password before deploying,
      since your dashboard is only protected by this front-end check
- [ ] Filled in your real bank/IBAN details in the checkout section (`[Your Bank Name]`, IBAN, etc.)
- [ ] Filled in your real WhatsApp number (`WHATSAPP_NUMBER` near the top of the script)

## What still needs a decision from you
- **Linking payment → account automatically.** Right now a client's program/tier
  is self-reported, not verified against an actual payment. True automatic
  verification means adding a real payment processor (Stripe, Moyasar, or a
  Saudi-specific gateway) that marks a client active on payment — a separate,
  bigger integration. Happy to help with that next if you want it.
- **The loyalty discount** just displays a code after 90 days — it doesn't
  automatically apply it anywhere, since there's no payment system wired up yet.
