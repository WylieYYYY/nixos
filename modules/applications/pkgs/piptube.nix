{ config, lib, pkgs, stdenv, fetchzip, ...}:

# Picture-in-picture streaming client with integrated controls.

stdenv.mkDerivation rec {
  pname = "piptube";
  version = "master";

  buildInputs = with pkgs; [ makeWrapper ];

  dontUnpack = true;

  installPhase = let
    runtimeLibraries = with pkgs; [
      alsa-lib
      ffmpeg
      libGL
      xorg.libXtst
      xorg.libXxf86vm
    ];
  in ''
    mkdir --parent "$out/share/${pname}"
    makeWrapper ${lib.getExe pkgs.jdk} $out/bin/${pname} \
        --add-flags '-jar '${lib.escapeShellArg config.customization.persistence.piptube} \
        --prefix LD_LIBRARY_PATH ':' ${lib.makeLibraryPath runtimeLibraries}
  '';

  meta.mainProgram = pname;
}
