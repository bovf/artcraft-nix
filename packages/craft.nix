{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  makeWrapper,
  alsa-lib,
  libglvnd,
  vulkan-loader,
  wayland,
  libxkbcommon,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxext,
  xdg-utils,
  dbus,
  zenity,
  ffmpeg,
  python3,
  desktop-file-utils,
  fetchurl,
  runCommand,
  writeShellScriptBin,
  bash,
  bubblewrap,
  util-linux,
  pname,
  src,
  fonts,
}: let
  manifest = builtins.fromTOML (builtins.readFile "${src}/Cargo.toml");
  version = manifest.workspace.package.version;
  audio = builtins.elem pname ["soundcraft" "filmcraft" "effectcraft" "deckcraft"];
  multimedia = builtins.elem pname ["soundcraft" "filmcraft" "effectcraft" "deckcraft"];
  # rfd 0.17 dlopens libdbus for portals, then falls back to Zenity.
  runtimeLibraries = [dbus libglvnd vulkan-loader wayland libxkbcommon libx11 libxcursor libxi libxrandr libxext];
  commands = [pname "${pname}-cli"];
  cargoFlags = lib.concatMap (name: ["--package" name]) commands;
  appId = "ai.storyteller.${pname}";
  # Craft Anything declares no document MIME type; the other apps ship one.
  hasMime = pname != "craft-anything";
  # Test buses must use the store's session config, never the host's /etc.
  portalTestBus = writeShellScriptBin "dbus-daemon" ''
    if [ "''${1-}" = --session ]; then
      shift
      set -- --config-file=${dbus}/share/dbus-1/session.conf "$@"
    fi
    exec ${dbus}/bin/dbus-daemon "$@"
  '';
  # PhotoCraft refuses imports when Nix's hidden cgroup constraints cannot be read.
  photocraftTestCargo = writeShellScriptBin "cargo" ''
    set -euo pipefail
    cargo="''${PHOTOCRAFT_CHECK_CARGO:-${rustPlatform.rust.cargo}/bin/cargo}"
    if [ "''${1-}" != test ]; then
      exec "$cargo" "$@"
    fi
    fixture=$(mktemp -d "$TMPDIR/photocraft-check.XXXXXX")
    mkdir -m 700 "$fixture/home"
    printf 'root:x:0:0:Fixture:/root:/bin/sh\n' > "$fixture/passwd"
    printf 'root:x:0:\n' > "$fixture/group"
    printf '00000000000000000000000000000001\n' > "$fixture/machine-id"
    printf '127.0.0.1 localhost\n::1 localhost\n' > "$fixture/hosts"
    exec ${bubblewrap}/bin/bwrap --unshare-all --uid 0 --gid 0 \
      --cap-add CAP_SYS_ADMIN --cap-add CAP_SETPCAP --die-with-parent --new-session \
      --ro-bind /nix/store /nix/store --bind "$NIX_BUILD_TOP" "$NIX_BUILD_TOP" \
      --proc /proc --dev /dev --tmpfs /tmp --dir /sys/fs/cgroup \
      --ro-bind "$fixture/passwd" /etc/passwd --ro-bind "$fixture/group" /etc/group \
      --ro-bind "$fixture/machine-id" /etc/machine-id --ro-bind "$fixture/hosts" /etc/hosts \
      --dir /bin --ro-bind ${bash}/bin/bash /bin/sh \
      --setenv HOME "$fixture/home" --chdir "$PWD" \
      ${bash}/bin/bash -euc '
        ${util-linux}/bin/mount -t cgroup2 -o ro,nosuid,nodev,noexec cgroup2 /sys/fs/cgroup
        test -r /sys/fs/cgroup/cgroup.controllers
        exec ${util-linux}/bin/setpriv --bounding-set=-all --inh-caps=-all --ambient-caps=-all --no-new-privs "$@"
      ' -- "$cargo" "$@"
  '';
  gitSourceHashes = {
    "git+https://github.com/storytold/craft-libs?rev=01315d9c92b5b0e69082d35ca56099461a1efd45#01315d9c92b5b0e69082d35ca56099461a1efd45" = "sha256-kGDEUIrIVX80dX/f9jczFUenheXqFGIhBivc9tKJb+I=";
    "git+https://github.com/storytold/craft-libs?rev=1a11a4897865f7410c40d25ca6e452ce399a1a2c#1a11a4897865f7410c40d25ca6e452ce399a1a2c" = "sha256-6Q6qpUD73D9aUntjL9g9ovJHXwsWzQZpxsvlGsxEZmI=";
    "git+https://github.com/storytold/craft-libs?rev=762a06a4c6b48b522b7d4de84a87917ef90265e6#762a06a4c6b48b522b7d4de84a87917ef90265e6" = "sha256-cyjktjU+fsQFQaG/aKxq7xtj/mrpdLEqCjKgujCXaAE=";
    "git+https://github.com/storytold/craft-libs?rev=787a7a0f972fd1d7a7618fdbeca3a5267a0407ff#787a7a0f972fd1d7a7618fdbeca3a5267a0407ff" = "sha256-oEMbxXiZ/e9RhYrefEUC0gFLPlaR9LxtUWUU8coz9As=";
    "git+https://github.com/storytold/craft-libs?rev=92d392cff132eaf53e13afff77f38b5c11b73aa0#92d392cff132eaf53e13afff77f38b5c11b73aa0" = "sha256-/8I9DcqtsznoYPo4ECc/rPQIal6P9gyPksrvVHDW6Mg=";
    "git+https://github.com/storytold/craft-libs?rev=9be9a63782298ab59cd9b7a42ee9cba4f42a5ccb#9be9a63782298ab59cd9b7a42ee9cba4f42a5ccb" = "sha256-P8GYGz4hEN7I0yzGQKIbi0g0Fh5LDqPTa0pFv03B+qc=";
    "git+https://github.com/storytold/craft-libs?rev=b8f7d93b00dfb8f172938f3d2d796ae62dcfe123#b8f7d93b00dfb8f172938f3d2d796ae62dcfe123" = "sha256-x3pHb9RI7FwssE7kivrhRo/0lIbrJee7Ll5Wrn96AMw=";
    "git+https://github.com/storytold/craft-libs?rev=c5a1cbfb5f9049f9270955caffb5bee5997aebf7#c5a1cbfb5f9049f9270955caffb5bee5997aebf7" = "sha256-BRkWxb796qLWtF1U1EqCZFa8h1YCuoAZcXrVWMN8MEY=";
    "git+https://github.com/storytold/craft-libs?rev=ca1b5e2edb8568335c6c14f390307bd5beae8238#ca1b5e2edb8568335c6c14f390307bd5beae8238" = "sha256-aEW6WiEyi9YB/mAVdhRJ/WaPBxaIhH1wkhenPE8KLNE=";
    "git+https://github.com/storytold/craft-libs?rev=e11f9d9aebea5f6b8e74643c1ea1ed172ba5f545#e11f9d9aebea5f6b8e74643c1ea1ed172ba5f545" = "sha256-yTMWFdJDxJnbwHbing7TsrbmKRMhrjceMz5RwFJYt5g=";
    "git+https://github.com/storytold/craft-libs?rev=f3b62ec61f45534392376492fc5ad33047375205#f3b62ec61f45534392376492fc5ad33047375205" = "sha256-Z6JTbIROXDFkdmdPmuLlo15uy7ZjxGX+EemLoz2G4gk=";
    "git+https://github.com/storytold/craft-libs?rev=f8f8829cc7be65d466d687dae381d1ca60e31242#f8f8829cc7be65d466d687dae381d1ca60e31242" = "sha256-0IBVplfbCZ7UhLR/tupGrOSYZkCFA2DBbUD9Bhs6xkE=";
    "git+https://github.com/storytold/egui.git?rev=6d518fc799681571963842f95b55a6b68431b15a#6d518fc799681571963842f95b55a6b68431b15a" = "sha256-xzgBk6K1X/MZ8WUlIdy+r/0cf1FDkhJJuwQHZX+WY9U=";
    "git+https://github.com/storytold/filmcraft?rev=09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5#09aaf9bf15d510eda1c413c0ccabb1d7e08b41c5" = "sha256-zwGlMsfzhQT+5pbYOaxyaOAfBkm6Ocs6s8+Dnz1A+nE=";
    "git+https://github.com/storytold/indd-utils?rev=7f3060e5bce78d21ea70e0d5eacb96edce15dfbe#7f3060e5bce78d21ea70e0d5eacb96edce15dfbe" = "sha256-9buHpnMVC8NPbe0JwF1guqoxeVv6PdO3OVcjSQk9fmk=";
    "git+https://github.com/storytold/winit.git?rev=a517b3846ee8457d84ee4975110bfda6797c44dc#a517b3846ee8457d84ee4975110bfda6797c44dc" = "sha256-+67bk7cqhM5VHqROL3PeghmhKJvlPIxhU73ay45vaxw=";
    "git+https://github.com/storytold/winprint.rs?rev=417ac3c4d14d3da5485a99c7d5ce8f05664ec312#417ac3c4d14d3da5485a99c7d5ce8f05664ec312" = "sha256-n1pcNaBGrnvSsE5MedeSRczJOMhfmF/LGFiiDTrG1GM=";
    "git+https://github.com/storytold/winprint.rs?rev=5f80b9baf6b58937c401656634e42d33f00ddf49#5f80b9baf6b58937c401656634e42d33f00ddf49" = "sha256-wnz/VbqQ3j/x1PEq6Elxu/oSjVqdONfqQmZ31NsTIIc=";
  };
  pdfModels = import ./pdf-models.nix {inherit lib fetchurl runCommand src;};
  lockContents = builtins.readFile "${src}/Cargo.lock";
  lock = builtins.fromTOML lockContents;
  unusedGitPatches = builtins.filter (p: lib.hasPrefix "git+" (p.source or "")) (lock.patch.unused or []);
  gitPackages = builtins.filter (p: lib.hasPrefix "git+" (p.source or "")) (lock.package ++ unusedGitPatches);
  # Cargo validates unused patch targets too; importCargoLock only reads package entries.
  vendorLockContents =
    lockContents
    + lib.concatMapStrings (p: ''

      [[package]]
      name = ${builtins.toJSON p.name}
      version = ${builtins.toJSON p.version}
      source = ${builtins.toJSON p.source}
    '')
    unusedGitPatches;
  cargoDeps =
    (rustPlatform.importCargoLock {
      lockFileContents = vendorLockContents;
      # Used and unused sources share the same exact, fail-closed hash allowlist.
      outputHashes = lib.listToAttrs (map (p: {
          name = "${p.name}-${p.version}";
          value = assert builtins.hasAttr p.source gitSourceHashes; gitSourceHashes.${p.source};
        })
        gitPackages);
    }).overrideAttrs (old: {
      # Keep the real lock untouched for the setup hook's consistency check and --locked.
      buildCommand =
        old.buildCommand
        + ''
          ln -sf ${src}/Cargo.lock "$out/Cargo.lock"
        '';
    });
in
  rustPlatform.buildRustPackage ({
      inherit pname src version cargoDeps;
      cargoBuildFlags = cargoFlags;
      cargoTestFlags = cargoFlags;
      nativeBuildInputs = [pkg-config makeWrapper];
      # Private portal buses and readable real memory constraints, only during tests.
      nativeCheckInputs = lib.optionals (stdenv.hostPlatform.isLinux && pname == "photocraft") [portalTestBus photocraftTestCargo];
      buildInputs = lib.optionals (stdenv.hostPlatform.isLinux && audio) [alsa-lib];
      env = {
        CRAFT_FONTS_DIR = toString fonts;
        CRAFT_FONTS_REQUIRED = "1";
        CARGO_PROFILE_RELEASE_LTO = "thin";
      };
      doCheck = true;
      postInstall =
        ''
              mkdir -p "$out/share/doc/${pname}"
              cp LICENSE-MIT LICENSE-APACHE "$out/share/doc/${pname}/"
              if [ -f NOTICE ]; then cp NOTICE "$out/share/doc/${pname}/"; fi
              for notice in ATTRIBUTION.md ATTRIBUTION.toml; do
                if [ -f "$notice" ]; then cp "$notice" "$out/share/doc/${pname}/"; fi
              done
              cp ${fonts}/ATTRIBUTION.md "$out/share/doc/${pname}/FONT-ATTRIBUTION.md"
              (cd ${fonts}/fonts; find . -name OFL.txt -type f -print0 | while IFS= read -r -d "" file; do
            install -Dm444 "$file" "$out/share/doc/${pname}/font-licenses/$file"
          done)
              if [ -f docs/brand/LICENSE-brand.txt ]; then
                cp docs/brand/LICENSE-brand.txt "$out/share/doc/${pname}/"
              fi
        ''
        + lib.optionalString stdenv.hostPlatform.isLinux ''
          mkdir -p "$out/share/applications" "$out/share/icons" "$out/share/mime/packages"
          cp packaging/linux/${appId}.desktop "$out/share/applications/"
          cp -r assets/app-icon/hicolor "$out/share/icons/"
          ${lib.optionalString hasMime ''cp packaging/linux/${appId}.mime.xml "$out/share/mime/packages/"''}
          for command in ${lib.escapeShellArgs commands}; do
            wrapProgram "$out/bin/$command" \
              --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibraries} \
              --prefix PATH : ${lib.makeBinPath ([xdg-utils zenity] ++ lib.optional multimedia ffmpeg)}
          done
        ''
        + lib.optionalString (stdenv.hostPlatform.isDarwin && multimedia) ''
          for command in ${lib.escapeShellArgs commands}; do
            wrapProgram "$out/bin/$command" --prefix PATH : ${lib.makeBinPath [ffmpeg]}
          done
        ''
        + lib.optionalString (pname == "pdfcraft") ''
          mkdir -p "$out/share/pdfcraft/models"
          cp -r ${pdfModels}/. "$out/share/pdfcraft/models/"
        '';
      doInstallCheck = true;
      nativeInstallCheckInputs = lib.optionals stdenv.hostPlatform.isLinux [desktop-file-utils python3];
      installCheckPhase =
        ''
          runHook preInstallCheck
          export HOME=$(mktemp -d)
          "$out/bin/${pname}" --version | grep -F '${version}'
          test -x "$out/bin/${pname}-cli"
          ${lib.optionalString stdenv.hostPlatform.isLinux ''
            desktop-file-validate "$out/share/applications/${appId}.desktop"
            test -f "$out/share/icons/hicolor/256x256/apps/${appId}.png"
            ${lib.optionalString hasMime ''test -f "$out/share/mime/packages/${appId}.mime.xml"''}
            python3 ${builtins.path {
              path = ../tests/dialog-runtime.py;
              name = "craft-dialog-runtime.py";
            }} ${lib.getLib dbus}/lib ${lib.getExe zenity} "$out" ${pname}
          ''}
          runHook postInstallCheck
        ''
        + lib.optionalString (pname == "pdfcraft") ''
          test -s "$out/share/pdfcraft/models/text-detection.onnx"
          test -s "$out/share/pdfcraft/models/text-recognition.onnx"
          test -s "$out/share/pdfcraft/models/ATTRIBUTION.toml"
        '';
      passthru =
        {
          upstreamVersion = version;
          tests =
            {
              cargo-resolution = import ../tests/cargo-resolution.nix {
                inherit runCommand rustPlatform src cargoDeps pname;
              };
            }
            // lib.optionalAttrs (stdenv.hostPlatform.isLinux && pname == "photocraft") {
              check-environment = import ../tests/photocraft-check-environment.nix {
                inherit runCommand src;
                inherit (rustPlatform.rust) rustc;
                testCargo = photocraftTestCargo;
                cc = stdenv.cc;
              };
            };
        }
        // lib.optionalAttrs (pname == "pdfcraft") {ocrModels = pdfModels;};
      meta = {
        description = "${lib.toUpper (lib.substring 0 1 pname)}${lib.substring 1 (-1) pname} desktop application and companion CLI";
        homepage = "https://github.com/storytold/${pname}";
        license = with lib.licenses; [mit asl20] ++ lib.optional (pname == "pdfcraft") cc-by-sa-40;
        platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
        mainProgram = pname;
      };
    }
    // lib.optionalAttrs (stdenv.hostPlatform.isLinux && pname == "photocraft") {
      preCheck = ''
        # Preserve the original auditable Cargo invocation, not a second test toolchain.
        export PHOTOCRAFT_CHECK_CARGO="$(command -v cargo)"
        test "$PHOTOCRAFT_CHECK_CARGO" != "${photocraftTestCargo}/bin/cargo"
        export PATH="${photocraftTestCargo}/bin:$PATH"
      '';
    })
