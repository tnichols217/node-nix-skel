{
  description = "Dev shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dream2nix.url = "github:nix-community/dream2nix/legacy";
  };

  outputs = { self, nixpkgs, flake-utils, dream2nix, gitignore }:
    let
      nixpkgs = import dream2nix.inputs.nixpkgs {};
      lib = nixpkgs.lib;

      _callModule = module:
        nixpkgs.lib.evalModules {
          specialArgs.dream2nix = dream2nix;
          specialArgs.packageSets.nixpkgs = nixpkgs;
          modules = [module ./settings.nix dream2nix.modules.dream2nix.core];
        };

      # like callPackage for modules
      callModule = module: (_callModule module).config.public;

      packageModuleNames = builtins.attrNames (builtins.readDir ./packages);

      packages =
        lib.genAttrs packageModuleNames
        (moduleName: callModule "${./packages}/${moduleName}/module.nix");

      dream2nixOut = {
        packages = packages;
      };

      # customOut = flake-utils.lib.eachDefaultSystem (system:
      #   let
      #     name = "node-nix-skel";
      #     pkgs = nixpkgs.legacyPackages.${system};
      #     app = dream2nixOut.packages."${system}"."${name}";
      #   in with pkgs; {
      #     packages = rec {
      #       filtered = pkgs.callPackage ./nix/filter.pkg.nix { file = app; inherit name; };
      #       docker = pkgs.callPackage ./nix/docker.pkg.nix { app = filtered; inherit name; };
      #       node = app;
      #       default = filtered;
      #     };
      #     apps = rec {
      #       dev = {
      #         type = "app";
      #         program = ./nix/scripts/dev.sh;
      #       };
      #       devProd = {
      #         type = "app";
      #         program = ./nix/scripts/devProd.sh;
      #       };
      #       start = {
      #         type = "app";
      #         program = ./nix/scripts/start.sh;
      #       };
      #       build = {
      #         type = "app";
      #         program = ./nix/scripts/build.sh;
      #       };
      #       default = dev;
      #     };
      #   });
    in
    dream2nixOut;
    # nixpkgs.lib.recursiveUpdate dream2nixOut customOut;
}