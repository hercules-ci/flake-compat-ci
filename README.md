
### `flake-compat-ci`

This was a stop-gap solution for flakes CI with stable Nix 2.3 and stable Hercules CI before it supported flakes natively.
An up to date hercules-ci-agent is enough to evaluate flakes, and you can make use of the [`herculesCI`](https://docs.hercules-ci.com/hercules-ci-agent/evaluation) flake output attribute in order to customize the default behavior.

Consider switching to the [`hercules-ci-effects`](https://flake.parts/options/hercules-ci-effects) flake-parts module, which adds more useful functionality using the module system. Flake-parts lets you integrate many other useful modules as well.

<details><summary>Old readme</summary>

It provides the `lib.recurseIntoFlake` function, which tells nix-build and Hercules CI
which attributes to traverse for a given flake.

### Installation

Add the custom `ciNix` attribute to your flake:

Add to `flake.nix`:
```nix
{
  inputs = {
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-compat-ci.url = "github:hercules-ci/flake-compat-ci";
  };
  outputs = { 
    self,
    # ...
    flake-compat-ci,
    ...
  }:
  {
    ciNix = flake-compat-ci.lib.recurseIntoFlakeWith {
      flake = self;

      # Optional. Systems for which to perform CI.
      # By default, every system attr in the flake will be built.
      # Example: [ "x86_64-darwin" "aarch64-linux" ];
      systems = [ "x86_64-linux" ];
    };
  };
}
```

Run `nix flake update` and add these two boilerplate files:

`flake-compat.nix`
```nix
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes.flake-compat.locked) owner repo rev narHash;
  flake-compat = builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
in
import flake-compat { src = ./.; }
```

`ci.nix`
```nix
(import ./flake-compat.nix).defaultNix.ciNix
```

</details>
