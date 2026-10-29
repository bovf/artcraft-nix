# Agent context: artcraft-nix

Read this file first, then [workflows.md](workflows.md). User-facing usage is in [README.md](../README.md); verified coverage/limits are in [docs/validation.md](../docs/validation.md).

## Purpose and repository boundary

This is an independent, reusable source-distribution flake for thirteen Storytold applications, hosted at `git@gitlab.dobryops.com:nix/artcraft-nix.git`. It does not configure a machine or depend on `pl-badwater`. Downstream system integration, cache publication and deployment are separate work requiring approval. Source-only default-branch GitHub/Codeberg mirrors are now authorized through the GitLab CI job modeled on `pi-nix`. Do not modify sibling repositories as part of a package update.

**CI is source-mirroring only.** The operator superseded the migration's CI exclusion: `.gitlab-ci.yml` now selects the protected default-branch push workflow on the `nix-cache` runner. Its complete inline script is copied from `pi-nix`, with only the two repository defaults changed to ArtCraft. `GITHUB_MIRROR_URL`/`CODEBERG_MIRROR_URL` take precedence; token variables construct fallback URLs exactly as in the reference. Destinations are not restricted by additional host checks. The job force-updates only the selected default branch. No package builds, binary/cache uploads, tags, feature-branch mirrors or deployment are authorized by this job. Do not create a second `.gitlab-ci.yaml` or expose secret variable values; see [CI setup](../README.md#gitlab-ci-source-mirrors).

## Source authority and layout

- `flake.nix`: immutable input wiring, three supported output systems, package/app/default outputs, checks, overlay, formatter and development shell.
- `flake.lock`: authoritative resolved upstream/toolchain/font revisions and content hashes. Applications now select explicit latest published release tags, resolved once at update time. Update each tag URL before resolving a new release. Do not silently replace releases with development snapshots.
- `packages/default.nix`: all thirteen names; narrowly overrides PDFCraft's compiler with paired official Rust 1.98.1 through locked `rust-overlay`. Updated nixpkgs Rust1.99.0/LLVM21 still rejects the AVX512 probe; official Rust1.98.1/LLVM22 passes it. FilmCraft0.14.0 fixes MIME consistency upstream, retiring the obsolete0.8 patch with6/6 isolated helper tests. Do not globally replace downstream Rust or patch app code around a compiler regression.
- `packages/craft.nix`: twelve Rust/egui workspaces, desktop and `${name}-cli`, locked Cargo dependencies, shared embedded fonts, native inputs/runtime wrappers, desktop/icons/MIME/notices, build/unit/install checks.
- `packages/artcraft.nix`: separately licensed Tauri/React application; fixed-output npm frontend, Rust backend/custom protocol, GTK/WebKit integration, offline SQL query metadata, BoringSSL's native Git/CMake/Perl/bindgen requirements.
- `packages/pdf-models.nix`: PDF OCR's exact official ONNX model pair and license downloads from pinned upstream `ATTRIBUTION.toml`, verified by its SHA-256 values. PDF0.15's loader/manifest explicitly support ONNX; legacy RTEN URLs were retired upstream. No runtime model installer, local conversion or unchecked download.
- `tests/source-contract.py`: pinned input owners/revisions, required source/lock/assets/licenses, all font manifest hashes/OFL notices, exact Cargo Git source/key contracts, FilmCraft MIME consistency, SQL metadata, upstream ONNX model agreement and a floating-revision negative control.

Packages: `photocraft`, `artcraft`, `lightcraft`, `filmcraft`, `pdfcraft`, `vectorcraft`, `effectcraft`, `designcraft`, `wordcraft`, `cadcraft`, `gridcraft`, `deckcraft`, `soundcraft`. Default package/app: `photocraft`. Every Craft package except Tauri `artcraft` contains a companion CLI.

## Licensing and runtime boundaries

Twelve Craft codebases declare MIT/Apache-2.0; fonts have OFL notices and brand assets have separate restrictions. PDF OCR data is CC-BY-SA-4.0. Preserve all relevant notices. **ArtCraft is non-free, source-available, and not covered by a general binary-redistribution grant.** Its frontend is also marked non-free; direct outputs allow only `artcraft`/`artcraft-frontend`, while overlay consumers own their license policy. It is excluded from automatic free-package checks. Do not publish its binaries/cache/artifacts without permission.

Linux wrappers supply graphics/window-system loaders, the D-Bus client library and Zenity file-dialog fallback, not host GPU drivers. The install-time [dialog runtime check](../tests/dialog-runtime.py) exercises both wrapper environments without starting an app; real isolated Open/Save checks are separate ([scope](../docs/linux-file-dialogs.md)). Audio hardware, portals, display servers, proprietary plugins and external services remain host/upstream concerns. Do not alter GPU drivers, activate a consumer system, expose a live desktop or read user documents/credentials merely to test packaging. Use private synthetic fixtures and explicit permission for real hardware/services.

## Validation and maintenance policy

Keep app versions derived from pinned upstream manifests; do not maintain a second version table in recipes. Never leave fake hashes, floating fetches or unsupported-platform claims in delivered code. Cargo git sources need explicit verified output hashes; unknown sources must fail closed. Keep ArtCraft's SQLX build offline and retain BoringSSL patches, rather than bypassing them to make a build pass.

Supported outputs are `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`; current nixpkgs rejects Intel macOS. Historical Linux native builds/isolated GUI rendering apply only to their recorded old source/derivation identities, not the current releases. ARM Linux/macOS evaluation is **not** a native build/runtime guarantee. Following/overlaying consumer nixpkgs changes effective dependencies and requires rebuilding.

If Graphify output exists, query it before broad searches; do not install an imperative duplicate. Make the smallest source-level change, update these pages and the README, validate current tracked bytes, scan redacted diffs/history and report evidence separately from limitations. Do not decrypt secrets or put credentials into Git, command arguments, store paths, logs or update artifacts.

The [2026-10-29 entire-flake selection](../docs/releases-2026-10-29.md) advances twelve native apps plus fonts/nixpkgs/rust-overlay and retains latest ArtCraft0.41.0. Only source/evaluation/contracts/hash checks and pure helper-level compile tests were requested; no application/frontend/GUI acceptance is claimed. Five changed Cargo Git trees were source-fetch verified; unknown strings still fail closed. All65 font manifest faces are hashed; PDF models follow the source-proven ONNX migration. Consumer edits/publication belong exclusively to the parent; retain ArtCraft exclusion and restrictive cache policy.

**The primary maintenance workflow is updating ALL thirteen applications together:** see [workflows.md#update-all-applications](workflows.md#update-all-applications). The [2026-10-11 release selection](../docs/releases-2026-10-11.md) was requested without tests/builds; its results are unverified. The operator explicitly approved ArtCraft's 0.42.0 development snapshot being replaced by published 0.41.0. Historical validation/capability snapshots must not be attributed to these pins. The separately authorized [Linux file-dialog follow-up](../docs/validation.md#linux-file-dialog-follow-up-2026-10-12) supplies scoped historical runtime/representative GUI evidence for its recorded old pins, not current-release or full-suite acceptance.
