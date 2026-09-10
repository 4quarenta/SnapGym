begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(10);

-- Synthetic users for an isolated transactional test.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('10000000-0000-4000-8000-000000000001', 'phase6-a@test.invalid', '{"provider":"email","providers":["email"]}', '{}'),
  ('10000000-0000-4000-8000-000000000002', 'phase6-b@test.invalid', '{"provider":"email","providers":["email"]}', '{}'),
  ('10000000-0000-4000-8000-000000000003', 'phase6-c@test.invalid', '{"provider":"email","providers":["email"]}', '{}');

update public.profiles set username = 'phase6_a', display_name = 'Phase 6 A'
where id = '10000000-0000-4000-8000-000000000001';
update public.profiles set username = 'phase6_b', display_name = 'Phase 6 B'
where id = '10000000-0000-4000-8000-000000000002';
update public.profiles set username = 'phase6_c', display_name = 'Phase 6 C'
where id = '10000000-0000-4000-8000-000000000003';

insert into public.checkins (
  id, user_id, workout_type, duration_minutes, photo_path, performed_at
) values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002',
  'corrida',
  30,
  '10000000-0000-4000-8000-000000000002/qa/test.jpg',
  now()
);

insert into public.challenges (
  id, creator_id, title, description, starts_on, ends_on, target_days
) values (
  '30000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002',
  'Desafio QA',
  'Fixture transacional da Fase 6.',
  current_date,
  current_date + 6,
  4
);

insert into public.social_follows (follower_id, following_id)
values (
  '10000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000002'
);

insert into public.checkin_likes (checkin_id, user_id)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001'
);

insert into public.checkin_comments (id, checkin_id, user_id, body)
values (
  '40000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'Mandou bem no teste!'
);

insert into public.challenge_participants (challenge_id, user_id)
values (
  '30000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001'
);

select is(
  (select count(*) from public.activity_notifications where user_id = '10000000-0000-4000-8000-000000000002'),
  4::bigint,
  'follow, like, comment and challenge join create four notifications'
);

set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000002';

select is(
  public.get_unread_activity_count(),
  4::bigint,
  'recipient sees four unread notifications'
);

select is(
  (select count(*) from public.get_activity_notifications()),
  4::bigint,
  'recipient RPC returns only its activity inbox'
);

select ok(
  public.mark_activity_notification_read(
    (select id from public.activity_notifications order by created_at limit 1)
  ),
  'recipient can mark one notification as read'
);

select is(
  public.get_unread_activity_count(),
  3::bigint,
  'single read decrements unread counter'
);

select is(
  public.mark_all_activity_notifications_read(),
  3,
  'mark all returns the number of remaining unread notifications'
);

select is(
  public.get_unread_activity_count(),
  0::bigint,
  'recipient has no unread notifications after mark all'
);

set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000003';

select is(
  public.get_unread_activity_count(),
  0::bigint,
  'another user cannot see recipient unread count'
);

select is(
  (select count(*) from public.activity_notifications),
  0::bigint,
  'RLS hides another users notification rows'
);

reset role;

delete from public.checkin_likes
where checkin_id = '20000000-0000-4000-8000-000000000001'
  and user_id = '10000000-0000-4000-8000-000000000001';

select is(
  (select count(*) from public.activity_notifications where dedupe_key = 'like:20000000-0000-4000-8000-000000000001:10000000-0000-4000-8000-000000000001'),
  0::bigint,
  'removing a like also removes its activity notification'
);

select * from finish();
rollback;
