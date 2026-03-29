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
