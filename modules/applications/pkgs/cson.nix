{ pkgs, buildNpmPackage, fetchFromGitHub, ... }:

# CoffeeScript-Object-Notation utilities.

buildNpmPackage {
  pname = "cson";
  version = "8.4.0";

  src = fetchFromGitHub {
    owner = "bevry";
    repo = "cson";
    rev = "v8.4.0";
    sha256 = "+JGkxoQDWJllNcpP2WgD3GhFvAJWaQrAsJKUNCFX7OE=";
  };

  npmBuildScript = "our:compile";
  npmDepsHash = "sha256-dc1mOLRy1ajttaH3GdDtqaVnkajZPYJ7ZX1vvM5dSBw=";
}
