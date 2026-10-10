# Agent context: artcraft-nix

Read this file first, then [workflows.md](workflows.md). User-facing usage is in [README.md](../README.md); verified coverage/limits are in [docs/validation.md](../docs/validation.md).

## Purpose and repository boundary

This is an independent, reusable source-distribution flake for thirteen Storytold applications, hosted at `git@gitlab.dobryops.com:nix/artcraft-nix.git`. It does not configure a machine or depend on `pl-badwater`. Downstream system integration, cache publication and deployment are separate work requiring approval. Source-only default-branch GitHub/Codeberg mirrors are now authorized through the GitLab CI job modeled on `pi-nix`. Do not modify sibling repositories as part of a package update.

**CI is source-mirroring only.** The operator superseded the migration's CI exclusion: `.gitlab-ci.yml` now selects the protected default-branch push workflow on the `nix-cache` runner. `ci/mirror.sh` references `GITHUB_TOKEN`/`CODEBERG_TOKEN` and optional URL overrides, supplies tokens through a temporary askpass helper rather than Git arguments, and force-updates only the selected default branch. No package builds, binary/cache uploads, tags, feature-branch mirrors or deployment are authorized by this job. Do not create a second `.gitlab-ci.yaml` or expose secret variable values; see [CI setup](../README.md#gitlab-ci-source-mirrors).

## Source authority and layout

- `flake.nix`: immutable input wiring, three supported output systems, package/app/default outputs, checks, overlay, formatter and development shell.
- `flake.lock`: authoritative resolved upstream/toolchain/font revisions and content hashes. Applications follow their default upstream branches, not necessarily release tags; “latest” means the latest available branch snapshot at update time.
- `packages/default.nix`: all thirteen names; narrowly overrides PDFCraft's compiler with paired official Rust 1.98.1 through locked `rust-overlay`. Nixpkgs's same-version LLVM 21 compiler rejects an AVX512 intrinsic; official LLVM 22 passes it. Do not globally replace downstream Rust or patch app code around a compiler regression.
- `packages/craft.nix`: twelve Rust/egui workspaces, desktop and `${name}-cli`, locked Cargo dependencies, shared embedded fonts, native inputs/runtime wrappers, desktop/icons/MIME/notices, build/unit/install checks.
- `packages/artcraft.nix`: separately licensed Tauri/React application; fixed-output npm frontend, Rust backend/custom protocol, GTK/WebKit integration, offline SQL query metadata, BoringSSL's native Git/CMake/Perl/bindgen requirements.
- `packages/pdf-models.nix`: PDF OCR model and license downloads from pinned upstream `ATTRIBUTION.toml`, verified by its SHA-256 values. No runtime model installer or unchecked download.
- `tests/source-contract.py`: pinned input owners/revisions, required source/lock/assets/licenses, fonts, SQL metadata, OCR hash contracts and a floating-revision negative control.

Packages: `photocraft`, `artcraft`, `lightcraft`, `filmcraft`, `pdfcraft`, `vectorcraft`, `effectcraft`, `designcraft`, `wordcraft`, `cadcraft`, `gridcraft`, `deckcraft`, `soundcraft`. Default package/app: `photocraft`. Every Craft package except Tauri `artcraft` contains a companion CLI.

## Licensing and runtime boundaries

Twelve Craft codebases declare MIT/Apache-2.0; fonts have OFL notices and brand assets have separate restrictions. PDF OCR data is CC-BY-SA-4.0. Preserve all relevant notices. **ArtCraft is non-free, source-available, and not covered by a general binary-redistribution grant.** Its frontend is also marked non-free; direct outputs allow only `artcraft`/`artcraft-frontend`, while overlay consumers own their license policy. It is excluded from automatic free-package checks. Do not publish its binaries/cache/artifacts without permission.

Linux wrappers supply graphics/window-system loaders, not host GPU drivers. Audio hardware, portals, display servers, proprietary plugins and external services remain host/upstream concerns. Do not alter GPU drivers, activate a consumer system, expose a live desktop or read user documents/credentials merely to test packaging. Use private synthetic fixtures and explicit permission for real hardware/services.

## Validation and maintenance policy

Keep app versions derived from pinned upstream manifests; do not maintain a second version table in recipes. Never leave fake hashes, floating fetches or unsupported-platform claims in delivered code. Cargo git sources need explicit verified output hashes; unknown sources must fail closed. Keep ArtCraft's SQLX build offline and retain BoringSSL patches, rather than bypassing them to make a build pass.

Supported outputs are `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`; current nixpkgs rejects Intel macOS. Linux native builds/isolated GUI rendering have been verified. ARM Linux/macOS evaluation is **not** a native build/runtime guarantee. Following/overlaying consumer nixpkgs changes effective dependencies and requires rebuilding.

If Graphify output exists, query it before broad searches; do not install an imperative duplicate. Make the smallest source-level change, update these pages and the README, validate current tracked bytes, scan redacted diffs/history and report evidence separately from limitations. Do not decrypt secrets or put credentials into Git, command arguments, store paths, logs or update artifacts.

**The primary maintenance workflow is updating ALL thirteen applications together:** see [workflows.md#update-all-applications](workflows.md#update-all-applications).
