create table if not exists public.photo_likes (
  photo_id text primary key,
  count integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.photo_likes enable row level security;

drop policy if exists "Public read photo likes" on public.photo_likes;
create policy "Public read photo likes"
on public.photo_likes
for select
using (true);

create or replace function public.increment_photo_like(photo_key text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  next_count integer;
begin
  insert into public.photo_likes as likes (photo_id, count, updated_at)
  values (photo_key, 1, now())
  on conflict (photo_id)
  do update set
    count = likes.count + 1,
    updated_at = now()
  returning likes.count into next_count;

  return next_count;
end;
$$;

grant execute on function public.increment_photo_like(text) to anon, authenticated;
