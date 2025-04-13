{ config, lib, pkgs, ... }:

# Adds VSCodium, with its configurations and extensions.

{

  programs.vscode = lib.mkIf (config.customization.codeEditor == "vscodium") {
    enable = true;
    package = pkgs.vscodium;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    userSettings = {
      "files.enableTrash" = false;
      "files.trimTrailingWhitespace" = true;
      "git.terminalAuthentication" = false;
      "javascript.validate.enable" = false;
      "js/ts.implicitProjectConfig.checkJs" = true;
      "nixEnvSelector.nixFile" = "\${workspaceRoot}/shell.nix";
      "security.workspace.trust.enabled" = false;
      "terminal.integrated.sendKeybindingsToShell" = true;
      "typescript.validate.enable" = false;
      "workbench.colorTheme" = "Dracula";
      "workbench.sideBar.location" = "right";
      "workbench.welcome.enabled" = false;
      "vim.normalModeKeyBindings" = [
        { before = [ "t" ]; commands = [ "workbench.action.quickOpen" ]; }
        { before = [ "J" ]; commands = [ ":tabprevious" ]; }
        { before = [ "K" ]; commands = [ ":tabnext" ]; }
      ];
      "vim.useSystemClipboard" = true;
    };

    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      dracula-theme.theme-dracula
      ms-azuretools.vscode-docker
      rust-lang.rust-analyzer
      vscodevim.vim
      arrterian.nix-env-selector
    ] ++ (pkgs.callPackage ./../../modules/applications/extensions/vscode-extras.nix { });
    mutableExtensionsDir = false;
  };

}
