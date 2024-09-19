{ config, lib, pkgs, ... }:

# Network and connectivity configurations.

{

  networking.hostName = config.customization.global.network.hostname;

  # Enables Bluetooth service.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # OpenConnect for VPN usage with IWD and randomized MAC.
  networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openconnect ];
    wifi.backend = "iwd";
    wifi.macAddress = "random";
  };

  # DNS using DoT and DNSSEC.
  networking.nameservers = config.customization.global.network.dns;
  services.resolved = lib.mkIf (config.customization.global.network.dns != [ ]) {
    enable = true;
    dnsovertls = "true";
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = config.customization.global.network.dns;
  };

  # Excludes domains that are not compatible with DNSSEC.
  environment.etc."dnssec-trust-anchors.d/default.negative" = lib.mkIf (config.customization.global.network.dnssecExcludes != [ ]) {
    text = lib.concatStringsSep "\n" config.customization.global.network.dnssecExcludes;
  };

  # Firewall with additional entries for offline application isolation.
  networking.firewall.checkReversePath = false;
  networking.nftables = {
    enable = true;
    preCheckRuleset = "sed 's/skuid [^ ]*/skuid nobody/g' -i ruleset.conf";
    ruleset = ''
      table inet filter {
        chain rpfilter {
          type filter hook prerouting priority mangle + 10; policy drop;
          meta nfproto ipv4 udp sport . udp dport { 68 . 67, 67 . 68 } accept comment "DHCPv4 client/server";
          udp dport 51820 accept comment "wireguard";
          udp sport 51820 accept comment "wireguard";
          fib saddr . mark . iif oif exists accept;
        }
        chain input {
          type filter hook input priority filter;
          meta l4proto {tcp,udp} th dport 8384 drop comment "syncthing";
        }
        chain output {
          type filter hook output priority filter;
          ${config.customization.global.isolated.nftOutputRules}
        }
      }
    '';
  };

  # Sensible file permission for synching files with service user.
  systemd.services.syncthing.serviceConfig.UMask = "0002";

  # Syncthing with predefined folder shared to all devices.
  services.syncthing = lib.mkIf (config.customization.global.persistence.syncthing != null) {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    relay.enable = false;
    settings = {
      devices = lib.mkMerge (lib.mapAttrsToList (name: value:
        { "${name}".id = value; }
      ) config.customization.global.network.syncthingIds);
      folders.sync = {
        path = config.customization.global.persistence.syncthing;
        devices = builtins.attrNames config.customization.global.network.syncthingIds;
      };
    };
  };

}
