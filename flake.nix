{
  description = "Reproducible source packages for the Storytold ArtCraft applications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    photocraft = {
      url = "github:storytold/photocraft/v0.20.2";
      flake = false;
    };
    artcraft = {
      url = "github:storytold/artcraft/artcraft-v0.41.0";
      flake = false;
    };
    lightcraft = {
      url = "github:storytold/lightcraft/v0.18.1";
      flake = false;
    };
    filmcraft = {
      url = "github:storytold/filmcraft/v0.17.1";
      flake = false;
    };
    pdfcraft = {
      url = "github:storytold/pdfcraft/v0.18.2";
      flake = false;
    };
    vectorcraft = {
      url = "github:storytold/vectorcraft/v0.21.1";
      flake = false;
    };
    effectcraft = {
      url = "github:storytold/effectcraft/v0.21.1";
      flake = false;
    };
    designcraft = {
      url = "github:storytold/designcraft/v0.17.2";
      flake = false;
    };
    wordcraft = {
      url = "github:storytold/wordcraft/v0.15.2";
      flake = false;
    };
    cadcraft = {
      url = "github:storytold/cadcraft/v0.17.1";
      flake = false;
    };
    gridcraft = {
      url = "github:storytold/gridcraft/v0.16.1";
      flake = false;
    };
    deckcraft = {
      url = "github:storytold/deckcraft/v0.15.1";
      flake = false;
    };
    soundcraft = {
      url = "github:storytold/soundcraft/v0.17.1";
      flake = false;
    };
    figcraft = {
      url = "github:storytold/figcraft/v0.15.1";
      flake = false;
    };
    texturecraft = {
      url = "github:storytold/texturecraft/v0.3.2";
      flake = false;
    };
    materialcraft = {
      url = "github:storytold/materialcraft/v0.1.2";
      flake = false;
    };
    craft-anything = {
      url = "github:storytold/craft-anything/v0.3.0";
      flake = false;
    };
    craft-fonts = {
      url = "github:storytold/craft-fonts";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    mkPackages = pkgs: import ./packages {inherit pkgs inputs;};
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [inputs.rust-overlay.overlays.default];
        # Selecting the explicitly named ArtCraft package opts into its non-free license.
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) ["artcraft" "artcraft-frontend"];
      };
  in {
    overlays.default = nixpkgs.lib.composeManyExtensions [
      inputs.rust-overlay.overlays.default
      (final: _prev: mkPackages final)
    ];

    packages = forAllSystems (system: let
      packages = mkPackages (pkgsFor system);
    in
      packages // {default = packages.photocraft;});

    apps = forAllSystems (system:
      nixpkgs.lib.mapAttrs (_: package: {
        type = "app";
        program = nixpkgs.lib.getExe package;
        meta.description = package.meta.description;
      })
      self.packages.${system});

    checks = forAllSystems (system: let
      pkgs = pkgsFor system;
      packages = self.packages.${system};
    in
      {
        # Builds execute the packages' unit/install checks. ArtCraft stays opt-in.
        source-contract = pkgs.runCommand "artcraft-source-contract" {nativeBuildInputs = [pkgs.python3];} ''
          python3 ${./tests/source-contract.py} ${./.} ${inputs.craft-fonts} \
            ${nixpkgs.lib.escapeShellArgs (map (name: "${name}=${inputs.${name}}") (builtins.attrNames (mkPackages pkgs)))}
          touch "$out"
        '';
        cargo-resolution = pkgs.linkFarm "craft-cargo-resolution" (map (name: {
          inherit name;
          path = packages.${name}.tests.cargo-resolution;
        }) (builtins.filter (name: name != "artcraft" && name != "default") (builtins.attrNames packages)));
      }
      // nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        photocraft-check-environment = packages.photocraft.tests.check-environment;
      }
      // nixpkgs.lib.filterAttrs (name: _: name != "artcraft" && name != "default") packages);

    formatter = forAllSystems (system: (pkgsFor system).alejandra);
    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = [pkgs.alejandra pkgs.git pkgs.jq pkgs.python3 pkgs.nix];
        shellHook = ''
          echo 'Artcraft Nix: nix build .#photocraft | nix run .#photocraft | nix flake check'
          echo 'Update a source: nix flake update photocraft; update toolchain: nix flake update nixpkgs'
        '';
      };
    });
  };
}
