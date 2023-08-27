{
  description = "Dev shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dream2nix.url = "github:nix-community/dream2nix";
  };

  outputs = { self, nixpkgs, flake-utils, dream2nix, gitignore }:
    let
      dream2nixOut = 
        dream2nix.lib.makeFlakeOutputs {
          systems = flake-utils.lib.defaultSystems;
          config.projectRoot = ./.;
          source = gitignore.lib.gitignoreSource ./.;
          # autoProjects = true;
          projects = ./projects.toml;
          settings = [
            {
              subsystemInfo.nodejs = 18;
            }
          ];
        };
      customOut = flake-utils.lib.eachDefaultSystem (system:
        let
          name = "node-nix-skel";
          pkgs = nixpkgs.legacyPackages.${system};
          app = dream2nixOut.packages."${system}"."${name}";
        in with pkgs; {
          packages = rec {
            filtered = pkgs.callPackage ./nix/filter.pkg.nix { file = app; inherit name; };
            docker = pkgs.callPackage ./nix/docker.pkg.nix { app = filtered; inherit name; };
            node = app;
            default = docker;
          };
          apps = rec {
            dev = {
              type = "app";
              program = ./nix/scripts/dev.sh;
            };
            devProd = {
              type = "app";
              program = ./nix/scripts/devProd.sh;
            };
            start = {
              type = "app";
              program = ./nix/scripts/start.sh;
            };
            build = {
              type = "app";
              program = ./nix/scripts/build.sh;
            };
            default = dev;
          };
        });
    in
    # dream2nixOut;
    nixpkgs.lib.recursiveUpdate dream2nixOut customOut;
}