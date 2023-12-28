{ buildNpmPackage, fetchFromGitHub }:

# Patched Gitlab CI local runner.
# - Removes Git cleanup as fetches do not include `.git`.
# - todo: Adds Rsync as one of the environment dependency.

buildNpmPackage rec {
  pname = "gitlab-ci-local";
  version = "4.45.2";

  src = fetchFromGitHub {
    owner = "firecow";
    repo = pname;
    rev = version;
    sha256 = "c2OMJfy/lAdCJJiuCccQYc4sf87vU9B7oaRHmISdI+M=";
  };

  patches = [ ./../../patches/gitlab-ci-local-no-cleanup.patch ];

  npmDepsHash = "sha256-mup3dsOXxSglf0Wl5bbMilYbwT6uP4Z27V7xdkEWTA4=";
}
