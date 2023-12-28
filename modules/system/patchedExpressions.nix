{

  # Patched home manager Nix expression.
  # - Adds configuration for custom configuration and profile paths.
  home-manager = { pkgs, ... }: pkgs.srcOnly rec {
    pname = "home-manager-patched";
    version = "release-23.11";
    src = builtins.fetchTarball {
      url = "https://github.com/nix-community/home-manager/archive/${version}.tar.gz";
      sha256 = "16ab1k33aivqc5ighi95nh28pssbds5glz3bb371gb06qpiydihl";
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
