{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  tmux,
  git,
  lsof,
  less,
}:
rustPlatform.buildRustPackage rec {
  pname = "vde-tmux";
  version = "0.3.7";

  src = fetchFromGitHub {
    owner = "yuki-yano";
    repo = "vde-tmux";
    tag = "v${version}";
    hash = "sha256-ZDrKIRoUNUgorulxXHunqb68D4L3NWSU1xGB74+kjV8=";
  };

  cargoHash = "sha256-Tex1jINKLe8jrrZyi/xRuXyFBg/ZqnZmA18skH8xTaA=";

  doCheck = false;

  nativeBuildInputs = [makeWrapper];

  postFixup = ''
    wrapProgram $out/bin/vt --prefix PATH : ${lib.makeBinPath [tmux git lsof less]}
    wrapProgram $out/bin/vde-tmux --prefix PATH : ${lib.makeBinPath [tmux git lsof less]}
  '';

  passthru.updateFile = "pkgs/vde-tmux/default.nix";

  meta = {
    description = "Show AI coding agent state in the tmux status line and sidebar";
    homepage = "https://github.com/yuki-yano/vde-tmux";
    changelog = "https://github.com/yuki-yano/vde-tmux/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "vt";
  };
}
