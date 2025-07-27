{ config, lib, pkgs, ... }:

# Adds Conky market tracker widget.

let
  queryTickers = pkgs.writeShellScriptBin "query-tickers" ''
    csv="$(${lib.getExe pkgs.terminal-stocks} --tickers ${lib.concatStringsSep "," config.customization.trackedTickers} \
        --json 2>/dev/null | ${lib.getExe pkgs.jq} --raw-output \
        '["Ticker", "Price", "Change", "% Change", "Market"], (.[] | [.ticker, .price, .change, .changePercent, .marketState]) | @csv')"
    printf '%s\n' "$csv" | ${lib.getExe' pkgs.csvkit "csvlook"}
    printf '\n(retrieved: %s (%s))\n' "$(${lib.getExe' pkgs.coreutils "date"} +%T)" \
        "$(TZ='America/New_York' ${lib.getExe' pkgs.coreutils "date"} '+%R %Z')"
  '';
in

{

  nixpkgs.overlays = [(final: prev: {
    terminal-stocks = prev.terminal-stocks.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./../patches/terminal-stocks-stdout-export.patch ];
    });
  })];

  services.conky = lib.mkIf (config.customization.trackedTickers != [ ]) {
    enable = true;
    extraConfig = ''
      conky.config = {
        alignment = 'top_right',
        gap_x = 60,
        gap_y = 60,

        default_color = 'white',
        draw_shades = false,
        font = 'monospace:size=12',

        own_window = true,
        own_window_class = 'Conky',
        own_window_type = 'normal',
        own_window_hints = 'undecorated,sticky,below,skip_taskbar,skip_pager',

        update_interval = 5,
      }

      conky.text = [[
      Market Price Information

      ''${execi 10 ${lib.getExe queryTickers}}
      ]]
    '';
  };

}
