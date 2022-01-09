# Bundle your node files as a Nix derivation

This is a thin wrapper around
[`node2nix`](https://github.com/svanderburg/node2nix) that creates a node
environment with the dependencies defined in `package-lock.json`. It provides
convenience (not having to keep several .nix files up-to-date with
`package.json`) at the expense of longer build times.

The package provides a single function `mkNodeModules`, that takes the following arguments:

* **src**: the path to your project. Usually `./.`
* node2nix (optional): `node2nix` package to use. Defaults to `pkgs.nodePackages.node2nix`
* nodejs (optional): `nodejs` package to use. Defaults to `pkgs.nodePackages.nodejs-16_x`
* fixNodeGyp (default: `false`): set to `true` if you’re having an installation
  error with node-gyp. See [this
  issue](https://github.com/svanderburg/node2nix/issues/275) for more
  information

## Example

Assuming you have a project with a `package.json` and `package-lock.json`, you can use the following:

``` nix
{
  inputs.mk-node.url = "github:sephii/mk-node";
  outputs = { self, nixpkgs, mk-node }:
    let
      system = "x86_64-linux";
      nodejs = nixpkgs.legacyPackages.${system}.nodejs-16_x;
      nodeModules = mk-node.${system}.mkNodeModules { src = ./.; inherit nodejs };
    in {
      # Include anything else you need for your derivation (eg. use `buildPythonApplication`, `mkPoetryApplication`, etc)
      defaultPackage.${system} = stdenv.mkDerivation {
        buildPhase = ''
          ln -s ${nodeModules}/lib/node_modules ./node_modules
          export PATH="${nodeModules}/bin:$PATH"
          ${nodejs}/bin/npm run build

          rm -rf ./node_modules
        '';
      };
    }
  }
}
```
