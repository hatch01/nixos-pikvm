{
  description = "NixOS modules and packages for pikvm v3";

  inputs = {
    nixpkgs.url = "/home/eymeric/code_bidouille/projet/nixpkgs";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:hatch01/nixos-hardware";
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
        };
    };
}
