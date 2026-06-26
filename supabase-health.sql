create table if not exists public.health_daily (
  date date primary key,
  steps integer,
  distance_m numeric,
  sleep_minutes integer,
  sleep_score integer,
  sleep_start_at timestamptz,
  sleep_end_at timestamptz,
  sleep_latency_minutes integer,
  deep_sleep_minutes integer,
  rem_sleep_minutes integer,
  light_sleep_minutes integer,
  awake_minutes integer,
  updated_at timestamptz not null default now()
);

alter table public.health_daily
  add column if not exists sleep_start_at timestamptz,
  add column if not exists sleep_end_at timestamptz,
  add column if not exists sleep_latency_minutes integer,
  add column if not exists deep_sleep_minutes integer,
  add column if not exists rem_sleep_minutes integer,
  add column if not exists light_sleep_minutes integer,
  add column if not exists awake_minutes integer;

update public.health_daily
set sleep_latency_minutes = null
where sleep_latency_minutes is not null;

alter table public.health_daily enable row level security;

drop policy if exists "Public read health daily" on public.health_daily;
create policy "Public read health daily"
on public.health_daily
for select
using (true);

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.health_sync_tokens (
  id text primary key,
  token_hash text not null,
  updated_at timestamptz not null default now()
);

alter table public.health_sync_tokens enable row level security;

drop function if exists public.upsert_health_daily(text, date, integer, numeric, integer, integer);
drop function if exists public.upsert_health_daily(text, date, integer, numeric, integer, integer, timestamptz, timestamptz, integer, integer, integer, integer, integer);

create or replace function public.upsert_health_daily(
  sync_token text,
  target_date date,
  steps_count integer,
  distance_meters numeric,
  sleep_total_minutes integer,
  sleep_quality_score integer default null,
  sleep_start_at timestamptz default null,
  sleep_end_at timestamptz default null,
  sleep_latency_minutes integer default null,
  deep_sleep_minutes integer default null,
  rem_sleep_minutes integer default null,
  light_sleep_minutes integer default null,
  awake_minutes integer default null
)
returns public.health_daily
language plpgsql
security definer
set search_path = public
as $$
declare
  saved_row public.health_daily;
  token_is_valid boolean;
begin
  select exists (
    select 1
    from public.health_sync_tokens
    where id = 'galaxy-s24'
      and token_hash = extensions.crypt(sync_token, token_hash)
  )
  into token_is_valid;

  if not token_is_valid then
    raise exception 'Invalid health sync token'
      using errcode = '28000';
  end if;

  insert into public.health_daily as daily (
    date,
    steps,
    distance_m,
    sleep_minutes,
    sleep_score,
    sleep_start_at,
    sleep_end_at,
    sleep_latency_minutes,
    deep_sleep_minutes,
    rem_sleep_minutes,
    light_sleep_minutes,
    awake_minutes,
    updated_at
  )
  values (
    target_date,
    steps_count,
    distance_meters,
    sleep_total_minutes,
    sleep_quality_score,
    sleep_start_at,
    sleep_end_at,
    sleep_latency_minutes,
    deep_sleep_minutes,
    rem_sleep_minutes,
    light_sleep_minutes,
    awake_minutes,
    now()
  )
  on conflict (date)
  do update set
    steps = excluded.steps,
    distance_m = excluded.distance_m,
    sleep_minutes = excluded.sleep_minutes,
    sleep_score = excluded.sleep_score,
    sleep_start_at = excluded.sleep_start_at,
    sleep_end_at = excluded.sleep_end_at,
    sleep_latency_minutes = excluded.sleep_latency_minutes,
    deep_sleep_minutes = excluded.deep_sleep_minutes,
    rem_sleep_minutes = excluded.rem_sleep_minutes,
    light_sleep_minutes = excluded.light_sleep_minutes,
    awake_minutes = excluded.awake_minutes,
    updated_at = now()
  returning * into saved_row;

  return saved_row;
end;
$$;

grant execute on function public.upsert_health_daily(text, date, integer, numeric, integer, integer, timestamptz, timestamptz, integer, integer, integer, integer, integer) to anon, authenticated;

-- Run once after replacing CHANGE_ME_WITH_LONG_RANDOM_TEXT.
-- insert into public.health_sync_tokens (id, token_hash)
-- values ('galaxy-s24', extensions.crypt('CHANGE_ME_WITH_LONG_RANDOM_TEXT', extensions.gen_salt('bf')))
-- on conflict (id)
-- do update set token_hash = excluded.token_hash, updated_at = now();
