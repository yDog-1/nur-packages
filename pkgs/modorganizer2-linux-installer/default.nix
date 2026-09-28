{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  cabextract,
  desktop-file-utils,
  fontconfig,
  procps,
  psmisc,
  xdg-utils,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "modorganizer2-linux-installer";
  version = "7.0.0";

  src = fetchurl {
    url = "https://github.com/Furglitch/modorganizer2-linux-installer/releases/download/${finalAttrs.version}/mo2-lint";
    hash = "sha256-bNc1VKVSe9u7zwLlcm0LTaDl/hJXVImd+rWuMp66NBc=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/mo2-lint
    wrapProgram $out/bin/mo2-lint \
      --prefix PATH : ${
      lib.makeBinPath [
        cabextract
        desktop-file-utils
        fontconfig
        procps
        psmisc
        xdg-utils
      ]
    }

    runHook postInstall
  '';

  passthru.updateFile = "pkgs/modorganizer2-linux-installer/default.nix";

  meta = {
    description = "Easy-to-use Mod Organizer 2 installer for Linux";
    homepage = "https://github.com/Furglitch/modorganizer2-linux-installer";
    changelog = "https://github.com/Furglitch/modorganizer2-linux-installer/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    mainProgram = "mo2-lint";
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
  };
})
