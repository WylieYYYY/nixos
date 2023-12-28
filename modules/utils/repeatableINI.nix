{ lib, changeSet, iniString, ... }:

# Custom INI manipulator that preserves repeating keys.
# Parameters:
# - changeSet: Attribute set of keys to new values, null if the key should be removed.
# - iniString: The INI string to be manipulated.
# Returns: New INI string after maniuplations.

let
  # Recreates entry or remove entry if the key is given.
  updateIfNeeded = changeSet: line: let
    name = builtins.elemAt (builtins.split " = " line) 0;
  in (
    if builtins.hasAttr name changeSet
    then if builtins.isNull changeSet."${name}"
         then null
         else lib.concatStrings [ name " = " changeSet."${name}" ]
    else line
  );
in

# Skips comment and empty lines to process entries, then recombines.
lib.concatStringsSep "\n" (lib.subtractLists [ null ] (builtins.map (line:
  if builtins.isString line
  then if lib.hasPrefix "#" line || line == ""
       then line
       else updateIfNeeded changeSet line
  else null
) (builtins.split "\n" iniString)))
