-- Run in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  receipt_code text not null unique check (receipt_code ~ '^GSS26-[A-F0-9]{8}$'),
  donor_name text not null check (char_length(donor_name) between 2 and 120),
  phone text not null check (phone ~ '^01[3-9][0-9]{8}$'),
  amount integer not null check (amount >= 10 and amount <= 10000000),
  payment_method text not null check (payment_method in ('bKash','Nagad','Rocket','Bank')),
  transaction_id text not null check (char_length(transaction_id) between 3 and 120),
  status text not null default 'pending' check (status in ('pending','verified','rejected')),
  created_at timestamptz not null default now(),
  verified_at timestamptz,
  verified_by uuid references auth.users(id)
);

create index if not exists donations_created_at_idx on public.donations (created_at desc);
create index if not exists donations_receipt_code_idx on public.donations (receipt_code);
alter table public.donations enable row level security;

-- Remove broad default grants; public users may only submit records.
revoke all on public.donations from anon, authenticated;
grant insert on public.donations to anon, authenticated;
grant select, update on public.donations to authenticated;

drop policy if exists "public can submit pending donations" on public.donations;
create policy "public can submit pending donations"
on public.donations for insert to anon, authenticated
with check (
  status = 'pending'
  and verified_at is null
  and verified_by is null
  and amount >= 10
  and char_length(donor_name) between 2 and 120
  and phone ~ '^01[3-9][0-9]{8}$'
);

-- Only accounts whose app_metadata.role is admin can read or update.
drop policy if exists "admins can read donations" on public.donations;
create policy "admins can read donations"
on public.donations for select to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "admins can verify donations" on public.donations;
create policy "admins can verify donations"
on public.donations for update to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Admin-only update fields should be controlled operationally:
-- grant is table-level; RLS restricts rows. Keep admin accounts private and enable MFA if possible.
