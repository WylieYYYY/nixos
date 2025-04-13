{ pkgs, stdenv, fetchFromGitHub, ... }:

# Monospace that is double-width for CJK characters.

stdenv.mkDerivation rec {
  pname = "noto-cjk-mono";
  version = "2.004";

  src = fetchFromGitHub {
    owner = "googlefonts";
    repo = "noto-cjk";
    rev = "Sans${version}";
    sha256 = "bq2IedO5JfMP5V423Zv0ofR2Y8w43VgIYLeZVpx6UAE=";
    sparseCheckout = [ "Sans/Mono" ];
  };

  installPhase = ''
    install --mode 444 -D --target-directory $out/share/fonts/opentype/noto-cjk \
        Sans/Mono/*.otf
  '';
}
