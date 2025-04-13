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
    version = "60f50437003e17137a871686dfa3fc4291edd5e5";

    stdenv = pkgs.stdenvNoCC;

    src = fetchFromGitLab {
      owner = "rycee";
      repo = "nur-expressions";
      rev = version;
      sha256 = "6PNBLb/YXVlx2YaDqtljQYpk2MlE0VRjGXcEg1RN/qw=";
    };

    patches = [ ./../../patches/nur-firefox-addon-id.patch ];
  };

}
