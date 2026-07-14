{pkgs ? import <nixpkgs> {}}: {
  ai-usagebar = pkgs.callPackage ./pkgs/ai-usagebar {};
}
