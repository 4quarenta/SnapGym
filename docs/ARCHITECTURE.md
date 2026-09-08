# SnapGym Architecture v0.1

## Product nucleus

SnapGym is a social fitness app built around:

`train -> check in -> prove with photo -> score -> social visibility -> ranking`

The architecture must preserve this sequence without making the client authoritative over points, ranking, or anti-fraud rules.

## Client architecture

Feature-first organization with a thin shared core.

Feature code owns its presentation/application/data logic when the feature is introduced. Shared code belongs in `core` only when it is genuinely cross-feature.

Avoid generic "utils" dumping grounds and premature Clean Architecture layers.

## Backend boundary

Supabase will provide PostgreSQL, Auth, Realtime and server-side capabilities.

The mobile client must never be authoritative for:

- awarded points
- streak calculation
- ranking position
- anti-fraud decisions
- privileged moderation
- access to other users' private rows

These rules belong in PostgreSQL policies/functions and server-side functions.

## Media boundary

Cloudflare R2 will store check-in media.

The Flutter application will not contain R2 credentials. Upload authorization will be issued server-side.

## Environments

- `dev`: local development / disposable data
- `staging`: online homologation
- `prod`: real users

Separate backend projects/buckets/push configuration must be used for staging and production.

## UI

Material 3 is the implementation base, wrapped by SnapGym design primitives/components.

Brand palette:

- Orange: `#F06021`
- Jet: `#202123`
- Moonstone: `#6B9CAA`

Visual direction: social fitness + athletic performance.
