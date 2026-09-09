create table public.social_follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint social_follows_no_self check (follower_id <> following_id)
);

create index social_follows_following_idx
  on public.social_follows (following_id, created_at desc);

alter table public.social_follows enable row level security;
revoke all on table public.social_follows from anon;
grant select, insert, delete on table public.social_follows to authenticated;

create policy social_follows_authenticated_read
on public.social_follows
for select
to authenticated
using (true);

create policy social_follows_owner_insert
on public.social_follows
for insert
to authenticated
with check ((select auth.uid()) = follower_id);

create policy social_follows_owner_delete
on public.social_follows
for delete
to authenticated
using ((select auth.uid()) = follower_id);

create table public.checkin_likes (
  checkin_id uuid not null references public.checkins(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (checkin_id, user_id)
);

create index checkin_likes_user_idx
  on public.checkin_likes (user_id, created_at desc);

alter table public.checkin_likes enable row level security;
revoke all on table public.checkin_likes from anon;
grant select, insert, delete on table public.checkin_likes to authenticated;

create policy checkin_likes_authenticated_read
on public.checkin_likes
for select
to authenticated
using (true);

create policy checkin_likes_owner_insert
on public.checkin_likes
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy checkin_likes_owner_delete
on public.checkin_likes
for delete
to authenticated
using ((select auth.uid()) = user_id);

create table public.checkin_comments (
  id uuid primary key default gen_random_uuid(),
  checkin_id uuid not null references public.checkins(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint checkin_comments_body_length check (
    char_length(btrim(body)) between 1 and 500
  )
);

create index checkin_comments_checkin_idx
  on public.checkin_comments (checkin_id, created_at asc);
create index checkin_comments_user_idx
  on public.checkin_comments (user_id, created_at desc);

alter table public.checkin_comments enable row level security;
revoke all on table public.checkin_comments from anon;
grant select, insert, delete on table public.checkin_comments to authenticated;

create policy checkin_comments_authenticated_read
on public.checkin_comments
for select
to authenticated
using (true);

create policy checkin_comments_owner_insert
on public.checkin_comments
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy checkin_comments_owner_delete
on public.checkin_comments
for delete
to authenticated
using ((select auth.uid()) = user_id);

create function public.get_social_feed(
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  user_id uuid,
  workout_type text,
  duration_minutes smallint,
  note text,
  photo_path text,
  performed_at timestamptz,
  created_at timestamptz,
  username text,
  display_name text,
  like_count bigint,
  comment_count bigint,
  liked_by_me boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    c.id,
    c.user_id,
    c.workout_type,
    c.duration_minutes,
    c.note,
    c.photo_path,
    c.performed_at,
    c.created_at,
    p.username,
    p.display_name,
    (select count(*) from public.checkin_likes l where l.checkin_id = c.id) as like_count,
    (select count(*) from public.checkin_comments cm where cm.checkin_id = c.id) as comment_count,
    exists (
      select 1
      from public.checkin_likes mine
      where mine.checkin_id = c.id
        and mine.user_id = (select auth.uid())
    ) as liked_by_me
  from public.checkins c
  join public.profiles p on p.id = c.user_id
  where c.user_id = (select auth.uid())
     or exists (
       select 1
       from public.social_follows f
       where f.follower_id = (select auth.uid())
         and f.following_id = c.user_id
     )
  order by c.created_at desc
  limit least(greatest(p_limit, 1), 50)
  offset greatest(p_offset, 0)
$$;

revoke all on function public.get_social_feed(integer, integer) from public, anon;
grant execute on function public.get_social_feed(integer, integer) to authenticated;
