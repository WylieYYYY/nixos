{ config, lib, pkgs, ... }:

# Adds VSCodium, with its configurations and extensions.

let
  profileCommonConfig = {
    keybindings = [
      { key = "ctrl+shift+t"; command = "workbench.action.terminal.new"; }
    ];

    userSettings = {
      "diffEditor.ignoreTrimWhitespace" = false;
      "editor.bracketPairColorization.enabled" = false;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.rulers" = [ 80 100 ];
      "editor.stickyScroll.enabled" = false;
      "editor.suggest.showSnippets" = false;
      "files.enableTrash" = false;
      "git.terminalAuthentication" = false;
      "javascript.validate.enable" = false;
      "js/ts.implicitProjectConfig.checkJs" = true;
      "nixEnvSelector.nixFile" = "\${workspaceRoot}/shell.nix";
      "redhat.telemetry.enabled" = false;
      "security.workspace.trust.enabled" = false;
      "terminal.integrated.defaultLocation" = "editor";
      "terminal.integrated.sendKeybindingsToShell" = true;
      "typescript.validate.enable" = false;
      "window.customTitleBarVisibility" = "never";
      "window.titleBarStyle" = "native";
      "workbench.activityBar.location" = "top";
      "workbench.colorTheme" = "Monokai";
      "workbench.secondarySideBar.defaultVisibility" = "hidden";
      "workbench.welcome.enabled" = false;
    };
  };
in

{

  programs.vscodium = lib.mkIf (config.customization.codeEditor == "vscodium") {
    enable = true;

    profiles = builtins.mapAttrs (_: value:
      value // profileCommonConfig // {
        extensions = with pkgs.vscode-extensions; [
          arrterian.nix-env-selector
          editorconfig.editorconfig
          ms-azuretools.vscode-containers
        ] ++ value.extensions;
      }
    ) ({
      default = {
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        extensions = [ ];
      };
    } // lib.optionalAttrs (config.customization.vscodiumProfiles ? c) {
      c = {
        folders = config.customization.vscodiumProfiles.c;
        extensions = with pkgs.vscode-extensions; [
          llvm-vs-code-extensions.vscode-clangd
        ];
      };
    } // lib.optionalAttrs (config.customization.vscodiumProfiles ? java) {
      java = {
        folders = config.customization.vscodiumProfiles.java;
        extensions = with pkgs.vscode-extensions; [
          vscjava.vscode-java-pack
          redhat.java
        ];
      };
    } // lib.optionalAttrs (config.customization.vscodiumProfiles ? nix) {
      nix = {
        folders = config.customization.vscodiumProfiles.nix;
        extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
        ];
      };
    } // lib.optionalAttrs (config.customization.vscodiumProfiles ? python) {
      python = {
        folders = config.customization.vscodiumProfiles.python;
        extensions = with pkgs.vscode-extensions; [
          ms-python.python
          ms-toolsai.jupyter
          ms-toolsai.jupyter-renderers
        ];
      };
    } // lib.optionalAttrs (config.customization.vscodiumProfiles ? rust) {
      rust = {
        folders = config.customization.vscodiumProfiles.rust;
        extensions = with pkgs.vscode-extensions; [
          rust-lang.rust-analyzer
        ];
      };
    } // lib.filterAttrs (lib.const builtins.isAttrs) config.customization.vscodiumProfiles);

    mutableExtensionsDir = false;
  };

}
