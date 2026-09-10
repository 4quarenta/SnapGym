# Phase 6 — Activity Center

## Scope

- In-app activity inbox for follows, likes, comments and challenge joins.
- Unread badge surfaced from the feed.
- Read-one and read-all flows.
- Actor/profile context and event-specific navigation.
- Server-generated notifications; clients cannot insert or delete notification rows.

## Security model

- `activity_notifications` has RLS enabled.
- Authenticated users can only select/update their own recipient rows.
- Direct client updates are restricted to `read_at`.
- Trigger helpers live in `private`, use a pinned empty `search_path`, and are not directly executable by `anon` or `authenticated`.
- Client RPCs use `SECURITY INVOKER` and explicit execute grants.

## Delivery

This phase establishes the in-app source of truth. FCM/APNs delivery is intentionally deferred until the activity model and UX are validated.
