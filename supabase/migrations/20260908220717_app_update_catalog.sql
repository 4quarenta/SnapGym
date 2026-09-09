create table if not exists public.app_versions (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('android', 'ios')),
  channel text not null check (channel in ('dev', 'staging', 'prod')),
  version_name text not null check (char_length(version_name) between 1 and 32),
  build_number integer not null check (build_number > 0),
  download_url text,
  action_url text,
  sha256 text check (sha256 is null or sha256 ~ '^[a-f0-9]{64}$'),
  release_notes text check (release_notes is null or char_length(release_notes) <= 4000),
  is_mandatory boolean not null default false,
  is_active boolean not null default true,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (platform, channel, build_number),
  check (
    (platform = 'android' and download_url is not null)
    or (platform = 'ios' and action_url is not null)
  )
);

comment on table public.app_versions is
  'Public update metadata consumed by SnapGym clients. Binary artifacts live outside Postgres.';

create index if not exists app_versions_lookup_idx
  on public.app_versions (platform, channel, is_active, build_number desc);

alter table public.app_versions enable row level security;

revoke all on table public.app_versions from anon, authenticated;
grant select on table public.app_versions to anon, authenticated;

drop policy if exists app_versions_public_read on public.app_versions;
create policy app_versions_public_read
  on public.app_versions
  for select
  to anon, authenticated
  using (is_active = true);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'app-updates',
  'app-updates',
  true,
  262144000,
  array[
    'application/vnd.android.package-archive',
    'application/octet-stream'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- No client write policies are created for app-updates.
-- Publishing remains an administrative operation.
