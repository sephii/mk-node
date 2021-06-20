Bundle your node files as a Nix derivation
==========================================

This is a thin wrapper around
[`node2nix`](https://github.com/svanderburg/node2nix) that creates a node
environment with the dependencies defined in `package-lock.json` and then runs a
custom compilation command to produce dist files.

The package provides a single function `mkNodeDist`, that takes the following arguments:

* **src**: the path to your project. Usually `./.`
* **installScript**: the script to create your bundle. This may change depending
  on the bundler you’re using (webpack, gulp, esbuild, etc). Note that your
  script is also responsible of copying the files to `$out` since the library
  cannot guess where your dist files are generated
* node2nix (optional): `node2nix` package to use. Defaults to `pkgs.nodePackages.node2nix`
* nodejs (optional): `nodejs` package to use. Defaults to `pkgs.nodePackages.nodejs-14_x`

Example
-------

Assuming you have a project with a `package.json` and `package-lock.json` and
you’re using webpack, you can use the following to generate your bundle:

``` nix
let
  pkgs = import <nixpkgs> {};
  mkNode = callPackage (pkgs.fetchFromGitHub {
    owner = "sephii";
    repo = "mk-node";
    rev = "main";
    # Use `nix-prefetch-git --url https://github.com/sephii/mk-node --rev refs/heads/main` to get the correct hash
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) { };
in
  mkNode.mkNodeDist {
    src = ./.;
    installScript = ''
      NODE_ENV=production webpack
      mkdir $out
      cp -r dist/{stylesheets,images,javascripts} $out/
    '';
  }
```
