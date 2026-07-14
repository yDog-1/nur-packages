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
    overlays.default = final: _prev: {
      ai-usagebar = final.callPackage ./pkgs/ai-usagebar {};
    };

    packages = forAllSystems (pkgs: rec {
      ai-usagebar = pkgs.callPackage ./pkgs/ai-usagebar {};
      default = ai-usagebar;
    });

    formatter = forAllSystems (pkgs:
      pkgs.writeShellApplication {
        name = "nixfmt";
        runtimeInputs = [pkgs.alejandra];
        text = ''
          if [ "$#" -eq 0 ]; then
            set -- .
          fi

          exec alejandra "$@"
        '';
      });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          deadnix
          nil
          statix
        ];
      };
    });

    checks = forAllSystems (pkgs: {
      inherit (pkgs.callPackage ./default.nix {}) ai-usagebar;

      format = pkgs.runCommand "check-format" {nativeBuildInputs = [pkgs.alejandra];} ''
        alejandra --check ${./.}
        touch $out
      '';

      deadnix = pkgs.runCommand "check-deadnix" {nativeBuildInputs = [pkgs.deadnix];} ''
        deadnix --fail ${./.}
        touch $out
      '';

      statix = pkgs.runCommand "check-statix" {nativeBuildInputs = [pkgs.statix];} ''
        statix check ${./.}
        touch $out
      '';
    });
  };
}
