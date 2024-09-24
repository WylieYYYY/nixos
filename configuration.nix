args@{ config, lib, pkgs, ... }:

# Main configurations.

let
  home-manager-repo = (import <nixpkgs> { }).callPackage
      (import ./modules/system/patchedExpressions.nix).home-manager { };
  impermanence-repo = builtins.fetchTarball {
    url = "https://github.com/nix-community/impermanence/archive/123e94200f63952639492796b8878e588a4a2851.tar.gz";
    sha256 = "07c146m0i47a0f9gajhh8h9l5ndy5744dmvbbqhvm28pnl319qmd";
  };
in

{

  # Neccessary for Nix REPL and package search.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  imports = [
    "${impermanence-repo}/nixos.nix"
    ./hardware-configuration.nix
    ./graphics-configuration.nix
    ./network-configuration.nix
    (import ./user-configuration.nix (args // { inherit home-manager-repo impermanence-repo; }))
    (import ./customization.nix (args // { inherit home-manager-repo impermanence-repo; }))
    ./modules/overlay.nix
    ./persist.nix
  ];

  # Disables graphical authentication so that autotype can be used.
  programs.ssh.enableAskPassword = false;

  boot.loader = let
    persistence = config.customization.global.persistence.boot;
  in lib.mkIf (persistence.grub != null && persistence.efi != null) {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = persistence.efi;
    };
    grub = {
      default = "saved";
      efiSupport = true;
      useOSProber = true;

      mirroredBoots = [{
        devices = [ "nodev" ];
        path = persistence.grub;
        efiSysMountPoint = persistence.efi;
      }];

      extraEntries = ''
        menuentry 'UEFI Firmware Settings' --class 'efi' {
          fwsetup
        }
      '';

      theme = pkgs.distro-grub-themes;
      splashImage = null;
    };
  };

  # Specifies swap device to be encrypted.
  swapDevices = lib.mkIf (config.customization.global.swapDevicePartUuid != null) [{
    device = "/dev/disk/by-partuuid/${config.customization.global.swapDevicePartUuid}";
    randomEncryption.enable = true;
  }];

  # Performance softwares.
  services.earlyoom.enable = true;
  services.tlp.enable = true;

  environment.persistence = lib.mkMerge [
    # Persistence for static system user data.
    (lib.mkIf (config.customization.global.persistence.root != null) {
      "${config.customization.global.persistence.root}" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/var/lib/AccountsService/icons"
        ];
      };
    })
    # Persistence for machine-specific states such as authentication.
    (lib.mkIf (config.customization.global.persistence.machineState != null) {
      "${config.customization.global.persistence.machineState}" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/var/lib/bluetooth"
          "/var/lib/iwd"
          "/var/lib/nixos"
          "/var/lib/syncthing"
          "/var/lib/systemd/coredump"
          "/var/log"
        ];
        files = [ "/etc/machine-id" ];
      };
    })
  ];

  time.timeZone = "Europe/London";
  services.xserver.xkb.layout = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = [ pkgs.ibus-engines.rime ];
  };

  programs.dconf.enable = true;

  services.logind.lidSwitch = "ignore";

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.greeters.gtk = {
    enable = true;
    theme = {
      package = pkgs.arc-theme;
      name = "Arc-Dark";
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Amber";
    };
    clock-format = "%Y-%m-%d %H:%M.%S";
    indicators = [ "~host" "~spacer" "~clock" "~spacer" "~power" ];
    extraConfig = ''
      position=10%,start 50%,center
    '' + lib.optionalString (config.customization.global.persistence.wallpaper != null) ''
      background=${config.customization.global.persistence.wallpaper}
    '';
  };

  # Allows custom window manager.
  services.xserver.desktopManager.session = [{
    name = "home-manager";
    start = ''
      ${pkgs.runtimeShell} $HOME/.xsession &
      waitPID=$!
    '';
  }];

  fonts = {
    packages = with pkgs; [
      noto-cjk-mono
      noto-fonts
      fira-code
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Fira Code" ];
    };
    fontconfig.subpixel.rgba = "none";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Minimal set of system applications.
  environment.defaultPackages = with pkgs; lib.mkForce [ ];
  environment.systemPackages = with pkgs; [
    htop
    ntfsprogs
    vim
  ];

  # Rootless Docker for development.
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    daemon.settings.dns = builtins.map (server:
      builtins.elemAt (builtins.split "#" server) 0
    ) config.networking.nameservers;
  };

  system.stateVersion = "23.05";

}
