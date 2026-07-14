{
  description = "Personal NUR packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {inherit system;}));
  in {
    overlays.default = final: prev: {
      ai-usagebar = final.callPackage ./pkgs/ai-usagebar {};
    };

    packages = forAllSystems (pkgs: rec {
      ai-usagebar = pkgs.callPackage ./pkgs/ai-usagebar {};
      default = ai-usagebar;
    });

    checks = forAllSystems (pkgs: {
      inherit (pkgs.callPackage ./default.nix {}) ai-usagebar;
    });
  };
}
