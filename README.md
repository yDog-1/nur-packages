# yDog NUR Packages

Personal NUR packages for tools that are not available in nixpkgs yet.

## Packages

- `ai-usagebar`
- `editprompt`
- `vde-tmux`

The repository is flake-only. Use packages by name, for example
`ydog-nur.packages.${system}.editprompt`.

## Flake Usage

```nix
{
  inputs.ydog-nur.url = "github:yDog-1/nur-packages";

  outputs = {nixpkgs, ydog-nur, ...}: {
    # Use a named package directly, or add ydog-nur.overlays.default
    # to nixpkgs overlays.
  };
}
```

## Bun Package Updates

Bun packages opt in to the shared update workflow with
`passthru.bun2nixUpdate`:

```nix
passthru.bun2nixUpdate = {
  sourceRoot = ".";
  sourceLockFile = "bun.lock";
  lockFile = "pkgs/example/bun.lock";
  nixFile = "pkgs/example/bun.nix";
};
```

All four values must be non-empty relative paths. `sourceRoot = "."` is
permitted. Absolute paths, `..` path components, and repeated `//` are
rejected. `sourceRoot` and `sourceLockFile` are relative to the fetched
upstream source and must identify its `package.json` and lockfile.
`lockFile` and `nixFile` are relative to this repository.

Source updates validate the upstream lockfile with Bun, then regenerate
`bun.nix` with the flake-pinned Bun tooling. Updating the `bun2nix` flake input
regenerates every opted-in package from its committed `lockFile` in one pull
request. Development and CI update tools are flake-pinned and invoked with
`nix develop --command`. `nix flake check --all-systems --no-build` evaluates
all configured systems without claiming that their packages were built.

## Binary Cache

Build results are available from Cachix:

```console
cachix use ydog-1-nur
```

Flake users are prompted to trust the configured binary cache automatically.

To configure the cache manually, add this to your flake:

```nix
{
  nixConfig = {
    extra-substituters = ["https://ydog-1-nur.cachix.org"];
    extra-trusted-public-keys = ["ydog-1-nur.cachix.org-1:gw4tWFtMdLnDn2k1EMrkgUrheq8/zi8mjPQKto5PyDs="];
  };
}
```
