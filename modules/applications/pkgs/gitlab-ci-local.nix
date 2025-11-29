{ lib, pkgs, buildNpmPackage, fetchFromGitHub, ... }:

# Patched Gitlab CI local runner.
# - Removes Git cleanup as fetches do not include `.git`.

buildNpmPackage rec {
  pname = "gitlab-ci-local";
  version = "4.62.0";

  src = fetchFromGitHub {
    owner = "firecow";
    repo = pname;
    rev = version;
    sha256 = "JcCfrrb/xAvILfHgnKoRxjWG4fvi4kVg0W+s+y25A6Y=";
  };

  patches = [ ./../../../patches/gitlab-ci-local-no-cleanup.patch ];

  npmDepsHash = "sha256-J/my72RPPwg1r1t4vO3CgMnGDP7H/Cc3apToypaK1YI=";

  postFixup = ''
    wrapProgram $out/bin/gitlab-ci-local --set PATH \
        ${lib.makeBinPath (with pkgs; [ bash coreutils docker gawk git rsync ])}
  '';

  meta.mainProgram = pname;
}
