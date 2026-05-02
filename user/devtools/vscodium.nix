{ config, lib, pkgs, ... }:

# Adds VSCodium, with its configurations and extensions.

let
  profileCommonConfig = {
    keybindings = [
      { key = "ctrl+shift+t"; command = "workbench.action.terminal.new"; }
    ];

    userSettings = {
      "editor.bracketPairColorization.enabled" = false;
      "editor.formatOnSave" = true;
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
      "window.customTitleBarVisibility" = "never";
      "window.titleBarStyle" = "native";
      "workbench.colorTheme" = "Monokai";
      "workbench.secondarySideBar.defaultVisibility" = "hidden";
      "workbench.welcome.enabled" = false;
    };
  };
in

{

  programs.vscode = lib.mkIf (config.customization.codeEditor == "vscodium") {
    enable = true;
    package = pkgs.vscodium;

    profiles = builtins.mapAttrs (_: value: value // profileCommonConfig) {
      default = {
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;

        extensions = with pkgs.vscode-extensions; [
          arrterian.nix-env-selector
          editorconfig.editorconfig
          ms-azuretools.vscode-containers
        ] ++ (pkgs.callPackage ./../../modules/applications/extensions/vscode-extras.nix { });
      };
    };

    mutableExtensionsDir = false;
  };

}
