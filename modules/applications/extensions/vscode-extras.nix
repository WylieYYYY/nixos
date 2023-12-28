{ vscode-utils, ... }:

# Extensions from Open VSX registry that are not yet in Nix.

vscode-utils.extensionsFromVscodeMarketplace [
  {
    name = "kotlin";
    publisher = "fwcd";
    version = "0.2.32";
    sha256 = "hLcnwTNN7jeCmdeddX48uaKUiTLNWqNPgxvJ5tjtw+U=";
  }
]
