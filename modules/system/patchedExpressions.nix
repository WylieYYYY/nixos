{

  # Patched home manager Nix expression.
  # - Adds configuration for custom configuration and profile paths.
  #   - Lifted from nix-community/home-manager#3339.
  home-manager = { pkgs, fetchFromGitLab, ... }: pkgs.srcOnly rec {
    pname = "home-manager-patched";
    version = "release-23.11";
    src = fetchFromGitLab {
      owner = "nix-community";
      repo = "home-manager";
      rev = version;
      sha256 = "1a2b1y8w7wm6shiawqic88j6sp6z43hq3p3852dgz6jbvj8lq5a1";
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
