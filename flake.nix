{
  description = "mk-node";
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, ... }: {
    overlay = final: prev: {
      mkNodeModules = { src, nodejs ? prev.nodejs-16_x
        , node2nix ? prev.nodePackages.node2nix, fixNodeGyp ? false }:
        let
          packageFiles = builtins.filterSource (path: type:
            builtins.elem (baseNameOf path) [
              "package.json"
              "package-lock.json"
            ]) src;

          nodeModules = prev.stdenv.mkDerivation {
            name = "node-modules";
            src = packageFiles;
            buildCommand = ''
              mkdir $out
              ${node2nix}/bin/node2nix -d -i $src/package.json -l $src/package-lock.json --node-env $out/node-env.nix --output $out/node-packages.nix
            '';
          };

          nodeEnv = prev.callPackage "${nodeModules}/node-env.nix" {
            nodejs = nodejs;
            libtool =
              if prev.stdenv.isDarwin then prev.darwin.cctools else null;
          };

          nodePackages = prev.callPackage "${nodeModules}/node-packages.nix" {
            inherit nodeEnv;
          };

          nodeArgs = nodePackages.args // {
            production = true;
            src = packageFiles;
            dontNpmInstall = true;
            # https://github.com/svanderburg/node2nix/issues/275
            buildInputs =
              if fixNodeGyp then [ prev.nodePackages.node-gyp-build ] else [ ];
            preRebuild = prev.lib.optionalString fixNodeGyp ''
              sed -i -e "s|#!/usr/bin/env node|#! ${nodejs}/bin/node|" node_modules/node-gyp-build/bin.js
            '';
          };

          nodeShell = nodeEnv.buildNodeShell nodeArgs;
        in nodeShell.nodeDependencies;
    };
  };
}
