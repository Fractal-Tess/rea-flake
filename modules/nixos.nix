{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  package = self.packages.${system}.rea;
  cfg = config.programs.rea;
in
{
  options = import ./options.nix { inherit lib package; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
