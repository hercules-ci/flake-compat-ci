{ ... }:
let
  recurseIntoAttrs = as: as // { recurseForDerivations = true; };
  optionalAttrs = b: if b then as: as else _: {};
  traverse_ = f: v: recurseIntoAttrs (builtins.mapAttrs (k: f) v);
  selectAttrs = systems:
    if systems == null
    then x: x
    else filterAttrs (k: v: builtins.elem k systems);

  inherit (builtins)
    attrNames
    concatMap
    listToAttrs
    ;

  # From nixpkgs/lib
  nameValuePair = k: v: { name = k; value = v; };
  filterAttrs = pred: set: listToAttrs (concatMap (name: let v = set.${name}; in if pred name v then [(nameValuePair name v)] else []) (attrNames set));

  checkApp = app:
    if app.type != "app"
    then throw "Nix flake app type must be \"app\"."
    else recurseIntoAttrs {
      inherit (app) program;
    };
  getNixOS = sys: sys.config.system.build.toplevel // { inherit (sys) config; };
  maybeGetNixOS = systems: 
    if systems == null
    then getNixOS
    else sys: 
      if builtins.elem sys.pkgs.hostPlatform.system systems
      then getNixOS sys
      else null;

in
rec {
  recurseIntoFlake = flake: recurseIntoFlakeWith { inherit flake; };
  recurseIntoFlakeWith = {
    # The flake to recurse into
    flake,
    # A list of systems to build.
    #
    # Flakes have no concept of cross compilation, so this is a little awkward
    # if you do cross compile.
    systems ? null,
    }:
    let selectSystems = 
          if systems == null || builtins.typeOf systems == "list" then 
            selectAttrs systems
            else abort "recurseIntoFlakeWith: systems must be a list of strings.";
    in recurseIntoAttrs {} 
    // optionalAttrs (flake ? checks) {
      checks = traverse_ recurseIntoAttrs (selectSystems flake.checks);
    }
    // optionalAttrs (flake ? packages) {
      packages = traverse_ recurseIntoAttrs (selectSystems flake.packages);
    }
    // optionalAttrs (flake ? defaultPackage) {
      defaultPackage = recurseIntoAttrs (selectSystems flake.defaultPackage);
    }
    // optionalAttrs (flake ? apps) {
      apps = traverse_ (traverse_ checkApp) (selectSystems flake.apps);
    }
    // optionalAttrs (flake ? defaultApp) {
      defaultApp = traverse_ checkApp (selectSystems flake.defaultApp);
    }
    // optionalAttrs (flake ? legacyPackages) {
      legacyPackages = traverse_ recurseIntoAttrs (selectSystems flake.legacyPackages);
    }
    // optionalAttrs (flake ? nixosConfigurations) {
      nixosConfigurations = traverse_ (maybeGetNixOS systems) flake.nixosConfigurations;
    }
    // optionalAttrs (flake ? devShell) {
      devShell = traverse_ (s: s // { isShell = true; }) (selectSystems flake.devShell);
    }
    // optionalAttrs (flake ? effects) {
      effects = recurseIntoAttrs flake.effects;
    }
    ;
}