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

create extension if not exists pgcrypto;

create table if not exists public.health_sync_tokens (
  id text primary key,
  token_hash text not null,
  updated_at timestamptz not null default now()
);

alter table public.health_sync_tokens enable row level security;

create or replace function public.upsert_health_daily(
  sync_token text,
  target_date date,
  steps_count integer,
  distance_meters numeric,
  sleep_total_minutes integer,
  sleep_quality_score integer default null
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
      and token_hash = crypt(sync_token, token_hash)
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
    updated_at
  )
  values (
    target_date,
    steps_count,
    distance_meters,
    sleep_total_minutes,
    sleep_quality_score,
    now()
  )
  on conflict (date)
  do update set
    steps = excluded.steps,
    distance_m = excluded.distance_m,
    sleep_minutes = excluded.sleep_minutes,
    sleep_score = excluded.sleep_score,
    updated_at = now()
  returning * into saved_row;

  return saved_row;
end;
$$;

grant execute on function public.upsert_health_daily(text, date, integer, numeric, integer, integer) to anon, authenticated;

-- Run once after replacing CHANGE_ME_WITH_LONG_RANDOM_TEXT.
-- insert into public.health_sync_tokens (id, token_hash)
-- values ('galaxy-s24', crypt('CHANGE_ME_WITH_LONG_RANDOM_TEXT', gen_salt('bf')))
-- on conflict (id)
-- do update set token_hash = excluded.token_hash, updated_at = now();
