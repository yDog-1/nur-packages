{
  description = "Personal NUR packages";

  nixConfig = {
    extra-substituters = [
      "https://ydog-1-nur.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ydog-1-nur.cachix.org-1:gw4tWFtMdLnDn2k1EMrkgUrheq8/zi8mjPQKto5PyDs="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bun2nix.url = "github:nix-community/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    bun2nix,
    nixpkgs,
    ...
  }: let
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
      editprompt = final.callPackage ./pkgs/editprompt {
        bun2nix = bun2nix.packages.${final.stdenv.hostPlatform.system}.default;
      };
      vde-tmux = final.callPackage ./pkgs/vde-tmux {};
    };

    packages = forAllSystems (pkgs: {
      ai-usagebar = pkgs.callPackage ./pkgs/ai-usagebar {};
      editprompt = pkgs.callPackage ./pkgs/editprompt {
        bun2nix = bun2nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      vde-tmux = pkgs.callPackage ./pkgs/vde-tmux {};
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
          bun
          bun2nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          deadnix
          nil
          nix-update
          pre-commit
          statix
          actionlint
        ];
      };
    });

    checks = forAllSystems (pkgs: {
      ai-usagebar = pkgs.callPackage ./pkgs/ai-usagebar {};
      editprompt = pkgs.callPackage ./pkgs/editprompt {
        bun2nix = bun2nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
      vde-tmux = pkgs.callPackage ./pkgs/vde-tmux {};

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
