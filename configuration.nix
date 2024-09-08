args@{ config, lib, pkgs, ... }:

# Main configurations.

let
  # Attribute set of persisting settings.
  #   - bootPath?: Path to grub boot directory.
  #   - efiSysMountPoint?: Path to the EFI mount point, typically under `bootPath` and named `efi`.
  #   - dmBackgroundPath?: Path to a background file for the display manager.
  #   - dns?: A list of DNS server addresses with domain fragments.
  #   - dnssecExcludes?: A list of domains to be excluded from DNSSEC.
  #   - hostname?: Host name to be registered.
  #   - isolatedEntries?: Function yielding an attribute set of user names to isolated menu entries.
  #     - expects: { lib, pkgs, ... }:
  #         { <username> = { name = <application name>; value = <command>; }, ... }
  #   - isolatedOutputRules?: Additional NFTables output rules for isolated applications.
  #   - machineStateRoot?: Persistence directory for machine-specific states such as authentication.
  #   - persistRoot?: Persistence directory for static system user data.
  #   - syncthingIds?: Attribute set of device names to Syncthing IDs.
  #   - syncthingDir?: Folder to be shared to all devices provided.
  #   - swapDevicePartUuid?: Swap partition's UUID for encryption.
  #   - users?: Attribute set of main usernames to user specific configurations.
  #     - <username>?: The username.
  #       - hashedPassword: Hashed password in the shadow format.
  #       - homeNixPath: Path to the user's `home.nix` configuration file.
  #   - ...?: Additional list of options found in `user/home.nix`.
  persist = import ./persist.nix;

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
    (import ./network-configuration.nix (args // { inherit persist; }))
    (import ./user-configuration.nix (args // { inherit persist impermanence-repo; }))
    ./modules/overlay.nix
  ];

  # Disables graphical authentication so that autotype can be used.
  programs.ssh.enableAskPassword = false;

  boot.loader = lib.mkIf (persist ? bootPath && persist ? efiSysMountPoint) {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = builtins.toString persist.efiSysMountPoint;
    };
    grub = {
      efiSupport = true;
      useOSProber = true;

      mirroredBoots = [{
        devices = [ "nodev" ];
        path = builtins.toString persist.bootPath;
        efiSysMountPoint = builtins.toString persist.efiSysMountPoint;
      }];

      theme = pkgs.callPackage ./modules/applications/pkgs/distro-grub-themes.nix { };
      splashImage = null;
    };
  };

  # Specifies swap device to be encrypted.
  swapDevices = lib.mkIf (persist ? swapDevicePartUuid) [{
    device = "/dev/disk/by-partuuid/${persist.swapDevicePartUuid}";
    randomEncryption.enable = true;
  }];

  # Performance softwares.
  services.earlyoom.enable = true;
  services.tlp.enable = true;

  environment.persistence = lib.mkMerge [
    # Persistence for static system user data.
    (lib.mkIf (persist ? persistRoot) {
      "${builtins.toString persist.persistRoot}" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/var/lib/AccountsService/icons"
        ];
      };
    })
    # Persistence for machine-specific states such as authentication.
    (lib.mkIf (persist ? machineStateRoot) {
      "${builtins.toString persist.machineStateRoot}" = {
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
    '' + lib.optionalString (persist ? dmBackgroundPath) ''
      background=${builtins.toString persist.dmBackgroundPath}
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
