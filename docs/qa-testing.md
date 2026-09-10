# SnapGym QA testing

## Remote dev fixtures

The SnapGym development project contains six synthetic QA actors used to exercise social and activity flows on a real device:

- `qa_ana`
- `qa_bruno`
- `qa_carla`
- `qa_diego`
- `qa_elaine`
- `qa_felipe`

These are **data fixtures, not login accounts**. They are marked in `auth.users.raw_app_meta_data` with `snapgym_test_user: true`, so they can be identified and removed without touching real accounts.

The current fixture set generates representative data for:

- six follows against the primary development account;
- six likes on a real test check-in;
- three comments on a real test check-in;
- joins on a real test challenge;
- all four Phase 6 activity-notification kinds;
- three QA-created active challenges with different windows, targets and participant counts;
- six searchable QA profiles for Explore/follow-unfollow tests.

Remote verification from the primary development account currently confirms six QA profiles discoverable through `search_social_profiles`, three QA challenges visible through `get_active_challenges`, and a populated activity inbox containing all four event kinds.

Do not add real personal data to these users.

### Cleanup

Run only against the development project:

```sql
delete from auth.users
where coalesce((raw_app_meta_data->>'snapgym_test_user')::boolean, false);
```

Foreign-key cascades remove their profiles, follows, likes, comments, QA-created challenges, challenge participation and activity entries.

## Automated coverage

Flutter tests cover activity parsing, inbox rendering and the feed unread badge, including both unread and zero-unread states.

Database tests live under `supabase/tests/database` and run with pgTAP in a local Supabase stack. The Phase 6 suite validates:

- follow notification creation;
- like notification creation and removal;
- comment notification creation;
- challenge-join notification creation;
- unread counts;
- mark-one / mark-all read behavior;
- RLS isolation between recipients.

The database workflow uses only synthetic transactional users and rolls test data back. The CI workflow starts a clean local Supabase stack, replays migrations and runs `supabase test db`, so database regressions are checked independently of the hosted development data.
