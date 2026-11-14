{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  sdl3,
  fontconfig,
  freetype,
  neovim,
}:
buildGoModule rec {
  pname = "ng";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "Shougo";
    repo = "ng";
    tag = "v${version}";
    hash = "sha256-b+T96sYfTWtXET4uvwTLYo23YFvTi34Otllg7Lf8l8E=";
  };

  vendorHash = null;
  subPackages = ["cmd/ng"];
  ldflags = ["-X main.version=${version}"];

  nativeBuildInputs = [pkg-config makeWrapper];
  buildInputs = [sdl3 fontconfig freetype];

  postInstall = ''
    install -Dm644 assets/ng.desktop $out/share/applications/ng.desktop
    cp -r assets/icons $out/share/icons
    wrapProgram $out/bin/ng --suffix PATH : ${lib.makeBinPath [neovim]}
  '';

  passthru.updateFile = "pkgs/ng/default.nix";

  meta = {
    description = "Minimal Neovim GUI client";
    homepage = "https://github.com/Shougo/ng";
    changelog = "https://github.com/Shougo/ng/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "ng";
  };
}
