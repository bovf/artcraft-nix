{
  pkgs,
  inputs,
}: let
  craft = name:
    pkgs.callPackage ./craft.nix ({
        pname = name;
        src = inputs.${name};
        fonts = inputs.craft-fonts;
      }
      // pkgs.lib.optionalAttrs (name == "pdfcraft") {
        # nixpkgs Rust 1.98.1/LLVM 21 rejects RTen's AVX512 intrinsic.
        # Keep upstream source intact; use the paired official compiler/std instead.
        rustPlatform = pkgs.makeRustPlatform {
          cargo = pkgs.rust-bin.stable."1.98.1".minimal;
          rustc = pkgs.rust-bin.stable."1.98.1".minimal;
        };
      });
in {
  photocraft = craft "photocraft";
  lightcraft = craft "lightcraft";
  filmcraft = craft "filmcraft";
  pdfcraft = craft "pdfcraft";
  vectorcraft = craft "vectorcraft";
  effectcraft = craft "effectcraft";
  designcraft = craft "designcraft";
  wordcraft = craft "wordcraft";
  cadcraft = craft "cadcraft";
  gridcraft = craft "gridcraft";
  deckcraft = craft "deckcraft";
  soundcraft = craft "soundcraft";
  artcraft = pkgs.callPackage ./artcraft.nix {src = inputs.artcraft;};
}
