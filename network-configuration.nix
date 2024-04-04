{ persist, lib, pkgs, ... }:

# Network and connectivity configurations.
# Parameters:
# - persist: Attribute set of persisting settings.
#   - dns?: A list of DNS server addresses with domain fragments.
#   - hostname?: Host name to be registered.
#   - isolatedOutputRules?: Additional NFTables output rules for isolated applications.
#   - syncthingIds?: Attribute set of device names to Syncthing IDs.
#   - syncthingDir?: Folder to be shared to all devices provided.

{

  networking.hostName = lib.mkIf (persist ? hostname) persist.hostname;

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
  networking.nameservers = lib.mkIf (persist ? dns) persist.dns;
  services.resolved = lib.mkIf (persist ? dns) {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = persist.dns;
    extraConfig = "DNSOverTLS=yes";
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
          ${persist.isolationOutputRules or ""}
        }
      }
    '';
  };

  # Sensible file permission for synching files with service user.
  systemd.services.syncthing.serviceConfig.UMask = "0002";

  # Syncthing with predefined folder shared to all devices.
  services.syncthing = lib.mkIf (persist ? syncthingIds && persist ? syncthingDir) {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    relay.enable = false;
    settings = {
      devices = lib.mkMerge (lib.mapAttrsToList (name: value:
        { "${name}".id = value; }
      ) persist.syncthingIds);
      folders.sync = {
        path = builtins.toString persist.syncthingDir;
        devices = builtins.attrNames persist.syncthingIds;
      };
    };
  };

}
