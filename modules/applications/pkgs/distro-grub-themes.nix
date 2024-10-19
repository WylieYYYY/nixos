{ pkgs, fetchzip, ... }:

# Cool GRUB theme for NixOS.

pkgs.srcOnly rec {
  pname = "distro-grub-themes";
  version = "3.3";

  src = fetchzip {
    url = "https://github.com/ahmedmoselhi/distro-grub-themes/releases/download/v${version}/nixos.tar";
    sha256 = "KQAXNK6sWnUVwOvYzVfolYlEtzFobL2wmDvO8iESUYE=";
    stripRoot = false;
  };
}
