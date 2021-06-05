{ ... }:
let
  recurseIntoAttrs = as: as // { recurseForDerivations = true; };
  optionalAttrs = b: if b then as: as else _: {};
  traverse_ = f: v: recurseIntoAttrs (builtins.mapAttrs (k: f) v);

  checkApp = app:
    if app.type != "app"
    then throw "Nix flake app type must be \"app\"."
    else recurseIntoAttrs {
      inherit (app) program;
    };
  getNixOS = sys: sys.config.system.build.toplevel // sys.config;

in
{
  recurseIntoFlake = flake:
    recurseIntoAttrs {} 
    // optionalAttrs (flake ? checks) {
      checks = traverse_ recurseIntoAttrs flake.checks;
    }
    // optionalAttrs (flake ? packages) {
      packages = traverse_ recurseIntoAttrs flake.packages;
    }
    // optionalAttrs (flake ? defaultPackage) {
      defaultPackage = recurseIntoAttrs flake.defaultPackage;
    }
    // optionalAttrs (flake ? apps) {
      apps = traverse_ (traverse_ checkApp) flake.apps;
    }
    // optionalAttrs (flake ? defaultApp) {
      defaultApp = traverse_ checkApp flake.defaultApp;
    }
    // optionalAttrs (flake ? legacyPackages) {
      legacyPackages = traverse_ recurseIntoAttrs flake.legacyPackages;
    }
    // optionalAttrs (flake ? nixosConfigurations) {
      nixosConfigurations = traverse_ getNixOS flake.nixosConfigurations;
    }
    // optionalAttrs (flake ? devShell) {
      devShell = traverse_ (s: s // { isShell = true; }) flake.devShell;
    }
    ;
}