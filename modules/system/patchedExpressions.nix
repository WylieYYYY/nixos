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
    version = "4118c12978f50c094d2e40146d2b1524012a6dd5";
    src = fetchFromGitLab {
      owner = "rycee";
      repo = "nur-expressions";
      rev = version;
      sha256 = "6cL574j1SSL9At2oZwGarAv9FcwphI9Pd8im+uQ5/bE=";
    };
    patches = [ ./../../patches/nur-firefox-addon-id.patch ];
  };

}
