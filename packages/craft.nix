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
    "git+https://github.com/skylartaylor/winit.git?rev=3d51077fd1a966f84df9ef287839dc84fd5b4ca7#3d51077fd1a966f84df9ef287839dc84fd5b4ca7" = "sha256-q1gDwAj8xU/2OC4CtCG72ZvrkZ436V3zsqh5hovLTcs=";
    "git+https://github.com/storytold/craft-libs?rev=3d37da389a3618ab9b76109da11416e9ca4ea719#3d37da389a3618ab9b76109da11416e9ca4ea719" = "sha256-uXP0zITi8i1JDUyc451FmZ0Pl1ZK4D0rlTJQmGFVm0I=";
    "git+https://github.com/storytold/craft-libs?rev=ca50d63b773c99f96e75c77ce5a1d21e7c9cda0d#ca50d63b773c99f96e75c77ce5a1d21e7c9cda0d" = "sha256-6r1iIlwK6HlUkascw0e4R9L2H5WMgKO2y6PEa51Flws=";
    "git+https://github.com/storytold/craft-libs?rev=f03ec27ab2c405969428512178f746183cd55ca0#f03ec27ab2c405969428512178f746183cd55ca0" = "sha256-QtSjPVQSYsqqmg/9mtfC4ueAFcZ3IcL4gb29B+BfgmY=";
    "git+https://github.com/storytold/pdfcraft?rev=b5467d93a0ffaa5e5e6658bccdf8655a3ba689c9#b5467d93a0ffaa5e5e6658bccdf8655a3ba689c9" = "sha256-xGbwY2SCjT1QTwVczSm3kSOxpweYfjd/2zgGk7EhqCE=";
    "git+https://github.com/storytold/winprint.rs?rev=417ac3c4d14d3da5485a99c7d5ce8f05664ec312#417ac3c4d14d3da5485a99c7d5ce8f05664ec312" = "sha256-n1pcNaBGrnvSsE5MedeSRczJOMhfmF/LGFiiDTrG1GM=";
    "git+https://github.com/storytold/winprint.rs?rev=5f80b9baf6b58937c401656634e42d33f00ddf49#5f80b9baf6b58937c401656634e42d33f00ddf49" = "sha256-wnz/VbqQ3j/x1PEq6Elxu/oSjVqdONfqQmZ31NsTIIc=";
    "git+https://github.com/storytold/filmcraft?rev=2c5ba7a72619935f0481f99d59409e0d1844b234#2c5ba7a72619935f0481f99d59409e0d1844b234" = "sha256-WXiX4rF7zSwfu3yu9aNH2/xWYhAYFVX1rdrnccuTD7g=";
    "git+https://github.com/storytold/craft-libs?rev=5c874d51eeb3de70e735c8ce87a59a7dedd47675#5c874d51eeb3de70e735c8ce87a59a7dedd47675" = "sha256-VhLeT7VLdZAIz6gR9PdFI34IJxHsGF8NE0uzFCN2vIU=";
    "git+https://github.com/storytold/craft-libs?rev=d991bf6792f8ade99c51358bf3c1d902c8cd96b5#d991bf6792f8ade99c51358bf3c1d902c8cd96b5" = "sha256-J/EJJeDDWXc+QQtpUqnAKKA4piOdPRbH3uG1ms2BRgY=";
    "git+https://github.com/storytold/craft-libs?rev=d27646a5f7c8b4fc85d9dd3213b8c88b58e0088d#d27646a5f7c8b4fc85d9dd3213b8c88b58e0088d" = "sha256-u2AR5YZZSRzhWaevgR2S/jofD99J3YWKJA+CktUJbRY=";
  };
  pdfModels = import ./pdf-models.nix {inherit lib fetchurl runCommand src;};
  gitPackages =
    builtins.filter (p: lib.hasPrefix "git+" (p.source or ""))
    (builtins.fromTOML (builtins.readFile "${src}/Cargo.lock")).package;
in
  rustPlatform.buildRustPackage {
    inherit pname src version;
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      # Exact FilmCraft/craft-libs sources only; unknown Git dependencies fail closed.
      outputHashes = lib.listToAttrs (map (p: {
          name = "${p.name}-${p.version}";
          value = assert builtins.hasAttr p.source gitSourceHashes; gitSourceHashes.${p.source};
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
