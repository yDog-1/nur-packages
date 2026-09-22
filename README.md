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

## Automated Updates

Packages updated with `nix-update` must declare the repository-relative source
expression that the tool may modify:

```nix
passthru.updateFile = "pkgs/example/default.nix";
```

`updateFile` is passed to `nix-update --override-filename`, avoiding heuristic
package-file discovery. It must be a repository-relative path to the package's
Nix expression.

Bun packages combine `updateFile` with `passthru.bun2nixUpdate` in one
`passthru` set:

```nix
passthru = {
  updateFile = "pkgs/example/default.nix";
  bun2nixUpdate = {
    sourceRoot = ".";
    sourceLockFile = "bun.lock";
    lockFile = "pkgs/example/bun.lock";
    nixFile = "pkgs/example/bun.nix";
  };
};
```

`sourceRoot` and `sourceLockFile` are relative to the fetched upstream source.
The source directory, its `package.json`, and its lock file must exist before
regeneration. `lockFile` and `nixFile` are repository-relative paths.

Source updates validate the upstream lockfile with Bun, then regenerate
`bun.nix` with the flake-pinned Bun tooling. Updating the `bun2nix` flake input
regenerates every opted-in package from its committed `lockFile` in one pull
request.

The weekly workflow starts from the latest `main`, updates all flake inputs,
then updates every package in lexical order with `nix-update`. Bun dependencies
are regenerated with the flake-pinned `bun2nix` tooling. All changes are grouped
into one pull request, so one failed update prevents publishing a partial set.
No-change runs create no pull request.

The update pull request is created by a repository-scoped GitHub App. Because
the App is distinct from `GITHUB_TOKEN`, the ordinary `pull_request` build runs
normally. GitHub native auto-merge squash-merges the update only after strict
branch protection accepts the required `build` check.

Configure the App with Contents and Pull requests read/write permissions and
Metadata read permission. Store its ID in the `CI_APP_ID` repository variable
and its private key in the `CI_APP_PRIVATE_KEY` repository secret. The token is
created only after update generation and is used only for pull-request creation
and enabling auto-merge; Nix update commands and pull-request builds do not
receive it.

Pull requests use read-only repository and Cachix access. Only trusted pushes
to `main` require `CACHIX_AUTH_TOKEN` and push build results. The repository
assumes `main` requires a strict GitHub Actions `build` check and has squash
merge, auto-merge, and automatic head-branch deletion enabled.

Development and CI update tools are flake-pinned and invoked with
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
