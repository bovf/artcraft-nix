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
  gitSourceHashes = {
    "git+https://github.com/storytold/craft-libs?rev=92d392cff132eaf53e13afff77f38b5c11b73aa0#92d392cff132eaf53e13afff77f38b5c11b73aa0" = "sha256-/8I9DcqtsznoYPo4ECc/rPQIal6P9gyPksrvVHDW6Mg=";
    "git+https://github.com/storytold/craft-libs?rev=e11f9d9aebea5f6b8e74643c1ea1ed172ba5f545#e11f9d9aebea5f6b8e74643c1ea1ed172ba5f545" = "sha256-yTMWFdJDxJnbwHbing7TsrbmKRMhrjceMz5RwFJYt5g=";
    "git+https://github.com/storytold/egui.git?rev=6d518fc799681571963842f95b55a6b68431b15a#6d518fc799681571963842f95b55a6b68431b15a" = "sha256-xzgBk6K1X/MZ8WUlIdy+r/0cf1FDkhJJuwQHZX+WY9U=";
    "git+https://github.com/storytold/filmcraft?rev=2c5ba7a72619935f0481f99d59409e0d1844b234#2c5ba7a72619935f0481f99d59409e0d1844b234" = "sha256-WXiX4rF7zSwfu3yu9aNH2/xWYhAYFVX1rdrnccuTD7g=";
    "git+https://github.com/storytold/indd-utils?branch=main#7f3060e5bce78d21ea70e0d5eacb96edce15dfbe" = "sha256-9buHpnMVC8NPbe0JwF1guqoxeVv6PdO3OVcjSQk9fmk=";
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
  rustPlatform.buildRustPackage {
    inherit pname src version cargoDeps;
    cargoBuildFlags = cargoFlags;
    cargoTestFlags = cargoFlags;
    nativeBuildInputs = [pkg-config makeWrapper];
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
        cp packaging/linux/${appId}.mime.xml "$out/share/mime/packages/"
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
          test -f "$out/share/mime/packages/${appId}.mime.xml"
          python3 ${../tests/dialog-runtime.py} ${lib.getLib dbus}/lib ${lib.getExe zenity} "$out" ${pname}
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
        tests.cargo-resolution = import ../tests/cargo-resolution.nix {
          inherit runCommand rustPlatform src cargoDeps pname;
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
