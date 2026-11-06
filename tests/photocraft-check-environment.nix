{
  runCommand,
  rustc,
  cc,
  src,
  testCargo,
}: let
  manifest = builtins.toFile "Cargo.toml" ''
    [package]
    name = "photocraft-check-environment"
    version = "0.1.0"
    edition = "2024"
    [lib]
    path = "check.rs"
    [workspace]
  '';
in
  runCommand "photocraft-check-environment" {
    nativeBuildInputs = [rustc cc testCargo];
  } ''
    export CARGO_HOME="$TMPDIR/cargo-home"
    mkdir -p "$CARGO_HOME"
    cp ${manifest} Cargo.toml
    cp ${./photocraft-check-environment.rs} check.rs
    substituteInPlace check.rs --replace-fail '@memoryDetector@' '${src}/crates/raster/src/memory/system.rs'
    cargo generate-lockfile --offline
    cargo test --offline --frozen
    touch "$out"
  ''
