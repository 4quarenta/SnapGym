-- SnapGym development backend foundation.
-- Applied to the dedicated SnapGym Supabase project only.

alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke usage, select on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public;

create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon, authenticated;
alter default privileges for role postgres in schema private
  revoke execute on functions from public;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  display_name text,
  bio text,
  avatar_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (
    username is null
    or (
      username = lower(username)
      and username ~ '^[a-z0-9][a-z0-9._]{1,22}[a-z0-9]$'
    )
  ),
  constraint profiles_display_name_length check (
    display_name is null
    or char_length(btrim(display_name)) between 1 and 60
  ),
  constraint profiles_bio_length check (
    bio is null
    or char_length(bio) <= 160
  ),
  constraint profiles_avatar_key_length check (
    avatar_key is null
    or char_length(avatar_key) <= 512
  )
);

create unique index profiles_username_lower_unique
  on public.profiles (lower(username))
  where username is not null;

alter table public.profiles enable row level security;

create policy profiles_authenticated_read
  on public.profiles
  for select
  to authenticated
  using (true);

create policy profiles_owner_update
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (username, display_name, bio, avatar_key) on table public.profiles to authenticated;
grant select, insert, update, delete on table public.profiles to service_role;

create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function private.handle_new_user();

create function private.set_profile_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function private.set_profile_updated_at();

revoke all on function private.handle_new_user() from public, anon, authenticated;
revoke all on function private.set_profile_updated_at() from public, anon, authenticated;

comment on table public.profiles is
  'Public-facing SnapGym profile data. Account/auth data remains in Supabase Auth.';
comment on column public.profiles.avatar_key is
  'Cloudflare R2 object key; never an R2 secret or credential.';
