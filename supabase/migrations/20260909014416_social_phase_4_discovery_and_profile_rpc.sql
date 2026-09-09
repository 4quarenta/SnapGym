create function public.search_social_profiles(
  p_query text default '',
  p_limit integer default 30
)
returns table (
  id uuid,
  username text,
  display_name text,
  bio text,
  follower_count bigint,
  following_count bigint,
  checkin_count bigint,
  is_following boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    p.id,
    p.username,
    p.display_name,
    p.bio,
    (select count(*) from public.social_follows f where f.following_id = p.id) as follower_count,
    (select count(*) from public.social_follows f where f.follower_id = p.id) as following_count,
    (select count(*) from public.checkins c where c.user_id = p.id) as checkin_count,
    exists (
      select 1
      from public.social_follows mine
      where mine.follower_id = (select auth.uid())
        and mine.following_id = p.id
    ) as is_following
  from public.profiles p
  where p.id <> (select auth.uid())
    and (
      coalesce(btrim(p_query), '') = ''
      or coalesce(p.username, '') ilike '%' || btrim(p_query) || '%'
      or coalesce(p.display_name, '') ilike '%' || btrim(p_query) || '%'
    )
  order by
    case when lower(coalesce(p.username, '')) = lower(btrim(p_query)) then 0 else 1 end,
    follower_count desc,
    p.created_at desc
  limit least(greatest(p_limit, 1), 50)
$$;

revoke all on function public.search_social_profiles(text, integer) from public, anon;
grant execute on function public.search_social_profiles(text, integer) to authenticated;

create function public.get_social_profile(p_user_id uuid)
returns table (
  id uuid,
  username text,
  display_name text,
  bio text,
  follower_count bigint,
  following_count bigint,
  checkin_count bigint,
  is_following boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    p.id,
    p.username,
    p.display_name,
    p.bio,
    (select count(*) from public.social_follows f where f.following_id = p.id) as follower_count,
    (select count(*) from public.social_follows f where f.follower_id = p.id) as following_count,
    (select count(*) from public.checkins c where c.user_id = p.id) as checkin_count,
    exists (
      select 1
      from public.social_follows mine
      where mine.follower_id = (select auth.uid())
        and mine.following_id = p.id
    ) as is_following
  from public.profiles p
  where p.id = p_user_id
$$;

revoke all on function public.get_social_profile(uuid) from public, anon;
grant execute on function public.get_social_profile(uuid) to authenticated;

create function public.get_profile_checkins(
  p_user_id uuid,
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
  where c.user_id = p_user_id
  order by c.created_at desc
  limit least(greatest(p_limit, 1), 50)
  offset greatest(p_offset, 0)
$$;

revoke all on function public.get_profile_checkins(uuid, integer, integer) from public, anon;
grant execute on function public.get_profile_checkins(uuid, integer, integer) to authenticated;
