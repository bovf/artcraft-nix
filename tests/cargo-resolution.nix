{
  runCommand,
  rustPlatform,
  src,
  cargoDeps,
  pname,
}:
runCommand "${pname}-cargo-resolution" {
  inherit src cargoDeps;
  nativeBuildInputs = [rustPlatform.rust.cargo rustPlatform.rust.rustc rustPlatform.cargoSetupHook];
} ''
  export HOME="$TMPDIR/home" CARGO_HOME="$TMPDIR/cargo-home"
  mkdir -p "$HOME" "$CARGO_HOME"
  # Exercise the same vendor/source lock check as the real application build.
  unpackPhase
  cd "$sourceRoot"
  patchPhase
  mkdir -p "$out"
  cargo metadata --locked --offline --format-version 1 > "$out/metadata.json"
  cmp Cargo.lock ${src}/Cargo.lock
  cp Cargo.lock "$out/Cargo.lock"
''
