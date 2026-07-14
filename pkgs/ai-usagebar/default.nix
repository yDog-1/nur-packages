{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "ai-usagebar";
  version = "0.12.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-g/R2MHab6XqZjv6LRi2VGOY+JpfNDVkOpckoE83AG0s=";
  };

  cargoHash = "sha256-O4xCWUkmXT02OCueC98iY9mEu2AIjDwEUSdexBLdkYo=";

  doCheck = false;

  meta = {
    description = "Waybar widget and TUI for AI plan usage";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = lib.licenses.mit;
    mainProgram = "ai-usagebar";
  };
}
