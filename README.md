# artcraft-nix

Standalone, revision-pinned Nix source packages for the [Storytold](https://github.com/storytold) creative applications. Import this flake from NixOS, Home Manager or another flake, without depending on `pl-badwater`.

This is independent packaging, not an official or endorsed ArtCraft release. Development is hosted on [our GitLab](https://gitlab.dobryops.com/nix/artcraft-nix). GitLab CI is configured for default-branch source mirrors to GitHub/Codeberg; destination repositories are created manually. Mirror execution/parity is not yet verified, and downstream synchronization is not configured.

## Packages

| Package / desktop command | Companion CLI | Purpose |
|---|---|---|
| `photocraft` (default) | `photocraft-cli` | Image editing |
| `lightcraft` | `lightcraft-cli` | Photo library and RAW development |
| `filmcraft` | `filmcraft-cli` | Video editing |
| `pdfcraft` | `pdfcraft-cli` | PDF tools |
| `vectorcraft` | `vectorcraft-cli` | Vector illustration |
| `effectcraft` | `effectcraft-cli` | Motion graphics and effects |
| `designcraft` | `designcraft-cli` | Page layout and publishing |
| `wordcraft` | `wordcraft-cli` | Word processing |
| `cadcraft` | `cadcraft-cli` | CAD |
| `gridcraft` | `gridcraft-cli` | Spreadsheets |
| `deckcraft` | `deckcraft-cli` | Presentations |
| `soundcraft` | `soundcraft-cli` | Audio workstation |
| `artcraft` | — | Tauri/React creative studio; **non-free**, see below |

Every named package builds from its locked upstream source and Cargo lockfile. The twelve native Rust/egui packages install both commands, upstream Linux desktop entries/icons/MIME definitions and required dynamic-library wrappers. Audio packages link ALSA on Linux; multimedia packages include FFmpeg in their command search path. Shared `craft-fonts` is a pinned compile-time input, with font attribution and OFL notices installed alongside the code licenses.

All application sources, fonts, nixpkgs and `rust-overlay` are pinned in `flake.lock`. There are no `latest` binary downloads or first-launch build scripts. PDFCraft includes the upstream default English OCR models and their CC-BY-SA-4.0 notices, fetched against upstream's SHA-256 values. Other optional features remain at upstream defaults. ArtCraft builds its frontend separately from its Rust backend.

## Build and run locally

Requires Nix with `nix-command` and `flakes` enabled. Source builds are substantial; keep parallel jobs bounded on machines with limited RAM.

```bash
nix build .#photocraft --no-link --max-jobs 1 --cores 3
nix run .#photocraft -- --version
nix run .#photocraft
nix shell .#photocraft --command photocraft-cli --help
nix build .#soundcraft --no-link
```

Outputs target `x86_64-linux`, `aarch64-linux` and `aarch64-darwin`. Current nixpkgs 26.11 dropped Intel (`x86_64-darwin`) macOS support; it is deliberately not advertised as a working output. Linux uses the host's graphics drivers, display server and desktop portals; wrappers supply the loader/client libraries, **not** a replacement GPU driver. On non-NixOS Linux you may need a host-compatible graphics bridge such as nixGL. WSL GUI use additionally requires WSLg. Darwin packages provide command-line launchers; signed/notarized `.app` bundles are not produced.

All thirteen applications have completed native x86_64 Linux builds, configured unit/install checks and isolated software-rendered GUI smoke tests. See [validation](docs/validation.md) for exact evidence and limits. ARM Linux/Darwin are evaluation-only until tested on native runners; neither hardware nor service behavior is implicitly verified by a Linux build. GitLab CI mirrors source only; it does not build packages or verify hardware.

## Import into another flake

Use Git over SSH for the private GitLab repository; readers need GitLab access. Until the packaging branch is merged, select `feat/migrate-artcraft-suite` as below; remove the `?ref=…` selection once the accepted flake is on the default branch. Future public mirrors can replace only the input URL once verified.

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.artcraft-nix.url = "git+ssh://git@gitlab.dobryops.com/nix/artcraft-nix.git?ref=feat/migrate-artcraft-suite";

  outputs = { self, nixpkgs, artcraft-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            artcraft-nix.packages.${pkgs.stdenv.hostPlatform.system}.photocraft
            artcraft-nix.packages.${pkgs.stdenv.hostPlatform.system}.vectorcraft
          ];
        })
      ];
    };
  };
}
```

The same package values work in `home.packages`. **Direct package consumption** uses this flake's tested nixpkgs/toolchain and is the safest way to avoid a consumer's older Rust compiler.

An overlay is also available:

```nix
nixpkgs.overlays = [ inputs.artcraft-nix.overlays.default ];
environment.systemPackages = [ pkgs.photocraft pkgs.soundcraft ];
```

The overlay uses the consumer's packages and toolchain, except PDFCraft's explicitly paired official Rust 1.98.1 compiler/std. This avoids a reproduced AVX512 intrinsic mismatch in nixpkgs's LLVM 21 build, without patching the app or altering host drivers. Following another nixpkgs revision is optional:

```nix
inputs.artcraft-nix.inputs.nixpkgs.follows = "nixpkgs";
```

Only do this with compatible dependencies: current sources require Rust 1.95 or newer for several apps. Changing/following nixpkgs requires rebuilding and validating, not merely evaluating output names.

## ArtCraft licensing and redistribution

`storytold/artcraft` is **not** one of the MIT/Apache-licensed Rust/egui applications. Its [source-available license](https://github.com/storytold/artcraft/blob/main/LICENSE.md) restricts commercial/competitive use and does not provide an unambiguous general binary-redistribution grant. This recipe supports building it for permitted personal use; it is marked non-free. Do not publish its binary cache, frontend or release artifacts without confirming permission with upstream. Its online services/account requirements remain upstream behavior.

Selecting `nix build .#artcraft` opts into this flake's specifically permitted non-free package. Overlay consumers must explicitly allow `artcraft` in their own nixpkgs configuration, for example `nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or "") [ "artcraft" "artcraft-frontend" ];`. The default package and automatic free-package checks exclude ArtCraft. Build it explicitly for permitted personal use; no binary publication or active CI job is configured.

The other twelve apps declare `MIT OR Apache-2.0` for code. Embedded fonts have their own OFL notices, PDF OCR model data is CC-BY-SA-4.0, and supplied brand assets have separate trademark/use restrictions; those notices are retained. Do not interpret the packaging repository's license as relicensing upstream software/assets, and do not represent modified or unofficial builds as endorsed releases.

## Maintenance and updates

```bash
nix develop
nix fmt -- --check flake.nix packages
nix flake check --no-build --all-systems --no-write-lock-file
nix build .#checks.x86_64-linux.source-contract --no-link
nix flake check --no-write-lock-file  # actually builds the free apps and their checks
# Advance ALL thirteen app sources and their shared fonts:
nix flake update photocraft artcraft lightcraft filmcraft pdfcraft vectorcraft \
  effectcraft designcraft wordcraft cadcraft gridcraft deckcraft soundcraft craft-fonts
# Update toolchain inputs separately when requested/required:
nix flake update nixpkgs rust-overlay
```

After source updates, inspect the upstream manifests/licenses, build the affected package and re-run checks before publishing the lock change. EffectCraft's locked FilmCraft git dependency has an explicit content hash in `packages/craft.nix`; if that dependency changes, prefetch the new exact revision and update the hash, never use an unchecked git fetch. ArtCraft's npm cache hash must be recomputed when its frontend lock changes.

Read [agent context](.agents/AGENTS.md) and the [all-app update workflow](.agents/workflows.md#update-all-applications) for the full procedure, dependency hash/model/compiler handling, validation and publishing safeguards. “Latest” means the selected default-branch snapshots at update time, not necessarily upstream release tags.

## GitLab CI source mirrors

[`.gitlab-ci.yml`](.gitlab-ci.yml) uses the same setup as `pi-nix`: default-branch pushes only, a full fresh clone (`GIT_DEPTH=0`), the `nix-cache` runner, `main-mirror-push` serialization and a 30-minute job timeout. It runs [the mirror helper](ci/mirror.sh), not Nix builds or cache publication. Feature branches, tags, merge requests, schedules and manual pipelines do not run this workflow.

Create these destination repositories manually, without an initial README/license commit:

- GitHub: **`bovf/artcraft-nix`**
- Codeberg: **`bovfbovf/artcraft-nix`**

The job references the same variable names as `pi-nix`; secret values never belong in YAML:

| Variable | Use |
|---|---|
| `GITHUB_MIRROR_REPO` | Default `bovf/artcraft-nix`; non-secret repository override. |
| `CODEBERG_MIRROR_REPO` | Default `bovfbovf/artcraft-nix`; non-secret repository override. |
| `GITHUB_TOKEN` | Protected/masked GitHub token with write access to the destination repository. |
| `CODEBERG_TOKEN` | Protected/masked Codeberg token with write access as `bovfbovf`. |
| `GITHUB_MIRROR_URL` | Optional credential-free `https://github.com/…` or `git@github.com:…` destination. |
| `CODEBERG_MIRROR_URL` | Optional credential-free `https://codeberg.org/…` or `git@codeberg.org:…` destination. |

Use the existing CI variable settings for tokens (environment scope `*`; disable expansion for secret values). Their names are referenced, **not** defined as empty YAML defaults that could interfere with inherited variables. Tokens are supplied through a temporary Git askpass helper, never embedded into Git arguments. Unlike the reference's token-bearing URL fallback, URL overrides here must not contain credentials: keep them in the corresponding token variable, or use SSH with runner-managed keys. Do not enable `CI_DEBUG_TRACE` for credentialed jobs.

The supplied settings page confirms the Nix group runner with tag `nix-cache` is available. It currently lists inherited `GITLAB_TOKEN` and `ATTIC_TOKEN`, but those are neither needed nor substitutes for GitHub/Codeberg authentication; no live variable provisioning is claimed. A missing mirror URL/token causes that destination to be skipped, as in `pi-nix`. Once credentials are available by these names, creating the destination repositories is the remaining external setup. Fine-grained tokens must include write access to the new repositories.

Protect the default branch so protected variables are available. The job **force-updates only that branch**: GitLab is authoritative, so do not edit the mirrored branch independently. Tags and other branches are not copied. Optional URL overrides must point at the intended ArtCraft repositories, not the old Pi destinations.

No live mirror push, GitLab pipeline success or destination parity is asserted by local tests. Before using public mirror URLs in consumers, verify the GitLab/GitHub/Codeberg default-branch SHA and fetched flake bytes after a real run. No application binaries, binary caches or deployment are published; ArtCraft's separate redistribution restrictions remain in force.
