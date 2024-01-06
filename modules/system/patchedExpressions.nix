{

  # Patched home manager Nix expression.
  # - Adds configuration for custom configuration and profile paths.
  #   - Lifted from nix-community/home-manager#3339.
  home-manager = { pkgs, fetchFromGitHub, ... }: pkgs.srcOnly rec {
    pname = "home-manager-patched";
    version = "7e398b3d76bc1503171b1364c9d4a07ac06f3851";
    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "home-manager";
      rev = version;
      sha256 = "QRVMkdxLmv+aKGjcgeEg31xtJEIsYq4i1Kbyw5EPS6g=";
    };
    patches = [ ./../../patches/firefox-path-options.patch ];
  };

  # Patched NUR expressions from Rycee.
  # - Adds addon ID to the package metadata.
  nur-rycee = { pkgs, fetchFromGitLab, ... }: pkgs.callPackage (pkgs.srcOnly rec {
    pname = "nur-rycee-patched";
    version = "d83b840e4681823c517995e31566f7d72d13793e";
    src = fetchFromGitLab {
      owner = "rycee";
      repo = "nur-expressions";
      rev = version;
      sha256 = "JpkjDE9R6grXrxzz6q4wR0kVLhn19/O5YrA8woXtx74=";
    };
    patches = [ ./../../patches/nur-firefox-addon-id.patch ];
  }) { };

}
