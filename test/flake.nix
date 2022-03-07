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

    ciNix = args@{ src /* don't omit; relevant for auto-call! */ }: flake-compat-ci.lib.recurseIntoFlakeWith { flake = self; systems = ["x86_64-linux"]; effectsArgs = args; };

    # This would error out if systems is unset.
    checks."unavailable-linux".bovine = throw "unavailable-linux is a pretend `system` that does not actually exist. While it is allowed to be in the flake, it does not actually exist. This error should not be encountered on CI: unavailable-linux is a fake example of a best-effort system. Basically unsupported, but still available.";

    checks."x86_64-linux".bovine = nixpkgs.legacyPackages."x86_64-linux".cowsay;

    packages."x86_64-linux".hello = nixpkgs.legacyPackages."x86_64-linux".hello;

    defaultPackage."x86_64-linux" = nixpkgs.legacyPackages."x86_64-linux".figlet;

    apps."x86_64-linux".hello = {
      type = "app";
      program = nixpkgs.legacyPackages."x86_64-linux".hello;
    };

    apps."x86_64-linux".hello-by-string = {
      type = "app";
      program = "${nixpkgs.legacyPackages."x86_64-linux".hello}/bin/hello";
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

    # Not actually an effect, but that doesn't matter for agent 0.8 traversal.
    effects = { src }: { launch = nixpkgs.legacyPackages."x86_64-linux".hello; };

    nixosConfigurations.joes-desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          fileSystems."/".device = "x";
          boot.loader.grub.enable = false;
        }
      ];
    };

    # Won't be adding alpha to the build farm anytime soon, so we'll find out
    # if it breaks (in the form of a job that can't complete)
    nixosConfigurations.joes-experiment = nixpkgs.lib.nixosSystem {
      system = "alpha-linux";
      modules = [
        {
          fileSystems."/".device = "x";
          boot.loader.grub.enable = false;
        }
      ];
    };

  };
}
