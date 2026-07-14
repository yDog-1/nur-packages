# yDog NUR Packages

Personal NUR packages for tools that are not available in nixpkgs yet.

## Packages

- `ai-usagebar`

## Flake Usage

```nix
{
  inputs.ydog-nur.url = "github:yDog-1/nur-packages";

  outputs = {nixpkgs, ydog-nur, ...}: {
    # Use ydog-nur.packages.${system}.ai-usagebar directly,
    # or add ydog-nur.overlays.default to nixpkgs overlays.
  };
}
```

## NUR Usage

```nix
{pkgs ? import <nixpkgs> {}}:

let
  ydog = import ./default.nix {inherit pkgs;};
in
  ydog.ai-usagebar
```
