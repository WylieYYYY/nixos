{ pkgs, fetchFromGitHub, fetchurl, ... }:

pkgs.lua5_2.pkgs.buildLuarocksPackage rec {
  pname = "awesome-ez";
  version = "0.3.0-2";

  knownRockspec = (fetchurl {
    url = "mirror://luarocks/awesome-ez-0.3.0-2.rockspec";
    sha256 = "Ku0/P8/og5e77671QYiPkjz5pYNLcSyrBeMYHnyp49s=";
  }).outPath;

  src = fetchFromGitHub {
    owner = "jcrd";
    repo = "awesome-ez";
    rev = "v0.3.0";
    sha256 = "XKTkl+gT5OO+M5ivgcwwWXAyvRO6FNBFmjwPsd5hk0A=";
  };

  disabled = pkgs.lua5_2.pkgs.luaOlder "5.1";
}
