{ lib, pkgs, ... }:

# Adds Pulsar Edit, with its configurations and packages.

{

  imports = [
    ./../../modules/applications/pulsar.nix
  ];

  programs.pulsar = {
    enable = true;

    # Excludes Git-Plus for long load time.
    packages = (builtins.filter (package: package.repo != "git-plus")
        (import ./atom-packages.nix));

    config."*" = {
      autocomplete-plus.backspaceTriggersAutocomplete = true;
      core.disabledPackages = [ "github" "welcome" "open-on-github" ];
      editor.showIndentGuide = true;
      git-diff-staged.gitPath = lib.getExe pkgs.git;
      kotlin-lsp-adapter.kotlin-lsp =
          lib.getExe' pkgs.kotlin-language-server "kotlin-language-server";
      tree-view.squashDirectoryNames = true;
      x-terminal-reloaded = {
        spawnPtySettings = {
          name = "xterm-256color";
          projectCwd = true;
        };
        terminalSettings = {
          leaveOpenAfterExit = false;
          showNotifications = false;
        };
      };
    };
  };

}
