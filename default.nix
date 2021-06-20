{ pkgs, stdenv, callPackage }:
let
  mkNodeDist = { src, installScript, nodejs ? pkgs.nodejs-14_x
    , node2nix ? pkgs.nodePackages.node2nix }:
    let
      packageFiles = builtins.filterSource (path: type:
        builtins.elem (baseNameOf path) [ "package.json" "package-lock.json" ])
        src;

      nodeModules = stdenv.mkDerivation {
        name = "node-modules";
        src = packageFiles;
        buildCommand = ''
          mkdir $out
          ${node2nix}/bin/node2nix -d -i $src/package.json -l $src/package-lock.json --node-env $out/node-env.nix --output $out/node-packages.nix
        '';
      };

      nodeEnv = callPackage "${nodeModules}/node-env.nix" {
        nodejs = nodejs;
        libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
      };

      nodePackages =
        callPackage "${nodeModules}/node-packages.nix" { inherit nodeEnv; };

      nodeArgs = nodePackages.args // {
        production = true;
        src = packageFiles;
        dontNpmInstall = true;
      };

      nodeShell = nodeEnv.buildNodeShell nodeArgs;
    in stdenv.mkDerivation {
      inherit src;

      name = "node-dist";
      installPhase = ''
        ln -s ${nodeShell.nodeDependencies}/lib/node_modules ./node_modules
        export PATH="${nodeShell.nodeDependencies}/bin:$PATH"
        ${installScript}
      '';
    };
in { inherit mkNodeDist; }
