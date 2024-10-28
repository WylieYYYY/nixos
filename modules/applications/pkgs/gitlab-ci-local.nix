{ lib, pkgs, buildNpmPackage, fetchFromGitHub, ... }:

# Patched Gitlab CI local runner.
# - Removes Git cleanup as fetches do not include `.git`.

buildNpmPackage rec {
  pname = "gitlab-ci-local";
  version = "4.55.0";

  src = fetchFromGitHub {
    owner = "firecow";
    repo = pname;
    rev = version;
    sha256 = "rfe2vvg6F4MzV/FN52cf31Ef0XlMGM+UpbSRq2vinsM=";
  };

  patches = [ ./../../../patches/gitlab-ci-local-no-cleanup.patch ];

  npmDepsHash = "sha256-uv0/pasytEKEhkQXhjh51YWPMaskTEb3w4vMaMpspmI=";

  postFixup = ''
    wrapProgram $out/bin/gitlab-ci-local --set PATH \
        ${lib.makeBinPath (with pkgs; [ bash coreutils docker gawk git rsync ])}
  '';

  meta.mainProgram = pname;
}
