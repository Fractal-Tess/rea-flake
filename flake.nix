{
  description = "REA (Reverse Engineer Anything) packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packageFor = system: nixpkgs.legacyPackages.${system}.callPackage ./packages/rea.nix { };
    in
    {
      packages = forAllSystems (
        system:
        let
          rea = packageFor system;
        in
        {
          inherit rea;
          default = rea;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.rea}/bin/rea";
          meta.description = "Run the REA CLI";
        };
      });

      checks = forAllSystems (system: {
        rea = self.packages.${system}.rea;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      overlays.default = final: _previous: {
        rea = final.callPackage ./packages/rea.nix { };
      };

      nixosModules.default = import ./modules/nixos.nix { inherit self; };
      homeManagerModules.default = import ./modules/home-manager.nix { inherit self; };
    };
}
