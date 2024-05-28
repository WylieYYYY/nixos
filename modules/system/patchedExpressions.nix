{

  # Patched home manager Nix expression.
  # - Adds configuration for custom configuration and profile paths.
  #   - Lifted from nix-community/home-manager#3339.
  home-manager = { pkgs, fetchFromGitHub, ... }: pkgs.srcOnly rec {
    pname = "home-manager-patched";
    version = "569d9284583909f416f00c44fab86f652c8b2c61";
    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "home-manager";
      rev = version;
      sha256 = "k+cLJfU6qDV8EO6HEokLt5boPwWXidi0B0F8KJlG3ug=";
    };
    patches = [ ./../../patches/firefox-path-options.patch ];
  };

  # Patched NUR expressions from Rycee.
  # - Adds addon ID to the package metadata.
  nur-rycee = { pkgs, fetchFromGitLab, ... }: pkgs.srcOnly rec {
    pname = "nur-rycee-patched";
    version = "d83b840e4681823c517995e31566f7d72d13793e";
    src = fetchFromGitLab {
      owner = "rycee";
      repo = "nur-expressions";
      rev = version;
      sha256 = "JpkjDE9R6grXrxzz6q4wR0kVLhn19/O5YrA8woXtx74=";
    };
    patches = [ ./../../patches/nur-firefox-addon-id.patch ];
  };

}
