{
  lib,
  bun2nix,
  fetchFromGitHub,
}:
bun2nix.mkDerivation (finalAttrs: {
  pname = "editprompt";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "eetann";
    repo = "editprompt";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mxjjIZHehezx4P1mHO/Rl35P1xL8eeeujk7LVBpEeA4=";
  };

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  module = "src/index.ts";
  bunCompileToBytecode = false;
  doCheck = true;
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/editprompt --version
    $out/bin/editprompt --help
    runHook postInstallCheck
  '';

  passthru = {
    updateFile = "pkgs/editprompt/default.nix";
    bun2nixUpdate = {
      sourceRoot = ".";
      sourceLockFile = "bun.lock";
      lockFile = "pkgs/editprompt/bun.lock";
      nixFile = "pkgs/editprompt/bun.nix";
    };
  };

  meta = {
    description = "Write CLI prompts in your favorite editor";
    homepage = "https://github.com/eetann/editprompt";
    changelog = "https://github.com/eetann/editprompt/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "editprompt";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [fromSource];
  };
})
