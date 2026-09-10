create or replace function public.get_weekly_ranking(p_scope text default 'following', p_limit integer default 50)
returns table(user_id uuid, username text, display_name text, avatar_key text, active_days bigint, checkins bigint, total_minutes bigint, rank bigint)
language sql stable security invoker set search_path = ''
as $$
  with bounds as (
    select date_trunc('week', now() at time zone 'America/Fortaleza') as week_start
  ), eligible as (
    select p.id, p.username, p.display_name, p.avatar_key
    from public.profiles p
    where p_scope = 'global'
       or p.id = (select auth.uid())
       or (p_scope = 'following' and exists (
         select 1 from public.social_follows f
         where f.follower_id = (select auth.uid()) and f.following_id = p.id
       ))
  ), totals as (
    select e.id, e.username, e.display_name, e.avatar_key,
      count(distinct (c.performed_at at time zone 'America/Fortaleza')::date) as active_days,
      count(c.id) as checkins,
      coalesce(sum(c.duration_minutes),0)::bigint as total_minutes
    from eligible e
    left join public.checkins c on c.user_id=e.id
      and (c.performed_at at time zone 'America/Fortaleza') >= (select week_start from bounds)
      and (c.performed_at at time zone 'America/Fortaleza') < (select week_start + interval '7 days' from bounds)
    group by e.id,e.username,e.display_name,e.avatar_key
  )
  select t.id,t.username,t.display_name,t.avatar_key,t.active_days,t.checkins,t.total_minutes,
    dense_rank() over(order by t.active_days desc,t.checkins desc,t.total_minutes desc) as rank
  from totals t
  where t.active_days > 0
  order by rank,t.username
  limit greatest(1,least(coalesce(p_limit,50),100));
$$;

create or replace function public.get_my_streak()
returns table(current_streak integer, best_streak integer, trained_today boolean)
language sql stable security invoker set search_path = ''
as $$
  with days as (
    select distinct (c.performed_at at time zone 'America/Fortaleza')::date d
    from public.checkins c where c.user_id=(select auth.uid())
  ), ordered as (
    select d, d - (row_number() over(order by d))::int as grp from days
  ), streaks as (
    select min(d) first_day,max(d) last_day,count(*)::int len from ordered group by grp
  ), today as (select (now() at time zone 'America/Fortaleza')::date d)
  select
    coalesce((select len from streaks,today where last_day in (today.d,today.d-1) order by last_day desc limit 1),0),
    coalesce((select max(len) from streaks),0),
    exists(select 1 from days,today where days.d=today.d);
$$;

revoke all on function public.get_weekly_ranking(text,integer) from public, anon;
grant execute on function public.get_weekly_ranking(text,integer) to authenticated;
revoke all on function public.get_my_streak() from public, anon;
grant execute on function public.get_my_streak() to authenticated;

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 60),
  description text not null default '' check (char_length(description) <= 280),
  starts_on date not null,
  ends_on date not null,
  target_days smallint not null check (target_days between 1 and 31),
  created_at timestamptz not null default now(),
  constraint challenges_valid_dates check (ends_on >= starts_on and ends_on - starts_on <= 90),
  constraint challenges_target_within_window check (target_days <= (ends_on - starts_on + 1))
);

create table if not exists public.challenge_participants (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;
revoke all on table public.challenges from public, anon;
revoke all on table public.challenge_participants from public, anon;
grant select, insert on table public.challenges to authenticated;
grant select, insert, delete on table public.challenge_participants to authenticated;

drop policy if exists challenges_select_authenticated on public.challenges;
create policy challenges_select_authenticated on public.challenges for select to authenticated using (true);
drop policy if exists challenges_insert_own on public.challenges;
create policy challenges_insert_own on public.challenges for insert to authenticated with check ((select auth.uid()) = creator_id);
drop policy if exists challenge_participants_select_authenticated on public.challenge_participants;
create policy challenge_participants_select_authenticated on public.challenge_participants for select to authenticated using (true);
drop policy if exists challenge_participants_insert_own on public.challenge_participants;
create policy challenge_participants_insert_own on public.challenge_participants for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists challenge_participants_delete_own on public.challenge_participants;
create policy challenge_participants_delete_own on public.challenge_participants for delete to authenticated using ((select auth.uid()) = user_id);

create index if not exists challenges_dates_idx on public.challenges(starts_on, ends_on);
create index if not exists challenges_creator_idx on public.challenges(creator_id);
create index if not exists challenge_participants_user_idx on public.challenge_participants(user_id, challenge_id);

create or replace function public.get_active_challenges(p_limit integer default 30)
returns table(challenge_id uuid,title text,description text,starts_on date,ends_on date,target_days integer,creator_id uuid,creator_username text,participant_count bigint,joined boolean,progress_days bigint)
language sql stable security invoker set search_path = ''
as $$
  select ch.id,ch.title,ch.description,ch.starts_on,ch.ends_on,ch.target_days::integer,ch.creator_id,p.username,
    count(distinct cp.user_id),
    bool_or(cp.user_id = (select auth.uid())),
    count(distinct case
      when cp.user_id = (select auth.uid()) and c.performed_at is not null
       and (c.performed_at at time zone 'America/Fortaleza')::date between greatest(ch.starts_on,(cp.joined_at at time zone 'America/Fortaleza')::date) and ch.ends_on
      then (c.performed_at at time zone 'America/Fortaleza')::date end)
  from public.challenges ch
  join public.profiles p on p.id=ch.creator_id
  left join public.challenge_participants cp on cp.challenge_id=ch.id
  left join public.checkins c on c.user_id=cp.user_id and cp.user_id=(select auth.uid())
  where ch.ends_on >= (now() at time zone 'America/Fortaleza')::date
  group by ch.id,ch.title,ch.description,ch.starts_on,ch.ends_on,ch.target_days,ch.creator_id,p.username
  order by ch.starts_on asc,ch.created_at desc
  limit greatest(1,least(coalesce(p_limit,30),100));
$$;

create or replace function public.get_challenge_ranking(p_challenge_id uuid,p_limit integer default 50)
returns table(user_id uuid,username text,display_name text,active_days bigint,checkins bigint,rank bigint)
language sql stable security invoker set search_path = ''
as $$
  with totals as (
    select cp.user_id,p.username,p.display_name,
      count(distinct (c.performed_at at time zone 'America/Fortaleza')::date) active_days,
      count(c.id) checkins
    from public.challenge_participants cp
    join public.challenges ch on ch.id=cp.challenge_id
    join public.profiles p on p.id=cp.user_id
    left join public.checkins c on c.user_id=cp.user_id
      and (c.performed_at at time zone 'America/Fortaleza')::date between greatest(ch.starts_on,(cp.joined_at at time zone 'America/Fortaleza')::date) and ch.ends_on
    where cp.challenge_id=p_challenge_id
    group by cp.user_id,p.username,p.display_name
  )
  select t.user_id,t.username,t.display_name,t.active_days,t.checkins,
    dense_rank() over(order by t.active_days desc,t.checkins desc,t.username)
  from totals t order by 6,t.username
  limit greatest(1,least(coalesce(p_limit,50),100));
$$;

create or replace function public.create_challenge(p_title text,p_description text,p_starts_on date,p_ends_on date,p_target_days integer)
returns uuid
language plpgsql volatile security invoker set search_path = ''
as $$
declare v_id uuid;
begin
  insert into public.challenges(creator_id,title,description,starts_on,ends_on,target_days)
  values ((select auth.uid()),trim(p_title),coalesce(trim(p_description),''),p_starts_on,p_ends_on,p_target_days)
  returning id into v_id;
  insert into public.challenge_participants(challenge_id,user_id) values (v_id,(select auth.uid()));
  return v_id;
end;
$$;

revoke all on function public.get_active_challenges(integer) from public, anon;
grant execute on function public.get_active_challenges(integer) to authenticated;
revoke all on function public.get_challenge_ranking(uuid,integer) from public, anon;
grant execute on function public.get_challenge_ranking(uuid,integer) to authenticated;
revoke all on function public.create_challenge(text,text,date,date,integer) from public, anon;
grant execute on function public.create_challenge(text,text,date,date,integer) to authenticated;
