-- RE:BID auction marketplace schema
create extension if not exists "pgcrypto";
create type public.auction_status as enum ('draft','scheduled','live','ended','cancelled');
create type public.condition_grade as enum ('A','B','C','D');
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade, display_name text, phone text, role text not null default 'buyer' check(role in ('buyer','seller','admin')), created_at timestamptz not null default now());
create table public.lots (id uuid primary key default gen_random_uuid(), sku text unique, title text not null, description text, category text not null, condition_grade public.condition_grade not null, condition_notes text, retail_price numeric(12,2), opening_bid numeric(12,2) not null, reserve_price numeric(12,2), bid_increment numeric(12,2) not null default 50, current_bid numeric(12,2), image_urls text[] not null default '{}', collection_location text, status public.auction_status not null default 'draft', starts_at timestamptz, ends_at timestamptz, created_at timestamptz not null default now());
create table public.bids (id uuid primary key default gen_random_uuid(), lot_id uuid not null references public.lots(id) on delete cascade, bidder_id uuid not null references public.profiles(id), amount numeric(12,2) not null check(amount>0), created_at timestamptz not null default now());
create index bids_lot_created_idx on public.bids(lot_id,created_at desc);
create table public.watchlist (user_id uuid references public.profiles(id) on delete cascade, lot_id uuid references public.lots(id) on delete cascade, created_at timestamptz not null default now(), primary key(user_id,lot_id));
create table public.orders (id uuid primary key default gen_random_uuid(), lot_id uuid unique not null references public.lots(id), buyer_id uuid not null references public.profiles(id), winning_bid numeric(12,2) not null, payment_status text not null default 'pending', fulfilment_method text, status text not null default 'awaiting_payment', created_at timestamptz not null default now());
alter table public.profiles enable row level security; alter table public.lots enable row level security; alter table public.bids enable row level security; alter table public.watchlist enable row level security; alter table public.orders enable row level security;
create policy "public lots readable" on public.lots for select using (status in ('scheduled','live','ended'));
create policy "bids readable" on public.bids for select using (true);
create policy "authenticated can bid" on public.bids for insert to authenticated with check (auth.uid()=bidder_id);
create policy "own watchlist" on public.watchlist for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "own profile readable" on public.profiles for select to authenticated using(auth.uid()=id);
create policy "own orders readable" on public.orders for select to authenticated using(auth.uid()=buyer_id);
