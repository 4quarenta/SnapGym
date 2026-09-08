create table public.checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  workout_type text not null check (
    workout_type in ('musculacao', 'corrida', 'caminhada', 'ciclismo', 'natacao', 'funcional', 'outro')
  ),
  duration_minutes smallint not null check (duration_minutes between 1 and 720),
  note text check (note is null or char_length(note) <= 280),
  photo_path text not null check (char_length(photo_path) <= 512),
  performed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint checkins_photo_owned_path check (split_part(photo_path, '/', 1) = user_id::text),
  constraint checkins_photo_extension check (lower(photo_path) ~ '\.(jpg|jpeg|png|webp)$')
);

comment on table public.checkins is 'Immutable social workout check-ins. Each check-in requires one evidence photo stored outside Postgres.';
comment on column public.checkins.photo_path is 'Object path in the active media storage provider. No credentials or binary data are stored here.';

create index checkins_created_at_idx on public.checkins (created_at desc);
create index checkins_user_performed_at_idx on public.checkins (user_id, performed_at desc);

alter table public.checkins enable row level security;

revoke all on table public.checkins from anon;
revoke all on table public.checkins from authenticated;
grant select, insert on table public.checkins to authenticated;

create policy "checkins_authenticated_feed_read"
on public.checkins
for select
to authenticated
using (true);

create policy "checkins_owner_insert"
on public.checkins
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and split_part(photo_path, '/', 1) = (select auth.uid())::text
);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'checkin-media',
  'checkin-media',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "checkin_media_authenticated_read"
on storage.objects
for select
to authenticated
using (bucket_id = 'checkin-media');

create policy "checkin_media_owner_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'checkin-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
);

create policy "checkin_media_owner_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'checkin-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
