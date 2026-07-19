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
  version = "0.2.15";

  src = fetchFromGitHub {
    owner = "yuki-yano";
    repo = "vde-tmux";
    tag = "v${version}";
    hash = "sha256-Bbx1SVxWl9S19SwtBTFUu895MGYvUcUiE4KLy7pRn+A=";
  };

  cargoHash = "sha256-PkbHiwrVmHk0knJld3CMn3taZUBbRvyCd++GpFOYtRE=";

  doCheck = false;

  nativeBuildInputs = [makeWrapper];

  postFixup = ''
    wrapProgram $out/bin/vt --prefix PATH : ${lib.makeBinPath [tmux git lsof less]}
    wrapProgram $out/bin/vde-tmux --prefix PATH : ${lib.makeBinPath [tmux git lsof less]}
  '';

  meta = {
    description = "Show AI coding agent state in the tmux status line and sidebar";
    homepage = "https://github.com/yuki-yano/vde-tmux";
    changelog = "https://github.com/yuki-yano/vde-tmux/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "vt";
  };
}
