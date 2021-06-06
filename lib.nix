{ ... }:
let
  inherit (builtins)
   attrNames
   concatMap
   intersectAttrs
   listToAttrs
   mapAttrs
   ;

  recurseIntoAttrs = as: as // { recurseForDerivations = true; };
  optionalAttrs = b: if b then as: as else _: {};
  traverse_ = f: v: recurseIntoAttrs (mapAttrs (k: f) v);

  checkApp = app:
    if app.type != "app"
    then throw "Nix flake app type must be \"app\"."
    else recurseIntoAttrs {
      inherit (app) program;
    };

  getNixOS = sys: sys.config.system.build.toplevel // getNixOSMeta;
  getNixOSMeta = sys: { inherit (sys) config; };
  toggleNixOS = pred: sys:
    if pred sys.config._module.args.pkgs.stdenv.hostPlatform
    then getNixOS sys
    else getNixOSMeta sys;

  nameValuePair = name: value: { inherit name value; };
  filterAttrs = pred: set:
    listToAttrs (concatMap (name: let v = set.${name}; in if pred name v then [(nameValuePair name v)] else []) (attrNames set));

  applyFunctions = functions: attrs:
    builtins.intersectAttrs functions (
      builtins.mapAttrs (k: functions.${k}) attrs
    );

  inputsForSystem = inputs: system: mapAttrs (k: toSystem system) inputs;
  intersectSystemAttrs = 
    intersectAttrs {
      checks = null;
      packages = null;
      defaultPackage = null;
      apps = null;
      defaultApp = null;
      legacyPackages = null;
      devShell = null;
    };

  toSystem = system: flake:
    flake // intersectSystemAttrs (transposeAttrs flake).${system};

  recurseIntoFlake = {
    systems ? null,
    systemPredicate ? if systems == null then _: true else s: builtins.elem s systems,
  }: flake:
  let filterSystems = filterAttrs (k: v: systemPredicate k);
      doSystems = f: ss: recurseIntoAttrs (filterSystems (mapAttrs (k: f) ss));
  in
    recurseIntoAttrs flake
    // applyFunctions {
      checks = doSystems recurseIntoAttrs;
      packages = doSystems recurseIntoAttrs;
      defaultPackage = doSystems (x: x);
      apps = doSystems (traverse_ checkApp);
      defaultApp = doSystems checkApp;
      legacyPackages = doSystems recurseIntoAttrs;
      nixosConfigurations = traverse_ (toggleNixOS systemPredicate);
      devShell = doSystems (s: s // { isShell = true; });
    } flake;

  makeFlake = {
    inputs,
    nixpkgs ? inputs.nixpkgs,
    systemIndependent ? _: {},
    perSystem ? _ : {}
  }:
    inputs:
      systemIndependent inputs
      // mergeSystems (forSystems nixpkgs (system:
        perSystem (inputsForSystem inputs system)
      ));

  forSystems = nixpkgs: f:
    mapAttrs (system: _: f system) nixpkgs.legacyPackages;
  
  mergeSystems = systems: intersectSystemAttrs (transposeAttrs systems);

  transposeAttrs = p: builtins.foldl'
    (acc: pName:
      builtins.foldl'
        (acc: qName:
          acc // {
            ${qName} = (acc.${qName} or {}) // { 
              ${pName} = p.${pName}.${qName};
            };
          }
        )
        acc
        (attrNames p.${pName}))
    {}
    (attrNames p);

  # /* Apply fold functions to values grouped by key.

  #    Example:
  #      foldAttrs (n: a: [n] ++ a) [] [{ a = 2; } { a = 3; }]
  #      => { a = [ 2 3 ]; }
  # */
  # foldAttrs = op: nul: list_of_attrs:
  #   fold (n: a:
  #       fold (name: o:
  #         o // { ${name} = op n.${name} (a.${name} or nul); }
  #       ) a (attrNames n)
  #   ) {} list_of_attrs;

  # mergeAttrList

in {
  inherit
    recurseIntoFlake
    makeFlake
    transposeAttrs
    ;
}