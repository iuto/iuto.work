create table if not exists public.health_daily (
  date date primary key,
  steps integer,
  distance_m numeric,
  sleep_minutes integer,
  sleep_score integer,
  updated_at timestamptz not null default now()
);

alter table public.health_daily enable row level security;

drop policy if exists "Public read health daily" on public.health_daily;
create policy "Public read health daily"
on public.health_daily
for select
using (true);
