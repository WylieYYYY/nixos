# List of Atom packages to be installed for Pulsar Edit.

[
  { # editorconfig
    repo = "atom-editorconfig";
    version = "2.6.1";
    owner = "sindresorhus";
    sha256 = "3K8WxwyEpbPsxaiJRapd1fZW7LQNND/6gJzHfJq30lA=";
    packageLock = ./../../lockfiles/atom-editorconfig.json;
  }
  { # git-plus
    repo = "git-plus";
    version = "8.7.1";
    owner = "akonwi";
    sha256 = "d/kc7t6zQgS+gAy54GYkBij0SuFn2sfeCAS1JQFRf70=";
    npmDepsHash = "sha256-pXpt39luGgVRQUtmQfdkKhytJysoE8dMEYsqPLYBxDg=";
  }
  { # kotlin-lsp-adapter
    repo = "kotlin-lsp-adapter";
    version = "0.3.0";
    owner = "sltodd";
    sha256 = "pG1AXumpYNy7HkL7Q8A8IMJm/FH79mlmY2oKzPOMvvs=";
    packageLock = ./../../lockfiles/atom-kotlin-lsp-adapter.json;
  }
  { # language-kotlin
    repo = "atom-kotlin-language";
    version = "0.5.0";
    owner = "alexmt";
    sha256 = "3d869FqratvkWk6p+lUpQM3KpCpOXn5bHXWBBEE0iaY=";
    packageLock = ./../../lockfiles/atom-language-kotlin.json;
  }
  { # nix
    repo = "atom-nix";
    version = "2.3.3";
    owner = "wmertens";
    sha256 = "iGVYDhnpSnJSOSlMZFSBP8auvcG9+CCJF8Dp3Jg/ujc=";
    packageLock = ./../../lockfiles/atom-nix.json;
  }
  { # x-terminal-reloaded
    repo = "x-terminal-reloaded";
    version = "14.3.0";
    owner = "Spiker985";
    sha256 = "m+ce0B89fxiwXRDm8r3wl84Rn3WlxW9iOZYoHvU4o8I=";
    patches = [ ./../../patches/atom-x-terminal-reloaded-node-pty.patch ];
  }
]
