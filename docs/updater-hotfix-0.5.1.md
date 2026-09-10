# Updater hotfix 0.5.1

## Root cause

`UpdateGate` was mounted through `MaterialApp.router.builder`, which places it above the Router/Navigator. The v0.4.0 implementation called `showDialog` using the `UpdateGate` build context. That context had no Navigator ancestor, so the dialog presentation failed. The updater intentionally swallowed startup exceptions, making the failure silent.

## Fix

- add a stable root `GlobalKey<NavigatorState>` to `GoRouter`;
- pass the root navigator key to `UpdateGate`;
- present the update dialog using the navigator context;
- log updater failures in debug builds;
- add a widget regression test that mounts `UpdateGate` above the Navigator and verifies that the update dialog is still shown.

## Bootstrap note

Devices still on v0.4.0+5 cannot receive this fix through the broken dialog path. One manual APK installation of v0.5.1+7 is required. The following release will be used for the next physical A→B updater validation.
