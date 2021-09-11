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
      let pkgs = import nixpkgs { inherit system; };
      in {
        defaultPackage = { src, installScript, nodejs ? pkgs.nodejs-14_x
          , node2nix ? pkgs.nodePackages.node2nix }:
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
            };

            nodeShell = nodeEnv.buildNodeShell nodeArgs;
          in pkgs.stdenv.mkDerivation {
            inherit src;

            name = "node-dist";
            installPhase = ''
              ln -s ${nodeShell.nodeDependencies}/lib/node_modules ./node_modules
              export PATH="${nodeShell.nodeDependencies}/bin:$PATH"
              ${installScript}
            '';
          };
      });
}
