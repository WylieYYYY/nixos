{ config, lib, pkgs, stdenv, ...}:

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

      libvlc
    ];
    gsettingsSchemas = builtins.map (pkg: "${pkg}/share/gsettings-schemas/${pkg.name}") [
      pkgs.gsettings-desktop-schemas
      pkgs.gtk3
    ];
  in ''
    mkdir --parent "$out/share/${pname}"
    makeWrapper ${lib.getExe pkgs.jdk} $out/bin/${pname} \
        --add-flags '-jar '${lib.escapeShellArg config.customization.persistence.piptube} \
        --set LD_LIBRARY_PATH ${lib.makeLibraryPath runtimeLibraries} \
        --set XDG_DATA_DIRS ${lib.concatStringsSep ":" gsettingsSchemas}
  '';

  meta.mainProgram = pname;
}
