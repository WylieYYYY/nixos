{ lib, pkgs, buildNpmPackage, fetchFromGitHub, importNpmLock, ... }:

{
  repo,
  owner,
  version,
  sha256,
  npmDepsHash ? null,
  packageLock ? null,
  patches ? [ ]
}:

# Builds an Atom package for Pulsar Edit.
# Patches the package before lock file is read.
# Parameters:
# - repo: Name of the GitHub repository to fetch the package from.
# - owner: Owner of the GitHub repository.
# - version: Version of the package which is the tag name without the `v` prefix.
# - sha256: Hash value of the specific version of the package repository.
# - packageLock: `null` if external `package-lock.json` is not required,
#   path to the file otherwise. This file is not patched and assumed to have a
#   `packages` key in the root of the object. If there is no `packages` key,
#   use `npmDepsHash` to specify dependencies hash. Default is `null`.
# - npmDepsHash: Hash of NPM dependencies for old version lock file support.
#   If this is not null, the `packageLock` option is ignored. Default is `null`.
# - patches: Patches to be applied to the package. Default is an empty list.
# Returns: Built package, Pulsar Edit expects the directory under
# `lib/node_modules/<package name>` in its `packages` subdirectory.

let
  patchedSrc = pkgs.srcOnly {
    inherit version patches;
    pname = repo;
    stdenv = pkgs.stdenvNoCC;
    src = fetchFromGitHub {
      inherit repo owner sha256;
      rev = "v${version}";
    };
  };

  package = lib.importJSON "${patchedSrc}/package.json";
in

buildNpmPackage (
  {
    inherit version;
    pname = package.name;
    src = patchedSrc;
    preConfigure = "mkdir --parent node_modules";
    buildPhase = "${lib.getExe' pkgs.pulsar "pulsar"} --package rebuild";
    dontNpmPrune = true;
  } // (
    if npmDepsHash != null
    then { inherit npmDepsHash; }
    else {
      npmDeps = importNpmLock {
        inherit package;
        packageLock =  lib.importJSON
            (if packageLock == null
             then "${patchedSrc}/package-lock.json"
             else packageLock);
      };
      npmConfigHook = importNpmLock.npmConfigHook;
    }
  )
)
