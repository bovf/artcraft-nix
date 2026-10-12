# Linux file dialogs

The twelve Rust/egui applications use the shared `packages/craft.nix` recipe.
Their selected releases use `rfd` 0.17.2 with its default XDG portal backend.
Unlike the older Rust D-Bus client, this version dynamically opens
`libdbus-1.so`; a running portal alone is insufficient if the app cannot load
that client library. When portal access fails, `rfd` tries the `zenity` command.
Missing both dependencies can look like Open/Save doing nothing.

The Linux wrappers now supply the pinned D-Bus **client library** through
`LD_LIBRARY_PATH` and Zenity through `PATH`, preserving their existing graphics,
X11/Wayland, URL-opening and multimedia dependencies. No input/tag/toolchain
update, global environment change, daemon installation or portal routing change
is required. Darwin wrappers are unchanged. Tauri-based ArtCraft uses a separate
recipe and is not covered by this change.

## Checks and scope

Each Linux package's install check runs `tests/dialog-runtime.py` against both
its GUI and CLI wrapper. The test intercepts the shell wrapper's final `exec`,
loads `libdbus-1.so` and resolves Zenity using the wrapper's actual environment.
It uses a private temporary HOME, no ambient library/search paths, and never
starts the app or touches a desktop session. This guards runtime packaging, not
file-dialog UI behavior.

Representative GUI checks must run with synthetic files in a private
filesystem/network/PID namespace, private HOME/XDG/D-Bus, an independent Xvfb
display and software rendering. Exercise real Open and Save menus, confirm a
mapped chooser and verify the selected/generated file. Check both a private
GTK portal and the Zenity fallback; a mapped app window or successful
`--version` alone is not a picker test. Do not expose the live desktop, session
bus, credentials, GPU/audio devices or user documents.

Scoped results for this fix belong in `docs/validation.md`; the older full-suite
acceptance and the originally untested release update remain historical.

## PhotoCraft's separate Wayland notice

PhotoCraft documents native file drag-and-drop as unsupported with its current
winit 0.30 Wayland backend. Fixing file-dialog dependencies does not implement
Wayland drag-and-drop. Use File > Open or copy/paste, or select Preferences >
Performance > Linux display server > X11 and restart PhotoCraft to use XWayland.
This is a per-app preference, not a reason to disable Wayland globally or replace
user settings declaratively.
