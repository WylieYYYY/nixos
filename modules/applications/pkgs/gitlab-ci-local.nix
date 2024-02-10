{ lib, pkgs, buildNpmPackage, fetchFromGitHub, ... }:

# Patched Gitlab CI local runner.
# - Removes Git cleanup as fetches do not include `.git`.

buildNpmPackage rec {
  pname = "gitlab-ci-local";
  version = "4.45.2";

  src = fetchFromGitHub {
    owner = "firecow";
    repo = pname;
    rev = version;
    sha256 = "c2OMJfy/lAdCJJiuCccQYc4sf87vU9B7oaRHmISdI+M=";
  };

  patches = [ ./../../../patches/gitlab-ci-local-no-cleanup.patch ];

  npmDepsHash = "sha256-mup3dsOXxSglf0Wl5bbMilYbwT6uP4Z27V7xdkEWTA4=";

  postFixup = ''
    wrapProgram $out/bin/gitlab-ci-local --set PATH \
        ${lib.makeBinPath (with pkgs; [ bash coreutils docker gawk git rsync ])}
  '';
}
