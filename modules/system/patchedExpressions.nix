{

  # Patched home manager Nix expression.
  home-manager = { pkgs, fetchFromGitHub, ... }: pkgs.srcOnly rec {
    pname = "home-manager-patched";
    version = "c7ffc9727d115e433fd884a62dc164b587ff651d";
  
    stdenv = pkgs.stdenvNoCC;

    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "home-manager";
      rev = version;
      sha256 = "zjO6m5BqxXIyjrnUziAzk4+T4VleqjstNudSqWcpsHI=";
    };
  
    patches = [ /* Patch no longer necessary. */ ];
  };

  # Patched NUR expressions from Rycee.
  # - Adds addon ID to the package metadata.
  nur-rycee = { pkgs, fetchFromGitLab, ... }: pkgs.srcOnly rec {
    pname = "nur-rycee-patched";
    version = "4118c12978f50c094d2e40146d2b1524012a6dd5";
  
    stdenv = pkgs.stdenvNoCC;
  
    src = fetchFromGitLab {
      owner = "rycee";
      repo = "nur-expressions";
      rev = version;
      sha256 = "6cL574j1SSL9At2oZwGarAv9FcwphI9Pd8im+uQ5/bE=";
    };
  
    patches = [ ./../../patches/nur-firefox-addon-id.patch ];
  };

}
