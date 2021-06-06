{
  description = "A very basic flake";

  inputs = {
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, flake-compat, nixpkgs }:
  let
    flake-compat-ci = (import ./flake-compat.nix { src = ../.; }).defaultNix;
  in
  {

    ciNix = {
      recurseIntoFlake = flake-compat-ci.lib.recurseIntoFlake {} self;
    };

    checks."x86_64-linux".bovine = nixpkgs.legacyPackages."x86_64-linux".cowsay;

    packages."x86_64-linux".hello = nixpkgs.legacyPackages."x86_64-linux".hello;

    defaultPackage."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".figlet;

    apps."x86_64-linux".hello = {
      type = "app";
      program = nixpkgs.legacyPackages."x86_64-linux".hello;
    };

    defaultApp."x86_64-linux" = {
      type = "app";
      program = nixpkgs.legacyPackages."x86_64-linux".hello;
    };

    devShell."x86_64-linux" =
      let pkgs = nixpkgs.legacyPackages."x86_64-linux";
      in pkgs.mkShell {
        nativeBuildInputs = [ pkgs.figlet pkgs.hello ];
      };

    nixosConfigurations.joes-desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          fileSystems."/".device = "x";
          boot.loader.grub.enable = false;
        }
      ];
    };

  };
}
