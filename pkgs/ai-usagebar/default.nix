{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "ai-usagebar";
  version = "0.17.2";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-pJJ7FM3f7Evl2XWRcH+TyvU4a4uCYk4hbLJKlOYXESE=";
  };

  cargoHash = "sha256-cTJyq0q8Ekt2j7jcmUnb7F6Si6SpbFlzWqeF31vaciA=";

  meta = {
    description = "Waybar widget and TUI for AI plan usage";
    homepage = "https://github.com/akitaonrails/ai-usagebar";
    license = lib.licenses.mit;
    mainProgram = "ai-usagebar";
  };
}
