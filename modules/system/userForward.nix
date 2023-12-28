{ package, mainProgram ? null, user, port ? 4656, lib, pkgs, ... }:

# Creates a shell script that runs a GUI application with sound as another user.
# Parameters:
# - package: Package to get the executable to run.
# - mainProgram: Name of the executable, null if the package has main program metadata.
# - user: Designated user to run the application.
# - port: Port to run Pulseaudio server on, defaults to 4656.

let
  escape = lib.escapeShellArg;
  packageExe = if builtins.isNull mainProgram
               then lib.getExe package
               else lib.getExe' package mainProgram;
  portString = builtins.toString port;
in

pkgs.writeShellScriptBin "${lib.getName package}-forwarded" ''
  ${lib.getExe pkgs.xorg.xhost} +si:localuser:${escape user}
  ${lib.getExe' pkgs.pulseaudio "pactl"} load-module module-native-protocol-tcp port=${portString}
  cd /
  sudo --user ${escape user} PATH=/home/${escape user}/.nix-profile/bin\
      PULSE_SERVER=tcp:127.0.0.1:${portString} ${packageExe} $@
  ${lib.getExe pkgs.xorg.xhost} -si:localuser:${escape user}
  ${lib.getExe' pkgs.pulseaudio "pactl"} unload-module module-native-protocol-tcp
''
