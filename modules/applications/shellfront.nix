{ pkgs, stdenv, fetchFromGitLab, ... }:

# Simple frontend for terminal applications and Linux shell scripts.

stdenv.mkDerivation rec {
  pname = "shellfront";
  version = "05b5c82a5fa2639ab30d314ef62b79caae1ca398";

  nativeBuildInputs = with pkgs; [ autoreconfHook pkg-config ];
  buildInputs = with pkgs; [ gtk3 vte ];
  src = fetchFromGitLab {
    owner = "WylieYYYY";
    repo = pname;
    rev = version;
    sha256 = "jyxO9e8QqTUikt6EriE270Kb8/NOVfeZ1zuqNW/v3D8=";
  };

  patches = [ ./../../patches/shellfront.patch ];

  buildPhase = ''
    NIX_CFLAGS_COMPILE="$(pkg-config --cflags gtk+-3.0 vte-2.91) $NIX_CFLAGS_COMPILE"
    make
  '';

  meta.mainProgram = pname;
}
