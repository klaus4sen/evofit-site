-- ============================================================
-- EVO FIT — Full Supabase setup (run this ONCE, top to bottom)
-- Go to your Supabase project → SQL Editor → New query → paste all
-- of this → Run.
-- ============================================================

-- 1. Generic key/value store — programs, tier prices, trainer profile,
--    gallery, partners, announcement bar, coach notes, monthly goal, etc.
create table if not exists site_data (
  key text primary key,
  value jsonb not null
);
alter table site_data enable row level security;
drop policy if exists "public read" on site_data;
drop policy if exists "public write" on site_data;
create policy "public read" on site_data for select using (true);
create policy "public write" on site_data for all using (true) with check (true);
-- Note: "public write" means anyone who finds your anon key could edit this table
-- via the API directly. Your coach password gate stops normal visitors, but not a
-- determined technical user. Fine for a single-coach business; ask if you want it
-- locked down to a real admin role later.

-- 2. One row per client (their login is by EMAIL — a one-time code sent to their
--    inbox, not SMS/phone, so no Twilio or SMS provider is needed).
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  phone text,
  name text,
  program text,
  join_date timestamptz default now(),
  prs jsonb default '[]'::jsonb,
  progress_photos jsonb default '[]'::jsonb
);
alter table profiles enable row level security;
drop policy if exists "clients manage own profile" on profiles;
drop policy if exists "coach can read all profiles" on profiles;
create policy "clients manage own profile" on profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "coach can read all profiles" on profiles
  for select using (true);
-- ^ lets your dashboard's "Clients" tab list everyone. There's no separate coach
-- login through Supabase (your dashboard uses the simple password gate instead),
-- so this read policy is intentionally open. Don't share your anon key or admin password.

-- If this table already existed from an earlier setup without the email column:
alter table profiles add column if not exists email text;

-- 3. Orders — created when a client checks out and sends their WhatsApp receipt.
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references auth.users(id) on delete set null,
  client_email text,
  client_name text,
  program text,
  tier text,
  price numeric,
  qty integer default 1,
  status text default 'pending', -- pending | paid | cancelled
  discount_code text,
  created_at timestamptz default now(),
  paid_at timestamptz
);
alter table orders enable row level security;
drop policy if exists "public insert" on orders;
drop policy if exists "public read" on orders;
drop policy if exists "public update" on orders;
create policy "public insert" on orders for insert with check (true);
create policy "public read" on orders for select using (true);
create policy "public update" on orders for update using (true);
alter table orders add column if not exists discount_code text;

-- 4. Discounts / promo codes — created from the Coach Dashboard's Discounts tab,
--    validated live at checkout.
create table if not exists discounts (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  percent_off integer not null,
  client_id uuid references auth.users(id) on delete cascade,
  note text,
  created_at timestamptz default now()
);
alter table discounts enable row level security;
drop policy if exists "public read" on discounts;
drop policy if exists "public write" on discounts;
create policy "public read" on discounts for select using (true);
create policy "public write" on discounts for all using (true) with check (true);

-- ============================================================
-- Done. Next: Storage → create 3 public buckets (review-photos,
-- progress-photos, exercise-videos) with the policies from SETUP.md.
-- ============================================================
