{
  lib,
  stdenv,
  rustPlatform,
  buildNpmPackage,
  pkg-config,
  gitMinimal,
  cmake,
  perl,
  makeWrapper,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  libappindicator-gtk3,
  openssl,
  xdg-utils,
  makeDesktopItem,
  src,
}: let
  config = builtins.fromJSON (builtins.readFile "${src}/crates/desktop/artcraft/tauri.conf.json");
  version = config.version;
  frontend = buildNpmPackage {
    pname = "artcraft-frontend";
    inherit version src;
    sourceRoot = "source/frontend";
    npmDepsHash = "sha256-MEfbgOH529EzHJDKm+m9c+OPCp9kUPcPKRnwUAW9RbM=";
    npmFlags = ["--ignore-scripts" "--legacy-peer-deps"];
    makeCacheWritable = true;
    meta.license = lib.licenses.unfree;
    env = {
      HUSKY = "0";
      NX_DAEMON = "false";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };
    preBuild = ''
      patchShebangs node_modules apps/artcraft/node_modules
    '';
    buildPhase = ''
      runHook preBuild
      npm run build --workspace=artcraft
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r apps/artcraft/dist/. "$out/"
      test -s "$out/index.html"
      runHook postInstall
    '';
  };
  desktopItem = makeDesktopItem {
    name = "artcraft";
    desktopName = "ArtCraft";
    exec = "artcraft";
    icon = "artcraft";
    comment = "ArtCraft creative studio";
    categories = ["Graphics"];
  };
in
  rustPlatform.buildRustPackage {
    pname = "artcraft";
    inherit src;
    version = "${version}-unstable-${builtins.substring 0 7 src.rev}";
    cargoLock.lockFile = "${src}/Cargo.lock";
    cargoBuildFlags = ["--package" "artcraft"];
    cargoTestFlags = ["--package" "artcraft"];
    buildFeatures = ["tauri/custom-protocol"];
    nativeBuildInputs =
      [pkg-config gitMinimal cmake perl makeWrapper rustPlatform.bindgenHook]
      ++ lib.optional stdenv.hostPlatform.isLinux wrapGAppsHook3;
    buildInputs =
      [openssl]
      ++ lib.optionals stdenv.hostPlatform.isLinux [gtk3 webkitgtk_4_1 libappindicator-gtk3];
    env.SQLX_OFFLINE = "true";
    preBuild = ''
      mkdir -p frontend/apps/artcraft/dist
      cp -r ${frontend}/. frontend/apps/artcraft/dist/
    '';
    doCheck = true;
    postInstall =
      ''
        mkdir -p "$out/share/doc/artcraft"
        cp LICENSE.md "$out/share/doc/artcraft/LICENSE.md"
      ''
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p "$out/share/icons/hicolor/128x128/apps" "$out/share/applications"
        cp crates/desktop/artcraft/icons/128x128.png "$out/share/icons/hicolor/128x128/apps/artcraft.png"
        cp ${desktopItem}/share/applications/artcraft.desktop "$out/share/applications/"
        gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [xdg-utils]})
      '';
    doInstallCheck = true;
    installCheckPhase = ''
      test -x "$out/bin/artcraft"
      test -s "$out/share/doc/artcraft/LICENSE.md"
    '';
    passthru = {inherit frontend;};
    meta = {
      description = "ArtCraft Tauri creative studio (non-free, source available)";
      homepage = "https://github.com/storytold/artcraft";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      mainProgram = "artcraft";
    };
  }
