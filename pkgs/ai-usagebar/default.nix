{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "ai-usagebar";
  version = "1.21.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-zhQ0dTy7ta0Vva9Y2njxxcEoeYlyUyLKHDtHTHCiggQ=";
  };

  cargoHash = "sha256-BD7Sp/Eb3FVsEe60/Z5jhvVLGxMKvAy03BqZCdjT4Fo=";

  passthru.updateFile = "pkgs/ai-usagebar/default.nix";

  meta = {
    description = "Waybar widget and TUI for AI plan usage";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = lib.licenses.mit;
    mainProgram = "ai-usagebar";
  };
}
