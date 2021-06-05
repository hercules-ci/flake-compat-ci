{
  description = "A very basic flake";

  inputs = {
  };

  outputs = { self }: {

    lib = import ./lib.nix {};

  };
}
