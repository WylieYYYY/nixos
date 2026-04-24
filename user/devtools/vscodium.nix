{ config, lib, pkgs, ... }:

# Adds VSCodium, with its configurations and extensions.

{

  programs.vscode = lib.mkIf (config.customization.codeEditor == "vscodium") {
    enable = true;
    package = pkgs.vscodium;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      keybindings = [
        { key = "ctrl+shift+t"; command = "workbench.action.terminal.new"; }
      ];

      userSettings = {
        "editor.bracketPairColorization.enabled" = false;
        "files.enableTrash" = false;
        "files.insertFinalNewline" = true;
        "files.trimTrailingWhitespace" = true;
        "git.terminalAuthentication" = false;
        "javascript.validate.enable" = false;
        "js/ts.implicitProjectConfig.checkJs" = true;
        "nixEnvSelector.nixFile" = "\${workspaceRoot}/shell.nix";
        "security.workspace.trust.enabled" = false;
        "terminal.integrated.defaultLocation" = "editor";
        "terminal.integrated.sendKeybindingsToShell" = true;
        "typescript.validate.enable" = false;
        "workbench.colorTheme" = "Monokai";
        "workbench.welcome.enabled" = false;
      };

      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        ms-azuretools.vscode-docker
        rust-lang.rust-analyzer
        arrterian.nix-env-selector
      ] ++ (pkgs.callPackage ./../../modules/applications/extensions/vscode-extras.nix { });
    };

    mutableExtensionsDir = false;
  };

}
