# Workflows and validation

## Standard change loop

1. Confirm this checkout/branch and the requested scope: `git status --short --branch`, `git remote -v`. Read [AGENTS.md](AGENTS.md).
2. Query Graphify first if `graphify-out/graph.json` exists. Read the owning recipes, pinned manifests and relevant upstream changes, not only the diff.
3. Make the smallest packaging change; do not modify a consumer system or upstream user data.
4. Validate narrowly, then run the appropriate matrix below. Keep evaluation, builds, install checks, GUI rendering and real hardware/service tests distinct.
5. Update README/context/evidence, review all intended tracked bytes, run redacted scans and publish only the authorized files/ref.

Lock updates are a maintenance operation, **not** a generic test. Freeze the selected snapshot while validating; do not endlessly chase moving upstream heads during a build.

## Update all applications

This is the default workflow when asked to update the creative suite to the latest available versions. It updates **all thirteen** published release-tag pins, including non-free ArtCraft. Application versions are read automatically from the selected manifests. Query each upstream's latest non-draft, non-prerelease GitHub release and edit its URL in `flake.nix` before updating the lock. A newer development snapshot may be ahead of the latest release: ask before a downgrade. Shared fonts/toolchains are separate updates when needed. Do not silently switch back to branch snapshots or use unpinned prebuilt binaries.

The 2026-10-13 operator requested a lightweight release update: source/hash checks, formatting, existing source-contract and evaluation only, with no full application/GUI build matrix. The producer is published to canonical main; the consumer's pin is left uncommitted for the operator's own build/testing/push/merge. See [selected releases and exact limits](../docs/releases-2026-10-13.md).

The operator requested the 2026-10-11 update **without tests/builds**. Only release metadata/source inspection, lock resolution and ArtCraft dependency-cache prefetching were performed. The normal validation/publishing steps below remain future work, not evidence for that branch.

### 1. Start from an accountable checkout

Do not overwrite existing work or use `git reset --hard`. Preserve unrelated work; CI changes require separate review and must remain source-mirroring only. Start a reviewed update branch from the intended published baseline:

```bash
git status --short --branch
git remote -v
git switch -c chore/update-applications-YYYY-MM-DD
cp flake.lock /tmp/artcraft-flake-lock.before.json
nix develop
```

Record the original revisions and versions before updating:

```bash
nix eval --json --no-write-lock-file .#packages.x86_64-linux \
  --apply 'p: builtins.mapAttrs (_: v: { version = v.version; rev = v.src.rev; }) (builtins.removeAttrs p ["default"])' \
  > /tmp/artcraft-packages.before.json
```

### 2. Resolve all upstreams once

First edit all thirteen application input URLs to the selected release tags; locking the existing tag does not discover a newer release. Then run these commands in Bash, from **this repository**, not a consumer flake:

```bash
apps=(photocraft artcraft lightcraft filmcraft pdfcraft vectorcraft effectcraft designcraft wordcraft cadcraft gridcraft deckcraft soundcraft)
nix flake update "${apps[@]}"
git diff -- flake.lock
```

That is the all-app update, not just the default PhotoCraft or twelve free apps. Refresh `craft-fonts` separately if required by the selected releases. Review each upstream's changes, manifests, MSRV/native requirements, desktop/assets, license/brand notices and Cargo/npm locks. Record changed and unchanged app revisions; unchanged input revisions are a valid “already latest” result. Do not claim permanently latest from a moving branch.

Toolchain updates are separate, deliberate operations when requested or needed for the new sources:

```bash
nix flake update nixpkgs rust-overlay
```

The PDF compiler version is explicitly pinned in `packages/default.nix`; updating `rust-overlay` alone does not change it. Raise that version only with compatible official compiler/std archives and a successful actual PDF build. Remove the workaround only after demonstrating that the unoverridden nixpkgs compiler builds RTen/PDF successfully. Do not switch off OCR/AVX code or change global host CPU/GPU settings to hide a compiler failure.

### 3. Reconcile dependency and asset hashes

- **Cargo registries:** import the new upstream `Cargo.lock`; checksum failures require investigation, not weakening verification or deleting the lock.
- **Cargo git dependencies:** `packages/craft.nix` maps exact full Git source strings to verified hashes for EffectCraft's FilmCraft commit `2c5ba7a72619935f0481f99d59409e0d1844b234` and the three craft-libs revisions selected by current app locks. Compare every git source in the new lock; unlisted strings must fail. For a changed revision, use its exact public source to prefetch the unpacked tree:

  ```bash
  nix store prefetch-file --unpack --json \
    'https://github.com/storytold/filmcraft/archive/FULL_NEW_COMMIT.tar.gz'
  ```

  Review the result, update the revision assertion/hash, then build the Cargo dependencies/EffectCraft to confirm that `fetchgit` has the same tree hash. Archive export rules/submodules can differ: only the successful fixed-output Cargo dependency build decides acceptance. Unknown git dependencies must fail until explicitly pinned; never enable unchecked builtin Git fetches.
- **ArtCraft npm:** compare `frontend/package-lock.json`. The pinned nixpkgs `prefetch-npm-deps` helper can fetch the new lockfile into a private directory; `nix hash path DIRECTORY` yields its cache SRI without application builds or tests. Use the recipe's fetcher format (currently `NPM_FETCHER_VERSION=1`) and bounded `NIX_BUILD_CORES=3`. Source fetches/hashes are not build acceptance. For a validated update, if dependencies changed, temporarily set `npmDepsHash = lib.fakeHash` in `packages/artcraft.nix`, then run:

  ```bash
  nix build --no-link --no-write-lock-file .#artcraft.frontend.npmDeps
  ```

  The expected fixed-output failure reports `got: sha256-…`. Replace the placeholder with that verified hash and build `.#artcraft.frontend`, then `.#artcraft`. Do not hand-guess it, disable integrity checks or commit a placeholder. Keep the workspace source root, writable **build-local** npm cache, ignore-scripts policy and nested Vite shebang fix. Never chmod/chown a Nix store cache to satisfy npm's misleading permission advice.
- **ArtCraft native build:** retain `SQLX_OFFLINE=true` and the shipped `.sqlx` metadata; never point compilation at a live database. BoringSSL needs Git for its bundled patches, plus CMake/Perl/bindgen. Do not bypass those patches with `BORING_BSSL_ASSUME_PATCHED`.
- **Fonts:** inspect the new `craft-fonts` manifest and notices, preserving attribution and every OFL file. Missing required fonts must fail a build rather than silently producing an incomplete application.
- **PDF models:** URLs/content/license hashes come directly from pinned `ATTRIBUTION.toml`. Build `.#pdfcraft.ocrModels`; preserve its credit manifest and `.LICENCE.txt` files. A changed model license/name/schema needs recipe/contract review, not a broad assertion removal. Model updates must not require first-use network installation.

### 4. Evaluate, then actually build ALL apps

```bash
nix fmt -- --check flake.nix packages
nix flake check --no-build --all-systems --no-write-lock-file
nix build --no-link --no-write-lock-file .#checks.x86_64-linux.source-contract
nix build --keep-going --no-link --no-write-lock-file --max-jobs 1 --cores 3 \
  "${apps[@]/#/.#}"
nix flake check --no-write-lock-file --max-jobs 1 --cores 3
```

The explicit build array includes ArtCraft; ordinary checks intentionally exclude its non-free binary. Review upstream's license before building it and never publish its artifacts/cache without permission. Use a private Linux build environment and enough disk space; a full source build can take hours. `--keep-going` allows independent results but an eventual nonzero exit is **not** acceptance. Consume final command statuses and inspect failures, not only the last log line or a derivation evaluation.

`nix flake check` checks the native system and cached outputs; it does not cross-build macOS or ARM. Use native ARM Linux/Darwin runners for build/runtime claims and the relevant `.#checks.SYSTEM` outputs. If such runners are unavailable, explicitly report evaluation-only coverage.

Check the final app outputs/versions and compare with the recorded baseline:

```bash
nix eval --json --no-write-lock-file .#apps \
  --apply 'builtins.mapAttrs (_: builtins.attrNames)'
nix eval --json --no-write-lock-file .#packages.x86_64-linux \
  --apply 'p: builtins.mapAttrs (_: v: { version = v.version; rev = v.src.rev; }) (builtins.removeAttrs p ["default"])' \
  > /tmp/artcraft-packages.after.json
```

Smoke-test each installed GUI/CLI and changed features with private, synthetic inputs. Never point a helper/MCP server at a real HOME or document collection. For GUI automation, use private HOME/runtime/data directories, a separate Xvfb/display, software Mesa and a filesystem/network sandbox containing only store inputs; assert a mapped rendered window, not merely a surviving process. The initial thirteen-app smoke tests used this isolation. Hardware/audio/portals/plugins/authenticated external services need separately approved real tests. Never claim those from a software-rendered blank document.

For PDF, `pdfcraft-cli run ocr_status --root PRIVATE_FIXTURE_DIRECTORY` must report `available: true` without `PDFCRAFT_MODELS` overrides. CAD sample SVG export is another useful hardware-free feature check. Preserve the consumer's configuration and files.

### 5. Review and publish the accepted snapshot

Update [validation evidence](../docs/validation.md), README and this context for changed ownership, compiler exceptions, features or limits. Compare exact accepted revisions, dependency hashes and output names. Do not commit a newer lock selection than the one actually built.

```bash
git diff --check
nix fmt -- --check flake.nix packages
# If Gitleaks is not already available, obtain it through Nix, not an imperative installer:
nix shell nixpkgs#gitleaks --command gitleaks dir . --redact --no-banner
git status --short
```

Stage paths explicitly; **do not use `git add .`** with unrelated local changes:

```bash
git add flake.nix flake.lock packages tests README.md LICENSE .gitignore .agents docs
git diff --cached --check
git diff --cached --name-status
# Review any CI changes separately; ordinary app updates do not change mirroring:
git diff --cached -- .gitlab-ci.yml
```

After authorized review, use a concise conventional subject, then a normal feature-branch push to GitLab. No co-author/signature trailers, force-pushing GitLab feature branches, unsolicited merge or activation. Only the authorized default-branch CI mirror job force-updates external source mirrors. Verify the pushed SHA with `git ls-remote origin refs/heads/BRANCH`. For a scoped downstream update, advance only its `artcraft-nix` input after this repository's accepted commit is published; follow the downstream repository's own authorization and tests.

## Mirror CI changes

The operator authorized `.gitlab-ci.yml` after the source-only migration. Match `pi-nix`'s default-branch-push workflow, full fresh clone, `nix-cache` tag, serialization and timeout; do not turn this into an app-build/cache/deploy pipeline. The user creates GitHub/Codeberg repositories manually; see [variable names and setup](../README.md#gitlab-ci-source-mirrors). Never copy actual secrets into YAML, arguments, artifacts or logs. `GITLAB_TOKEN`/`ATTIC_TOKEN` are unused; do not silently repurpose them for external mirror authentication.

Preserve the complete inline reference pipeline: the only deliberate differences from `pi-nix/.gitlab-ci.yml` are `GITHUB_MIRROR_REPO=bovf/artcraft-nix` and `CODEBERG_MIRROR_REPO=bovfbovf/artcraft-nix`. URL variables override token/repository fallbacks without custom host restrictions. Do not split it into a helper or change authentication/variable precedence without being asked.

Local validation (no remote push):

```bash
nix shell --inputs-from . nixpkgs#yamllint --command yamllint .gitlab-ci.yml
```

Also parse YAML to extract `mirror:main.script`, check the Bash syntax/ShellCheck, and compare the full configuration to the reference after those two substitutions. For mocked tests use only synthetic URLs/tokens and a fake Git executable; never invoke a real authenticated mirror push just to validate YAML. Keep token/credential-bearing URL variables protected/masked and job tracing disabled. Local tests are not evidence of live credentials or external repository permissions.

Stage `.gitlab-ci.yml` explicitly for an authorized CI change; the earlier migration's CI omission is historical, not a current prohibition. Do not add a duplicate `.gitlab-ci.yaml`. A feature push does not execute the default-branch-only job. A local green fixture or skipped destination is not a verified mirror; confirm live job logs and all three source SHAs only after approved merge and actual configured execution.

## Linux file-dialog runtime

The common Linux Rust wrappers supply D-Bus's client library and Zenity; keep
these dependencies in `packages/craft.nix`, not per-consumer overlays or global
session variables. Every Linux install check exercises the actual GUI/CLI
wrapper environment with `tests/dialog-runtime.py`, without starting an app.
Use the [isolated Open/Save procedure and limits](../docs/linux-file-dialogs.md)
for representative GUI acceptance; wrapper checks alone do not certify a live
Wayland session. Do not apply PhotoCraft's X11 preference or touch real files
merely to validate packaging.

## Narrow changes and recovery

For one requested app update, use `nix flake update NAME`, inspect its dependency/asset changes and build it, plus shared-font/toolchain affected apps where appropriate. Do not quietly turn it into an all-input refresh. Documentation-only changes still need valid relative links/commands, diff checks and redacted scans.

When a build fails: retain the log/status and exact branch/input/compiler selection, inspect the first real error, reproduce the smallest safe case, fix at the owning layer, and re-run affected checks. Nixpkgs Rust 1.98.1/LLVM 21's AVX512 signature failure was reproduced with a compile-only intrinsic probe and resolved using the same Rust version paired with official LLVM 22; no app source or hardware setting changed. Fixture title mismatches (`CADCraft`, spreadsheet `Book1`) or GTK's hidden leader windows are test-harness issues, not evidence that an app fails to render.

Do not auto-delete unrelated Git changes/roots/results or run live store cleanup to resolve resource problems. Do not assume a completed background process succeeded: read its final status and test current tracked bytes before publishing.
