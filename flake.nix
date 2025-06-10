{
  description = "NixOS modules and packages for pikvm v3";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          default = kvmd;
          kvmd = pkgs.callPackage ./packages/kvmd.nix { };
        };
      }
    );
}
