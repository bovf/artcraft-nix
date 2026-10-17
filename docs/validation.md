# Validation evidence and limits

**Current release validation is source/evaluation-only.** The [2026-10-13 release update](releases-2026-10-13.md) advances twelve apps, preserving ArtCraft0.41.0, fonts/toolchains/OCR models and the Linux runtime fix. Existing source contracts and three fixed-output craft-libs source fetches passed; no application/frontend builds or runtime/editorial/hardware acceptance were requested. Do not relabel earlier GUI/build receipts as acceptance of these new pins.

**Preceding release validation was partial.** The [2026-10-11 release update](releases-2026-10-11.md) originally ran no application builds/tests or acceptance gates, at the operator's request. The separately authorized Linux file-dialog follow-up below adds scoped current-release evidence, not full-suite/editorial acceptance. The companion capability JSON and the subsequent initial-acceptance sections remain historical snapshots.

## Linux file-dialog follow-up (2026-10-12)

The shared Linux Rust wrapper now exposes D-Bus's client library and Zenity for
`rfd` 0.17.2. Application sources, release tags, fonts, toolchains, licences and
both producer/consumer locks were preserved; Tauri ArtCraft is untouched.

- PhotoCraft **0.7.0** and FilmCraft **0.6.0** were built from the changed recipe
  with selected Cargo/unit and install checks. The new install check exercises
  each real GUI/CLI wrapper environment; the preceding wrapper fails its
  negative control. One upstream PhotoCraft test remains ignored.
- Both genuinely built apps passed actual native **Open and Save As** through a
  private GTK portal and, separately, the Zenity fallback with no portal
  activation available. A 32×24 synthetic PNG was opened/saved with its dimensions
  verified; a generated Film project retained its non-default display setting
  through Open/Save and reopened successfully with the native CLI. Blank-window
  rendering or `--version` alone was not treated as picker acceptance.
- All **twelve** changed Linux recipes' post-install/wrapper checks passed in
  runtime-only fixtures, reusing byte-identical baseline GUI/CLI ELF binaries
  (24 wrappers). This validates the shared runtime change, **not** fresh Cargo
  builds or all features of the other ten apps.
- All three supported systems evaluated. Darwin package derivations are exactly
  unchanged; all app source/version selections and ArtCraft derivations are
  unchanged on every platform. ARM Linux remains evaluation-only.
- Source contracts, Nix/Python formatting, whitespace and redacted changed-file
  scans passed. The new Python check has clean Ruff/ty LSP diagnostics; nixd
  reports two pre-existing `builtins.`-prefix style warnings, not errors.

The GUI fixture used private filesystem/network/PID namespaces, HOME/XDG,
synthetic passwd/group/machine identity, D-Bus, Xvfb and software Mesa. No live
HOME/session/display sockets, credentials, network, user media or GPU/audio
hardware was exposed. Fixture-only missing-user, event timing, chooser-extension
and Save-As project-renaming assumptions were corrected and failed attempts
retained; no desktop settings or app sources were changed to make tests pass.

No live Niri/Wayland picker or native Wayland drag/drop, hardware, other ten apps'
complete source builds, ArtCraft GUI, full native/editorial compatibility,
publication, consumer adoption or system activation is certified. See
[Linux file-dialog ownership and checks](linux-file-dialogs.md).

## Historical initial acceptance

Initial acceptance: **2026-10-10**, against this repository's locked inputs and package recipes. This is a snapshot, not a claim that moving upstream branches will stay latest. Repeat [the update/validation workflow](../.agents/workflows.md) after pin, compiler, recipe or consumer-nixpkgs changes.

## Platform matrix

| System | Package/app/check evaluation | Native builds and install checks | Isolated GUI rendering |
|---|---|---|---|
| `x86_64-linux` | Pass, including reusable overlay | All thirteen applications; ArtCraft frontend separately | All thirteen |
| `aarch64-linux` | Pass | Not tested on native hardware | Not tested |
| `aarch64-darwin` | Pass | Not tested on native hardware | Not tested |

Current nixpkgs no longer supports `x86_64-darwin`; it is intentionally not an output, rather than advertised as untested support. No signed/notarized macOS `.app` or installer is produced.

## Accepted Linux sources

All rows passed their configured Cargo unit/doc tests and install checks, and displayed a mapped window with non-uniform rendered pixels in an isolated software-rendering fixture. These are default/synthetic-document smoke tests, **not** exhaustive feature tests. Full revisions/hashes remain authoritative in `flake.lock`.

| Package | Upstream version | Revision prefix | Linux build + GUI smoke |
|---|---|---|---|
| `photocraft` | 0.6.0 | `d4ec2db` | Pass |
| `artcraft` | 0.42.0 | `910bfe4` | Pass |
| `lightcraft` | 0.5.0 | `5436951` | Pass |
| `filmcraft` | 0.5.0 | `7bd7621` | Pass |
| `pdfcraft` | 0.5.0 | `68e91d4` | Pass |
| `vectorcraft` | 0.8.0 | `e1599a1` | Pass |
| `effectcraft` | 0.7.0 | `813c7c4` | Pass |
| `designcraft` | 0.5.0 | `0b69d68` | Pass |
| `wordcraft` | 0.4.0 | `a1caf22` | Pass |
| `cadcraft` | 0.4.0 | `43e33ad` | Pass |
| `gridcraft` | 0.4.0 | `13664fe` | Pass |
| `deckcraft` | 0.4.0 | `84acb49` | Pass |
| `soundcraft` | 0.4.0 | `3bc2d92` | Pass |

The twelve Craft packages contain their companion CLIs. Desktop `--version`, CLI executable presence, desktop-file validity, icons and MIME files are checked during their builds. ArtCraft's install check covers its executable/license; its selected Cargo tests passed **109 tests**, with one upstream-ignored test. CadCraft's selected packages contain no unit tests; zero-test output is not described as unit coverage. Selected-package Cargo tests do not constitute every upstream workspace/hardware test.

## Additional verified behavior

- All-platform no-build flake checking passed. All 42 app outputs (thirteen plus default on three systems) have expected program paths. Native `nix flake check` passed against completed free-package/source-contract outputs; non-free ArtCraft was built explicitly.
- Direct packaging and downstream overlay CAD/PDF derivations evaluated successfully with the pinned nixpkgs. The reusable overlay includes its needed Rust overlay. No consumer configuration was activated or modified.
- Source-contract checks passed for all thirteen source/Cargo/assets/license contracts, fonts, ArtCraft's offline SQL metadata and PDF model hashes. Its negative control rejects a floating `main` revision.
- CAD CLI sample export generated a valid **99,570-byte SVG with 498 XML elements** in a temporary fixture.
- PDF's installed model files and CC-BY-SA-4.0 license notices were fetched against upstream SHA-256 values. Without a `PDFCRAFT_MODELS` override, CLI `ocr_status` reports **available: true**, English. This verifies bundling/discovery, not OCR accuracy on real documents.
- ArtCraft's npm dependencies and production frontend were built in the Nix sandbox, then embedded into the release/custom-protocol Tauri backend. Vite size/deprecation warnings are not hidden, nor described as frontend lint/type-test coverage.
- Alejandra, Python syntax, whitespace/diff checks and redacted repository scans passed. LSP diagnostics were unavailable because configured server commands were missing; native Nix/Python validation is not represented as a clean LSP result. Install/fix the configured `nixd`, `ty`/`ruff` commands in the owner's `pi-lsp.json` for LSP coverage.

## GUI fixture boundaries

Tests used Bubblewrap with separate filesystem/network/PID namespaces, only read-only Nix store inputs and an inert harness, private temporary HOME/config/cache/data/runtime directories, a separate Xvfb display and software Mesa rendering. No host HOME, user documents, display socket, D-Bus session, GPU/audio device nodes or network access was exposed. The test queried mapped windows and sampled rendered pixels; namespace teardown terminated the app/display and removed fixture state. CAD additionally opened its built-in sample. ArtCraft used GTK/WebKit software rendering and could not authenticate or contact online providers.

All thirteen windows rendered, including CAD's upstream title `CADCraft`, spreadsheet `Book1` and GTK's main ArtCraft window rather than its hidden leader window. Initial harness title/geometry mismatches were corrected; they were not app failures.

This does **not** verify physical GPUs/Vulkan drivers, Wayland input/scaling, audio/MIDI devices, clipboard/portals/file pickers, all import/export formats, printing, proprietary plugins, WSLg, native macOS integration, authenticated online models/services or account behavior. No real system/session was activated and no user credential/data migration was performed.

## Compiler regression and dependency lessons

Nixpkgs's Rust **1.98.1 with LLVM 21.1.8** fails a tiny compile-only `_mm512_dpbusd_epi32` probe with an intrinsic-signature mismatch, also blocking RTen/PDFCraft. The paired official Rust **1.98.1 with LLVM 22.1.8**, selected solely for PDFCraft through locked `rust-overlay`, compiles the same probe and the actual app successfully. The probe was never executed: it does not require or test an AVX512-capable CPU. No upstream app source, host compiler or GPU configuration was changed.

ArtCraft's verified native fixes retain BoringSSL's bundled Git patches and use the upstream `.sqlx` query cache offline; build-time cache/shebang changes operate inside the sandbox, not on the immutable store. PDF models are immutable build inputs with notices, not a first-use download workaround.

## Repository migration

The recreated canonical repository is `git@gitlab.dobryops.com:nix/artcraft-nix.git`, with initial packaging on `feat/migrate-artcraft-suite`. Migration copied the reviewed source-only tree from the old repository's `741e2b4` without importing its Git metadata or local CI draft. Package recipes, source contracts and `flake.lock` remain byte-identical: this is a repository/documentation move, not an upstream or toolchain update. Migration validation passed all-platform evaluation, native free-package/source-contract checks and an explicit ArtCraft build. All thirteen source revisions, versions, derivation and output paths exactly match the accepted producer outputs, which were reused from the store rather than rebuilt unnecessarily. No fresh hardware/GUI test is asserted: the original native GUI evidence above remains applicable only while those exact package identities are unchanged.

## Publication boundary

The initial migration omitted CI. The operator subsequently authorized a `pi-nix`-style source-only mirror pipeline: `.gitlab-ci.yml` targets GitHub `bovf/artcraft-nix` and Codeberg `bovfbovf/artcraft-nix` on default-branch pushes using the existing `nix-cache` runner. Secret token/optional URL variables are referenced by name, not provisioned or stored in Git. The pipeline now copies the full inline `pi-nix` configuration verbatim except the two ArtCraft repository defaults, retaining complete URL-variable overrides, token fallbacks, skips and force-push behavior. YAML/ShellCheck validation and synthetic mock-Git tests check the reference configuration, variable precedence, destination/refspec selection and failure propagation. The removed custom helper/host restrictions are not part of this setup; no token-free Git-argument guarantee is claimed for the reference's authenticated URL behavior. No real credentials or external pushes are used in local tests.

No live GitLab pipeline execution, mirror parity or external repository creation is asserted. Only source packaging/context is mirrored; no application binaries/cache or downstream deployment is configured. ArtCraft binary redistribution still requires confirmed upstream permission.

## Native editorial interoperability

The unchanged pinned FilmCraft/SoundCraft/EffectCraft outputs are exercised by pi-nix's synthetic editorial gate: genuine native vertical motion/crop and layered placement, native linked retiming, selected stereo Sound cuts with gain/duck automation and save/reopen/bounce, native timed/keyframed text, transparent ProRes4444 RGBA export, Film import/composition/save/reopen/H264+AAC export. Independent output-pixel checks verify caption presence, unoccluded underlying corner and absence outside the effect interval, alongside native composite QC. These tests do not certify every codec/effect, hardware/GUI, long recordings, artistic quality or providers. App versions/toolchains/fonts/licences remain unchanged; no speculative app-source patch was needed.

## Lightweight release refresh — 2026-10-18

See [all13 selected releases, exact new Git hashes and limits](releases-2026-10-18.md).
Only source/hash/contracts/format/evaluation were requested and performed for
these releases. Previous application/GUI receipts are historical, not acceptance
of the new pins. Local consumer rebuild/runtime checking remains operator-owned.
