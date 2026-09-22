# GitHub Actions CI/CD Specification

## Status

- Target branch: `fix/gha-ci-cd`
- Authentication: use a repository-scoped GitHub App for update pull requests
- Update granularity: one aggregate dependency-update pull request
- Cache policy: pull requests are read-only; only pushes to `main` push to Cachix
- Merge policy: GitHub native auto-merge guarded by strict branch protection

## Design Principles

The repository SHOULD delegate generic behavior to maintained tools rather than
reimplementing it in workflow shell code:

- Nix updates flake inputs with `nix flake update`;
- `Mic92/nix-update` updates package versions and fixed-output hashes;
- `nix-community/bun2nix` regenerates Bun dependency expressions;
- `peter-evans/create-pull-request` creates and refreshes the update pull request;
- GitHub branch protection and native auto-merge decide when it may merge;
- Cachix actions configure read-only and write-enabled cache access.

Repository code MUST implement only repository-specific update orchestration and
Bun regeneration that these tools cannot provide directly.

## Trust Model

- Normal pull requests, including automated update pull requests, are untrusted.
  They receive read-only repository permissions and read-only Cachix access.
- A push to `main` is trusted and requires `CACHIX_AUTH_TOKEN` to push build
  results.
- The scheduled update generator is trusted. It checks out `main`, runs only
  tools pinned by the repository flake or full action commit SHAs, and may use a
  short-lived GitHub App installation token to create a pull request.
- The GitHub App token MUST NOT be exposed to commands that evaluate or build
  generated pull request code.
- GitHub branch protection, not custom workflow code, is the authority for
  required checks, up-to-date status, and merge eligibility.

All third-party actions MUST be pinned by full commit SHA with a comment naming
the full known release version.

## 1. Shared Build CI

`.github/workflows/build.yml` MUST run for pull requests and pushes to `main`.
It MUST retain one job whose job ID and check name are `build`.

The build job MUST:

- use read-only repository permissions;
- configure Cachix read-only for every pull request;
- require `CACHIX_AUTH_TOKEN` and push results for `main` pushes;
- fail before checkout if a `main` build has no cache token;
- evaluate flake checks for all configured systems without building them;
- run native-system flake checks;
- discover and build every `x86_64-linux` package;
- fail if no package is discovered;
- use `--print-build-logs` and `--keep-going` where supported;
- use `--no-link` for explicit package builds;
- use `--no-update-lock-file` for commands that evaluate the flake.

The build workflow MUST NOT have a privileged automated-update mode. Automated
updates use the same ordinary pull-request CI as every other pull request.

## 2. GitHub App

The update workflow MUST create an installation token with
`actions/create-github-app-token` from:

- repository variable `CI_APP_ID`;
- repository secret `CI_APP_PRIVATE_KEY`.

The App MUST be installed only where needed and have no more than:

- Contents: read and write;
- Pull requests: read and write;
- Metadata: read.

The token MAY be passed only to pull-request creation and native auto-merge
commands. Checkout MUST use the read-only `GITHUB_TOKEN` and set
`persist-credentials: false`. The App token MUST be created only after Nix
update generation has completed.

## 3. Aggregate Dependency Update

`.github/workflows/update.yml` MUST run on a weekly schedule and manual dispatch.
Only one update run may execute at a time.

One run MUST start from the latest `main` and perform, in order:

1. update all flake inputs with `nix flake update`;
2. update every eligible package in lexical order with `nix-update`;
3. regenerate Bun dependency files for each Bun package after its source update;
4. create or refresh one pull request containing all resulting changes;
5. enable native squash auto-merge for the exact generated head revision.

A no-change run MUST create no pull request and succeed.

Update generation MUST NOT run package builds. The normal pull-request `build`
check is the single source of build verification.

## 4. Package Metadata

Every package eligible for `nix-update` MUST expose:

```nix
passthru.updateFile = "pkgs/example/default.nix";
```

The updater MUST pass this value to `nix-update --override-filename` so package
file discovery is declarative and deterministic.

Bun packages MUST additionally expose:

```nix
passthru.bun2nixUpdate = {
  sourceRoot = ".";
  sourceLockFile = "bun.lock";
  lockFile = "pkgs/example/bun.lock";
  nixFile = "pkgs/example/bun.nix";
};
```

For packages with both attributes, they MUST be members of one `passthru` set.
Repository paths MUST be relative to the repository root. Source paths are
relative to the fetched upstream source, with `sourceRoot = "."` allowed.

## 5. Repository Update Script

The repository MAY contain one standalone update script. Its responsibilities
are limited to:

- invoking the pinned external update tools in the required order;
- reading package update metadata from the flake;
- verifying required Bun source files exist;
- copying the upstream Bun lock file into the repository;
- invoking `bun install --frozen-lockfile --ignore-scripts`, `bun2nix`,
  `deadnix`, and the formatter.

It MUST use strict shell mode and pass ShellCheck. It MUST NOT call the GitHub
API, handle credentials, create checks, or decide merge eligibility.

## 6. Pull Request and Merge

`peter-evans/create-pull-request` MUST create or refresh a stable update branch
using the GitHub App token. The workflow MUST use the returned pull request
number and head SHA.

After pull-request creation, the workflow MUST request GitHub native auto-merge
with:

- squash merge;
- expected-head matching where supported.

Merged head branches MUST be removed by the repository's native
"Automatically delete head branches" setting.

The workflow MUST NOT publish a synthetic `build` check. The required `build`
check MUST come from the normal `pull_request` run of `build.yml`.

## 7. Repository Settings

The implementation relies on these settings:

- default branch is `main`;
- `main` requires the GitHub Actions `build` check;
- the required check is strict, so branches must be current before merge;
- squash merge and auto-merge are enabled;
- automatically deleting head branches is enabled;
- GitHub Actions may create pull requests and repository contents;
- the update GitHub App is installed with the documented permissions.

These settings MUST be verified during live acceptance. The workflow MUST NOT
add a bypass around failed branch protection or required checks.

## 8. Dependabot

Dependabot pull requests SHOULD use GitHub's official
`dependabot/fetch-metadata` action and native auto-merge. A
`pull_request_target` workflow MUST NOT check out or execute pull-request code.
Branch protection remains responsible for waiting for the normal `build` check.

## 9. Documentation

`README.md` MUST document:

- package and Bun update metadata;
- the aggregate update behavior;
- the GitHub App variables, secret, and permissions;
- normal pull-request and `main` cache behavior;
- native auto-merge and branch-protection assumptions.

## Local Acceptance

The following MUST succeed:

```console
actionlint .github/workflows/*.yml
git diff --check
nix flake check --all-systems --no-build --print-build-logs --no-update-lock-file
nix flake check --print-build-logs --no-update-lock-file
```

The standalone update script MUST pass ShellCheck. All discovered
`x86_64-linux` packages MUST build with `--no-link`, without leaving output
symlinks or lock-file changes.

## Live Acceptance

Before the pipeline is considered operationally complete, verify on GitHub:

1. the App-created pull request triggers the normal `pull_request` build;
2. the pull-request build has read-only Cachix access;
3. the required `build` check is attached by GitHub Actions;
4. failed builds do not merge;
5. a stale branch does not merge under strict protection;
6. a successful update is squash-merged and the repository deletes its branch;
7. the resulting `main` push requires the Cachix token and pushes results;
8. a no-change update creates no pull request;
9. the App token is absent from all Nix update and pull-request build steps.
