{ lib, package }:
{
  programs.rea = {
    enable = lib.mkEnableOption "REA, a reverse engineering CLI and MCP server for AI agents";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "REA package to install. Override with `withGhidra = false` to skip the bundled Ghidra.";
    };
  };
}
