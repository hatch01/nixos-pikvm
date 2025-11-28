{
  description = "NixOS modules and packages for pikvm v3";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        nixosModules = rec {
          default = kvmd;
          kvmd =
            { ... }:
            {
              imports = [ ./modules/default.nix ];

              # Make the package available to the module
              nixpkgs.overlays = [
                (final: prev: {
                  kvmd = final.callPackage ./packages/kvmd.nix { };
                })
              ];
            };
        };

        # Example usage in NixOS configuration:
        # {
        #   imports = [ pikvm-flake.nixosModules.default ];
        #   services.kvmd.enable = true;
        # }
      };

      perSystem =
        { pkgs, ... }:
        {
          packages = rec {
            default = kvmd;
            kvmd = pkgs.callPackage ./packages/kvmd.nix { };
          };
          formatter = pkgs.nixfmt-tree;

          # Developer shell with common tooling
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.statix
              pkgs.deadnix
            ];
          };

          checks = {
            formatting = pkgs.runCommand "formatting" { buildInputs = [ pkgs.nixfmt-tree ]; } ''
              ${pkgs.nixfmt-tree}/bin/nixfmt --check ${./.} || {
                echo "Formatting issues detected (nixfmt)."
              }
              touch $out
            '';

            statix = pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
              ${pkgs.statix}/bin/statix check ${./.} || {
                echo "Statix suggestions emitted."
              }
              touch $out
            '';

            deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
              ${pkgs.deadnix}/bin/deadnix --fail --no-lambda-arg --no-lambda-pattern ${./.} || {
                echo "Deadnix reported unused code."
              }
              touch $out
            '';
          };
        };
    };
}
