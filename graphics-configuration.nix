{ config, lib, ... }:

# Basic Nvidia Optimus setup with DPI fix.

{

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "nvidia-settings" "nvidia-x11" ];

  # Adds CUDA package binary caches.
  customization.global.trustedPublicKeys = [
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  customization.global.trustedSubstituters = [
    "https://cuda-maintainers.cachix.org"
    "https://nix-community.cachix.org"
  ];

  # Enables module for CUDA compute.
  boot.kernelModules = [ "nvidia_uvm" ];

  services.xserver.videoDrivers = [ "modesetting" "intel" "nvidia" ];
  services.xserver.dpi = 96;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  hardware.opentabletdriver.enable = true;

}
