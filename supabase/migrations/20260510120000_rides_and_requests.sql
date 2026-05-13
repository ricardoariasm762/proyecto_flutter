-- RideMatch: tablas usadas por la app (rides, ride_requests).
-- Ejecuta este archivo en Supabase → SQL Editor → Run (o `supabase db push` si usas CLI).

create table if not exists public.rides (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  origin_lat double precision not null,
  origin_lng double precision not null,
  dest_lat double precision not null,
  dest_lng double precision not null,
  status text not null default 'waiting',
  available_seats integer not null default 1,
  participants_count integer not null default 1,
  created_at timestamptz not null default now()
);

create table if not exists public.ride_requests (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.rides (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create index if not exists rides_user_id_idx on public.rides (user_id);
create index if not exists rides_created_at_idx on public.rides (created_at desc);
create index if not exists ride_requests_ride_id_idx on public.ride_requests (ride_id);
create index if not exists ride_requests_user_id_idx on public.ride_requests (user_id);

alter table public.rides enable row level security;
alter table public.ride_requests enable row level security;

grant select, insert, update, delete on public.rides to authenticated;
grant select, insert, update, delete on public.ride_requests to authenticated;

drop policy if exists "rides_select_auth" on public.rides;
create policy "rides_select_auth" on public.rides
  for select to authenticated using (true);

drop policy if exists "rides_insert_own" on public.rides;
create policy "rides_insert_own" on public.rides
  for insert to authenticated with check (auth.uid() = user_id);

-- El dueño edita su viaje; otros usuarios autenticados pueden actualizar estado al solicitar unirse.
drop policy if exists "rides_update_authenticated" on public.rides;
create policy "rides_update_authenticated" on public.rides
  for update to authenticated using (true) with check (true);

drop policy if exists "ride_requests_select_auth" on public.ride_requests;
create policy "ride_requests_select_auth" on public.ride_requests
  for select to authenticated using (true);

drop policy if exists "ride_requests_insert_own" on public.ride_requests;
create policy "ride_requests_insert_own" on public.ride_requests
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "ride_requests_update_auth" on public.ride_requests;
create policy "ride_requests_update_auth" on public.ride_requests
  for update to authenticated using (true) with check (true);

-- Realtime (streams y escucha de inserts). Si ya estaba añadida, Postgres avisará y puedes ignorarlo.
alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.ride_requests;
