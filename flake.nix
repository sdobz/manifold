{
  description = "literate programming in markdown using nix";
  inputs = {};
  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "x86_64-darwin" "i686-linux" "aarch64-linux" ];
  in {
      legacyPackages = forAllSystems (system: import nixpkgs {
        inherit system;
      });

      packages = forAllSystems (system: let
        pkgs = self.legacyPackages."${system}";
        semantic_nix = ./nix/semantic.md.nix;
        runtime_nix = ./nix/runtime.nix;
        manifold_cli = ./nix/manifold.cli.sh;
        runtimeInputs = [ pkgs.nix ];
      in rec {
        manifold = pkgs.writeScriptBin "manifold"
          ''
          #!${pkgs.runtimeShell}

          export PATH="${pkgs.lib.makeBinPath runtimeInputs}:$PATH"
          export SEMANTIC_NIX="${semantic_nix}"
          export RUNTIME_NIX="${runtime_nix}"
          export MANIFOLD_CLI="${manifold_cli}"

          ${pkgs.runtimeShell} "$MANIFOLD_CLI" "$@"
          '';
        manifold-all = pkgs.linkFarmFromDrvs  "manifold-all" [ manifold ];
      });

      defaultPackage = forAllSystems (system: self.packages."${system}".manifold-all);

      apps = forAllSystems (system: {
        manifold = {
          type = "app";
          program = "${self.packages."${system}".manifold}/bin/manifold";
        };
      });
      defaultApp = forAllSystems (system: self.apps."${system}".manifold);
      formatter = forAllSystems (system: self.legacyPackages."${system}".nixfmt);

      devShell =  forAllSystems (system:
        let pkgs = self.legacyPackages."${system}"; in
        pkgs.mkShell {
            buildInputs = [
              self.packages."${system}".manifold
              pkgs.jq
              pkgs.inotify-tools
              pkgs.cloc
            ];
            buildPhase = "";
            shellHook = ''
            mkdir .gcroot
            '';
          }
      );
  };
}
