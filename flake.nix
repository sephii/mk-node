{
  description = "mk-node";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        mkNodeModules = { src, nodejs ? pkgs.nodejs-16_x
          , node2nix ? pkgs.nodePackages.node2nix, fixNodeGyp ? false }:
          let
            packageFiles = builtins.filterSource (path: type:
              builtins.elem (baseNameOf path) [
                "package.json"
                "package-lock.json"
              ]) src;

            nodeModules = pkgs.stdenv.mkDerivation {
              name = "node-modules";
              src = packageFiles;
              buildCommand = ''
                mkdir $out
                ${node2nix}/bin/node2nix -d -i $src/package.json -l $src/package-lock.json --node-env $out/node-env.nix --output $out/node-packages.nix
              '';
            };

            nodeEnv = pkgs.callPackage "${nodeModules}/node-env.nix" {
              nodejs = nodejs;
              libtool =
                if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
            };

            nodePackages = pkgs.callPackage "${nodeModules}/node-packages.nix" {
              inherit nodeEnv;
            };

            nodeArgs = nodePackages.args // {
              production = true;
              src = packageFiles;
              dontNpmInstall = true;
              # https://github.com/svanderburg/node2nix/issues/275
              buildInputs = if fixNodeGyp then
                [ pkgs.nodePackages.node-gyp-build ]
              else
                [ ];
              preRebuild = pkgs.lib.optionalString fixNodeGyp ''
                sed -i -e "s|#!/usr/bin/env node|#! ${nodejs}/bin/node|" node_modules/node-gyp-build/bin.js
              '';
            };

            nodeShell = nodeEnv.buildNodeShell nodeArgs;
          in nodeShell.nodeDependencies;
      });
}
