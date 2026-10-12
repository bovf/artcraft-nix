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
  filmGitHash = "sha256-WXiX4rF7zSwfu3yu9aNH2/xWYhAYFVX1rdrnccuTD7g=";
  pdfModels = import ./pdf-models.nix {inherit lib fetchurl runCommand src;};
  gitPackages =
    builtins.filter (p: lib.hasPrefix "git+" (p.source or ""))
    (builtins.fromTOML (builtins.readFile "${src}/Cargo.lock")).package;
in
  rustPlatform.buildRustPackage {
    inherit pname src version;
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      # EffectCraft pins FilmCraft's native media crates at this exact commit.
      outputHashes = lib.listToAttrs (map (p: {
          name = "${p.name}-${p.version}";
          value = assert lib.hasInfix "2c5ba7a72619935f0481f99d59409e0d1844b234" p.source; filmGitHash;
        })
        gitPackages);
    };
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
        test -s "$out/share/pdfcraft/models/text-detection.rten"
        test -s "$out/share/pdfcraft/models/text-recognition.rten"
        test -s "$out/share/pdfcraft/models/ATTRIBUTION.toml"
      '';
    passthru = {upstreamVersion = version;} // lib.optionalAttrs (pname == "pdfcraft") {ocrModels = pdfModels;};
    meta = {
      description = "${lib.toUpper (lib.substring 0 1 pname)}${lib.substring 1 (-1) pname} desktop application and companion CLI";
      homepage = "https://github.com/storytold/${pname}";
      license = with lib.licenses; [mit asl20] ++ lib.optional (pname == "pdfcraft") cc-by-sa-40;
      platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      mainProgram = pname;
    };
  }
