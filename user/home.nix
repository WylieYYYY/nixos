args@{ persist, username, config, lib, pkgs, ... }:

# Main user's `home.nix` for home manager.
# Parameters:
# - persist: Attribute set of persisting settings.
#   - allowedUnfreePackages?: Some unfree package names to allow and isolate.
#   - bluemanNoNotification?: whether to suppress Blueman notifications (defaults to true).
#   - browserPersistPath?: Persisting directory for browser.
#     - expects: extensions.json, extension-settings.json
#   - containerSuffixes?: Attribute set of container names to their suffixes.
#     - Work?: Suffixes for the work container.
#   - direnvPersistPath?: Persisting directory for direnv.
#   - gitUserEmail?: Default email associated with Git.
#   - gitUserName?: Default user name associated with Git.
#   - hostname?: Display name for the top-left corner of the desktop.
#   - isolatedEntries?: Function yielding an attribute set of user names to isolated menu entries.
#     - expects: { lib, pkgs, ... }:
#         { <username> = { name = <application name>; value = <command>; }, ... }
#   - kdbxPath?: Path to the Keepass database for KeepassXC and Keepmenu.
#   - mouseAllowedDomains?: Domains that are excluded from Tridactyl's no mouse mode.
#   - useCubicleExtension?: Whether the browser persisting directory has a build of Cubicle to link.
#   - users?: Attribute set of main usernames to user specific configurations.
#     - <username>?: The username.
#       - persistence?: Attribute set to be passed to the impermanence module.
#   - wallpaperPath?: Path to a wallpaper file for Nitrogen.
# - username: Username of the main user.

{

  home.username = username;
  home.homeDirectory = "/home/${username}";

  imports = [
    ./../modules/overlay.nix
    (import ./desktop.nix (args // { inherit persist; }))
    (import ./annoyance.nix (args // { inherit persist; }))
  ];

  home.persistence = lib.mkIf (persist.users."${username}" ? persistence)
      persist.users."${username}".persistence;

  programs.autorandr = {
    enable = true;
    profiles = lib.mkIf (persist ? autorandrProfiles) (persist.autorandrProfiles args);
    hooks.postswitch = {
      "change-brightness" = "${lib.getExe pkgs.brightnessctl} set 20%";
      "change-warmth" = "${lib.getExe pkgs.redshift} -PO 4000";
      "change-background" = "${lib.getExe pkgs.nitrogen} --restore";
    };
  };

  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

}
