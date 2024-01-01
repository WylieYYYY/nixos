{ command, user, port ? 4656, lib, pkgs, ... }:

# Creates a shell script that runs a GUI application with sound as another user.
# Parameters:
# - command: Command to run as the user to launch the application.
# - user: Designated user to run the application.
# - port: Port to run Pulseaudio server on, defaults to 4656.
# Returns: Store path of the created shell script.

let
  escape = lib.escapeShellArg;
  portString = builtins.toString port;
in

pkgs.writeShellScriptBin "${user}-forwarded" ''
  ${lib.getExe pkgs.xorg.xhost} +si:localuser:${escape user}
  ${lib.getExe' pkgs.pulseaudio "pactl"} load-module module-native-protocol-tcp port=${portString}
  cd /
  sudo --user ${escape user} PATH=/home/${escape user}/.nix-profile/bin\
      PULSE_SERVER=tcp:127.0.0.1:${portString} ${command} $@
  ${lib.getExe pkgs.xorg.xhost} -si:localuser:${escape user}
  ${lib.getExe' pkgs.pulseaudio "pactl"} unload-module module-native-protocol-tcp
''
