-- Drop obsolete tables
drop table if exists public.ride_requests cascade;
drop table if exists public.rides cascade;
drop table if exists public.drivers_available cascade;
drop table if exists public.customer_requests cascade;

-- Table for Groups
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users (id) on delete cascade,
  origin_lat double precision not null,
  origin_lng double precision not null,
  dest_lat double precision not null,
  dest_lng double precision not null,
  status text not null default 'gathering', -- 'gathering', 'searching_driver', 'driver_assigned', 'cancelled', 'completed'
  driver_id uuid references auth.users (id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '4 minutes'
);

-- Table for Group Members
create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending', -- 'pending', 'accepted', 'rejected'
  created_at timestamptz not null default now()
);

-- Table for Online Drivers
create table if not exists public.drivers_online (
  user_id uuid primary key references auth.users (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.drivers_online enable row level security;

-- Policies Groups
create policy "Select all groups" on public.groups for select to authenticated using (true);
create policy "Insert own group" on public.groups for insert to authenticated with check (auth.uid() = creator_id);
create policy "Update group" on public.groups for update to authenticated using (true);

-- Policies Group Members
create policy "Select all members" on public.group_members for select to authenticated using (true);
create policy "Insert own membership" on public.group_members for insert to authenticated with check (auth.uid() = user_id);
create policy "Update membership" on public.group_members for update to authenticated using (true);

-- Policies Drivers Online
create policy "Select all online" on public.drivers_online for select to authenticated using (true);
create policy "Insert own online" on public.drivers_online for insert to authenticated with check (auth.uid() = user_id);
create policy "Update own online" on public.drivers_online for update to authenticated using (auth.uid() = user_id);
create policy "Delete own online" on public.drivers_online for delete to authenticated using (auth.uid() = user_id);

-- Realtime
alter publication supabase_realtime add table public.groups;
alter publication supabase_realtime add table public.group_members;
alter publication supabase_realtime add table public.drivers_online;
