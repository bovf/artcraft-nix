# artcraft-nix

Standalone, revision-pinned Nix source packages for the [Storytold](https://github.com/storytold) creative applications. Import this flake from NixOS, Home Manager or another flake, without depending on `pl-badwater`.

This is independent packaging, not an official or endorsed ArtCraft release. Development is hosted on [our GitLab](https://gitlab.dobryops.com/nix/artcraft-nix). GitLab CI is configured for default-branch source mirrors to GitHub/Codeberg; destination repositories are created manually. Canonical GitLab main has verified source-only GitHub/Codeberg mirrors; consumers refresh their immutable input pin separately.

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

Every named package builds from its locked upstream source and Cargo lockfile. The twelve native Rust/egui packages install both commands, upstream Linux desktop entries/icons/MIME definitions and required dynamic-library wrappers. Audio packages link ALSA on Linux; multimedia packages include FFmpeg in their command search path. Linux wrappers also expose the D-Bus client library for `rfd` file dialogs and Zenity for its fallback. The host still supplies the desktop portal/session; see [Linux file dialogs](docs/linux-file-dialogs.md). Shared `craft-fonts` is a pinned compile-time input, with font attribution and OFL notices installed alongside the code licenses.

All thirteen application inputs select explicit published release tags; their resolved revisions, fonts, nixpkgs and `rust-overlay` are pinned in `flake.lock`. Package versions come from those release manifests. There are no `latest` binary downloads or first-launch build scripts. The [2026-10-18 release update](docs/releases-2026-10-18.md) advances all twelve native apps again; ArtCraft remains at the latest published 0.41.0. Only lightweight source/evaluation checks were requested: these new applications have not been built or runtime-tested. The [Linux file-dialog follow-up](docs/validation.md#linux-file-dialog-follow-up-2026-10-12) is historical evidence for preceding PhotoCraft/FilmCraft releases, not acceptance of these pins. PDFCraft includes the upstream default English OCR models and their CC-BY-SA-4.0 notices, fetched against upstream's SHA-256 values. Other optional features remain at upstream defaults. ArtCraft builds its frontend separately from its Rust backend.

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

The previous development snapshots completed native x86_64 Linux builds, configured unit/install checks and isolated software-rendered GUI smoke tests. Those results do **not** validate the current release selections. See [validation](docs/validation.md) for the scoped current Linux file-dialog follow-up, historical evidence and limits. ARM Linux/Darwin are evaluation-only until tested on native runners; neither hardware nor service behavior is implicitly verified by a Linux build. GitLab CI mirrors source only; it does not build packages or verify hardware.

## Import into another flake

Use the verified GitHub main source mirror below, or Git over SSH to canonical GitLab. `flake.lock` selects the immutable source snapshot; refresh it explicitly after an authorized producer update.

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.artcraft-nix.url = "github:bovf/artcraft-nix/main";

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
# First update all thirteen release-tag URLs in flake.nix, then resolve them:
nix flake update photocraft artcraft lightcraft filmcraft pdfcraft vectorcraft \
  effectcraft designcraft wordcraft cadcraft gridcraft deckcraft soundcraft
# Refresh shared fonts separately when required:
nix flake update craft-fonts
# Update toolchain inputs separately when requested/required:
nix flake update nixpkgs rust-overlay
```

After source updates, inspect the upstream manifests/licenses, build the affected package and re-run checks before publishing the lock change. The exact FilmCraft and craft-libs Git sources have explicit content hashes in `packages/craft.nix`; when dependencies change, verify their exact trees and update the map, never enable unchecked Git fetches. ArtCraft's npm cache hash must be recomputed when its frontend lock changes. The pinned nixpkgs `prefetch-npm-deps` helper can fetch that cache without building or testing an application.

Read [agent context](.agents/AGENTS.md) and the [all-app update workflow](.agents/workflows.md#update-all-applications) for the full procedure, dependency hash/model/compiler handling, validation and publishing safeguards. “Latest release” means GitHub's latest non-draft, non-prerelease publication at selection time. Edit the explicit tag URLs before locking a newer release; `nix flake update` alone does not advance a fixed tag. Development snapshots require an explicit choice, especially if newer than the latest published release.

## GitLab CI source mirrors

On default-branch pushes, [GitLab CI](.gitlab-ci.yml) syncs the source branch to the configured GitHub and Codeberg mirrors using CI variables. It does not build packages, upload binaries or deploy anything.

## Verified headless controls

See the [historical capability matrix](docs/capabilities.md) and [previously tested paths/revisions](docs/capabilities.json). Twelve native synthetic MCP operations were tested against the previous snapshots, not these new releases; ArtCraft remains install-only. No GUI/provider/redistribution claim is added.
