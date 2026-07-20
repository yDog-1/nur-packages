{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "ai-usagebar";
  version = "0.13.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-OC24X7kzTVbllyJMSjF9tZJhy2nzFsA6qo/I6tQpl1M=";
  };

  cargoHash = "sha256-bZ6ZBul/BGzLWj8GouJj+OmXBNDPjq5v9T/snwbL4NA=";

  meta = {
    description = "Waybar widget and TUI for AI plan usage";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = lib.licenses.mit;
    mainProgram = "ai-usagebar";
  };
}
