{ persist, lib, pkgs, ... }:

# Adds development tools such as Git and VSCode.
# Parameters:
# - persist: Attribute set of persisting settings.
#   - gitUserEmail?: Default email associated with Git.
#   - gitUserName?: Default user name associated with Git.

{

  home.packages = [ pkgs.gitlab-ci-local ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_config theme choose 'ayu Dark'
      set fish_greeting
    '';

    # Creates a temporary private shell with the given packages.
    shellAbbrs.try = ''${lib.getExe' pkgs.nix "nix-shell"} --command \
        '${lib.getExe pkgs.fish} --private' --packages'';

    # Searches Youtube with the query and plays the first audio found.
    functions.play = ''
      set query (string join ' ' $argv)
      set log (${lib.getExe' pkgs.vlc "cvlc"} --play-and-exit \
      (${lib.getExe pkgs.yt-dlp} --get-url --format bestaudio ytsearch:$query) 2>&1)
      set play_status $status
      [ $play_status -ne 0 ] && printf '%s\n' "$log" >&2
      return $play_status
    '';

    # Overrides Which to display the canonicalized name on NixOS.
    functions.which = ''
      set path (${lib.getExe pkgs.which} $argv[1])
      set which_status $status
      [ $which_status -ne 0 ] && return $which_status
      ${lib.getExe' pkgs.coreutils "readlink"} --canonicalize $path
    '';
  };

  programs.git = {
    enable = true;
    userEmail = lib.mkIf (persist ? gitUserEmail) persist.gitUserEmail;
    userName = lib.mkIf (persist ? gitUserName) persist.gitUserName;

    aliases = {
      br = "branch";
      co = "checkout";
      l  = "log --oneline --graph --decorate --all";
      st = "status";
    };

    extraConfig = {
      core.excludesFile = builtins.toString (pkgs.writeText "git-ignore"
          (lib.concatStringsSep "\n" [ ".direnv" ".envrc" "shell.nix" ]));
      credential.helper = "cache";
    };

    lfs = {
      enable = true;
      skipSmudge = true;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    userSettings = {
      "files.enableTrash" = false;
      "git.terminalAuthentication" = false;
      "javascript.validate.enable" = false;
      "js/ts.implicitProjectConfig.checkJs" = true;
      "nixEnvSelector.nixFile" = "\${workspaceRoot}/shell.nix";
      "security.workspace.trust.enabled" = false;
      "terminal.integrated.sendKeybindingsToShell" = true;
      "typescript.validate.enable" = false;
      "workbench.colorTheme" = "Dracula";
      "workbench.welcome.enabled" = false;
      "vim.normalModeKeyBindings" = [
        { before = [ "t" ]; commands = [ "workbench.action.quickOpen" ]; }
        { before = [ "J" ]; commands = [ ":tabprevious" ]; }
        { before = [ "K" ]; commands = [ ":tabnext" ]; }
      ];
    };

    extensions = with pkgs.vscode-extensions; [
      mhutchie.git-graph
      bbenoist.nix
      dracula-theme.theme-dracula
      ms-azuretools.vscode-docker
      rust-lang.rust-analyzer
      vscodevim.vim
      arrterian.nix-env-selector
    ] ++ (pkgs.callPackage ./../modules/applications/extensions/vscode-extras.nix { });
    mutableExtensionsDir = false;
  };

}
