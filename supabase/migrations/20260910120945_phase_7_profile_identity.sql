insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-media',
  'profile-media',
  true,
  1048576,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists profile_media_authenticated_read on storage.objects;
create policy profile_media_authenticated_read
on storage.objects for select to authenticated
using (bucket_id = 'profile-media');

drop policy if exists profile_media_owner_insert on storage.objects;
create policy profile_media_owner_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

drop policy if exists profile_media_owner_update on storage.objects;
create policy profile_media_owner_update
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

drop policy if exists profile_media_owner_delete on storage.objects;
create policy profile_media_owner_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

comment on column public.profiles.avatar_key is
  'Object path for the user profile image. Storage provider can change without changing the public profile contract.';

drop function if exists public.search_social_profiles(text, integer);
create function public.search_social_profiles(
  p_query text default '', p_limit integer default 30
)
returns table (
  id uuid, username text, display_name text, bio text, avatar_key text,
  follower_count bigint, following_count bigint, checkin_count bigint, is_following boolean
)
language sql stable security invoker set search_path = ''
as $$
  select p.id,p.username,p.display_name,p.bio,p.avatar_key,
    (select count(*) from public.social_follows f where f.following_id=p.id),
    (select count(*) from public.social_follows f where f.follower_id=p.id),
    (select count(*) from public.checkins c where c.user_id=p.id),
    exists(select 1 from public.social_follows mine where mine.follower_id=(select auth.uid()) and mine.following_id=p.id)
  from public.profiles p
  where p.id <> (select auth.uid())
    and (coalesce(btrim(p_query),'')='' or coalesce(p.username,'') ilike '%'||btrim(p_query)||'%' or coalesce(p.display_name,'') ilike '%'||btrim(p_query)||'%')
  order by case when lower(coalesce(p.username,''))=lower(btrim(p_query)) then 0 else 1 end,
    (select count(*) from public.social_follows f where f.following_id=p.id) desc,
    p.created_at desc
  limit least(greatest(p_limit,1),50)
$$;
revoke all on function public.search_social_profiles(text, integer) from public, anon;
grant execute on function public.search_social_profiles(text, integer) to authenticated;

drop function if exists public.get_social_profile(uuid);
create function public.get_social_profile(p_user_id uuid)
returns table (
  id uuid, username text, display_name text, bio text, avatar_key text,
  follower_count bigint, following_count bigint, checkin_count bigint, is_following boolean
)
language sql stable security invoker set search_path = ''
as $$
  select p.id,p.username,p.display_name,p.bio,p.avatar_key,
    (select count(*) from public.social_follows f where f.following_id=p.id),
    (select count(*) from public.social_follows f where f.follower_id=p.id),
    (select count(*) from public.checkins c where c.user_id=p.id),
    exists(select 1 from public.social_follows mine where mine.follower_id=(select auth.uid()) and mine.following_id=p.id)
  from public.profiles p where p.id=p_user_id
$$;
revoke all on function public.get_social_profile(uuid) from public, anon;
grant execute on function public.get_social_profile(uuid) to authenticated;

drop function if exists public.get_social_feed(integer, integer);
create function public.get_social_feed(p_limit integer default 30, p_offset integer default 0)
returns table (
  id uuid,user_id uuid,workout_type text,duration_minutes smallint,note text,photo_path text,
  performed_at timestamptz,created_at timestamptz,username text,display_name text,avatar_key text,
  like_count bigint,comment_count bigint,liked_by_me boolean
)
language sql stable security invoker set search_path = ''
as $$
  select c.id,c.user_id,c.workout_type,c.duration_minutes,c.note,c.photo_path,c.performed_at,c.created_at,
    p.username,p.display_name,p.avatar_key,
    (select count(*) from public.checkin_likes l where l.checkin_id=c.id),
    (select count(*) from public.checkin_comments cm where cm.checkin_id=c.id),
    exists(select 1 from public.checkin_likes mine where mine.checkin_id=c.id and mine.user_id=(select auth.uid()))
  from public.checkins c join public.profiles p on p.id=c.user_id
  where c.user_id=(select auth.uid())
     or exists(select 1 from public.social_follows f where f.follower_id=(select auth.uid()) and f.following_id=c.user_id)
  order by c.created_at desc
  limit least(greatest(p_limit,1),50) offset greatest(p_offset,0)
$$;
revoke all on function public.get_social_feed(integer, integer) from public, anon;
grant execute on function public.get_social_feed(integer, integer) to authenticated;

drop function if exists public.get_profile_checkins(uuid, integer, integer);
create function public.get_profile_checkins(p_user_id uuid,p_limit integer default 30,p_offset integer default 0)
returns table (
  id uuid,user_id uuid,workout_type text,duration_minutes smallint,note text,photo_path text,
  performed_at timestamptz,created_at timestamptz,username text,display_name text,avatar_key text,
  like_count bigint,comment_count bigint,liked_by_me boolean
)
language sql stable security invoker set search_path = ''
as $$
  select c.id,c.user_id,c.workout_type,c.duration_minutes,c.note,c.photo_path,c.performed_at,c.created_at,
    p.username,p.display_name,p.avatar_key,
    (select count(*) from public.checkin_likes l where l.checkin_id=c.id),
    (select count(*) from public.checkin_comments cm where cm.checkin_id=c.id),
    exists(select 1 from public.checkin_likes mine where mine.checkin_id=c.id and mine.user_id=(select auth.uid()))
  from public.checkins c join public.profiles p on p.id=c.user_id
  where c.user_id=p_user_id
  order by c.created_at desc
  limit least(greatest(p_limit,1),50) offset greatest(p_offset,0)
$$;
revoke all on function public.get_profile_checkins(uuid, integer, integer) from public, anon;
grant execute on function public.get_profile_checkins(uuid, integer, integer) to authenticated;

drop function if exists public.get_activity_notifications(integer, integer);
create function public.get_activity_notifications(p_limit integer default 30,p_offset integer default 0)
returns table(
  notification_id uuid,kind text,actor_id uuid,actor_username text,actor_display_name text,actor_avatar_key text,
  checkin_id uuid,workout_type text,comment_body text,challenge_id uuid,challenge_title text,read_at timestamptz,created_at timestamptz
)
language sql stable security invoker set search_path = ''
as $$
  select n.id,n.kind,n.actor_id,p.username,p.display_name,p.avatar_key,n.checkin_id,c.workout_type,cm.body,
    n.challenge_id,ch.title,n.read_at,n.created_at
  from public.activity_notifications n
  join public.profiles p on p.id=n.actor_id
  left join public.checkins c on c.id=n.checkin_id
  left join public.checkin_comments cm on cm.id=n.comment_id
  left join public.challenges ch on ch.id=n.challenge_id
  where n.user_id=(select auth.uid())
  order by n.created_at desc
  limit greatest(1,least(coalesce(p_limit,30),100)) offset greatest(coalesce(p_offset,0),0)
$$;
revoke all on function public.get_activity_notifications(integer, integer) from public, anon;
grant execute on function public.get_activity_notifications(integer, integer) to authenticated;
