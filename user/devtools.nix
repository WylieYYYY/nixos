{ persist, lib, pkgs, ... }:

# Adds development tools such as Git and VSCode.
# Parameters:
# - persist: Attribute set of persisting settings.
#   - gitUserEmail?: Default email associated with Git.
#   - gitUserName?: Default user name associated with Git.

{

  home.packages = [ pkgs.gitlab-ci-local ];

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

    extraConfig.credential.helper = "cache";

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
