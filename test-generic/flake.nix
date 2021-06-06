{
  description = "A very basic flake";

  inputs = {
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ self, flake-compat, ... }:
  let
    flake-compat-ci = (import ./flake-compat.nix { src = ../.; }).defaultNix;
  in
  flake-compat-ci.lib.makeFlake {
    inherit inputs;
    systemIndependent = { self, nixpkgs, ... }: {
      ciNix = {
        recurseIntoFlake = flake-compat-ci.lib.recurseIntoFlake { systems = ["x86_64-linux"]; } self;
      };
      nixosConfigurations.joes-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            fileSystems."/".device = "x";
            boot.loader.grub.enable = false;
            environment.systemPackages = self.packages."x86_64-linux".hello;
          }
        ];
      };
    };
    perSystem = { nixpkgs, ...}: {
      checks.bovine = nixpkgs.legacyPackages.cowsay;
      packages.hello = nixpkgs.legacyPackages.hello;
      defaultPackage = nixpkgs.legacyPackages.figlet;
      apps.hello = {
        type = "app";
        program = nixpkgs.legacyPackages.hello;
      };
      defaultApp = self.apps.hello;
      devShell =
        let pkgs = nixpkgs.legacyPackages;
        in pkgs.mkShell {
          nativeBuildInputs = [ pkgs.figlet pkgs.hello ];
        };
      };
  } inputs;
}
