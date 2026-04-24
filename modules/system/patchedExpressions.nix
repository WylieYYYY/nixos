{

  # Patched home manager Nix expression.
  home-manager = { pkgs, fetchFromGitHub, ... }: pkgs.srcOnly rec {
    pname = "home-manager-patched";
    version = "82fb7dedaad83e5e279127a38ef410bcfac6d77c";

    stdenv = pkgs.stdenvNoCC;

    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "home-manager";
      rev = version;
      sha256 = "MOU5YdVu4DVwuT5ztXgQpPuRRBjSjUGIdUzOQr9iQOY=";
    };

    patches = [ /* Patch no longer necessary. */ ];
  };

  # Patched impermanence Nix expression.
  # - Adds `homeRelative` option to place files and directories directly in the home directory.
  impermanence = { pkgs, fetchFromGitHub, ... }: pkgs.srcOnly rec {
    pname = "impermanence-patched";
    version = "7b1d382faf603b6d264f58627330f9faa5cba149";

    stdenv = pkgs.stdenvNoCC;

    src = fetchFromGitHub {
      owner = "nix-community";
      repo = "impermanence";
      rev = version;
      sha256 = "03+JxvzmfwRu+5JafM0DLbxgHttOQZkUtDWBmeUkN8Y=";
    };

    patches = [
      (pkgs.fetchpatch {
        url = "https://github.com/nix-community/impermanence/pull/309.patch";
        sha256 = "1lH0vKh99LCAXdX4mOXzSnL7CbajPVs86TnA23kWV58=";
      })
    ];
  };

  # Patched NUR expressions from Rycee.
  nur-rycee = { pkgs, fetchFromGitLab, ... }: pkgs.srcOnly rec {
    pname = "nur-rycee-patched";
    version = "c73146d00a2a01e2ac844ceed9640e0f314a5dda";

    stdenv = pkgs.stdenvNoCC;

    src = fetchFromGitLab {
      owner = "rycee";
      repo = "nur-expressions";
      rev = version;
      sha256 = "cqbRdYEmO8FNoaUtoc6+GLR4EGU1f24cGJiQUPJJmxI=";
    };

    patches = [ /* Patch no longer necessary. */ ];
  };

}
