# NixOS Configuration
This is the collection of configuration files for my personal NixOS system.

### Screenshots
Current configuration without modification running under QEMU.  
![Example Neofetch Screenshot](screenshot-fetch.png "Example Neofetch Screenshot")

### Features:
- Impermanence system managed by Home Manager;
- Customization via `persist.nix` which separates private and public configuration;
- Multiuser setup for isolating applications;
- Custom patches to applications for quality of life improvements;

### Setup
1. Download NixOS installation medium from https://nixos.org.
2. Mount a tmpfs on `/mnt` and a persistent volume on `/mnt/nix`.
3. Create directory `/mnt/nix/persist/boot/efi` and mount the EFI partition there.
4. Connect to the Internet using `wpa_supplicant`.
5. Create directory `/mnt/nix/persist/etc` and clone this repository into it.
6. Run `nixos-generate-config --root /mnt` to generate the hardware configurations.
7. Create and paste in the following in `/mnt/nix/persist/etc/nixos/persist.nix`,
   replacing ``<output from `mkpasswd`>``:
   ```nix
     { ... }:

     {
       customization.global.persistence = {
         boot.efi = /nix/persist/boot/efi;
         boot.grub = /nix/persist/boot;
         machineState = /nix/persist;
         root = /nix/persist;
       };
       customization.users.user = {
         hashedPassword = "<output from `mkpasswd`>";
       };
     }
   ```
8. Adjust `graphics-configuration.nix` so that it fits the target machine.
9. Run `cd /mnt && nixos-install` to install.
