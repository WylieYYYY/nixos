{ config, lib, pkgs, ... }:

# Adds development tools such as Git and VSCode.

{

  home.packages = [ pkgs.gitlab-ci-local ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Persists the direnv allow files for impermanence.
  xdg.dataFile."direnv/allow" = lib.mkIf (config.customization.persistence.direnv != null) {
    source = config.lib.file.mkOutOfStoreSymlink config.customization.persistence.direnv;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      bind \cc ctrl_c
      fish_config theme choose 'ayu Dark'
      set fish_greeting
    '';

    # Creates a temporary private shell with the given packages.
    shellAbbrs.try = lib.concatStringsSep " " [
      ''${lib.getExe' pkgs.nix "nix-shell"} --command''
      '''${lib.getExe pkgs.fish} --private' --packages''
    ];

    # Overrides Ctrl+C to save incomplete commands to history.
    functions.ctrl_c = ''
      set buffer (commandline --current-buffer)
      if [ -n "$buffer" ] && [ -z "$fish_private_mode" ]
        set cmd (string replace --all -- \\ \\\\ $buffer | string join '\n')
        printf '- cmd: %s\n  when: %s\n' $cmd (${lib.getExe' pkgs.coreutils "date"} +%s) \
            >> ${lib.escapeShellArg config.xdg.dataHome}/fish/fish_history
        history merge
      end
      commandline --function cancel-commandline
    '';

    # Searches Youtube with the query and plays the first audio found.
    functions.play = ''
      set query (string join ' ' $argv)
      set info (${lib.getExe pkgs.yt-dlp} --print filename -o '%(title)s - %(uploader)s/%(id)s' ytsearch:$query)
      printf '%s\n' (string replace '/' ' (id: ' $info)')'
      set log (${lib.getExe' pkgs.vlc "cvlc"} --play-and-exit \
          (${lib.getExe pkgs.yt-dlp} --get-url --format bestaudio (string split '/' $info)[-1]) 2>&1)
      set play_status $status
      [ $play_status -ne 0 ] && printf '%s\n' $log >&2
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
    userEmail = config.customization.git.email;
    userName = config.customization.git.username;

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
