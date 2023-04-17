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
        markdown_nix = ./bootstrap/markdown.nix;
        runtime_nix = ./bootstrap/runtime.nix;
        nixmd_sh = ./bootstrap/nixmd.sh;
        runtimeInputs = [ pkgs.nix ];
      in rec {
        nixmd = pkgs.writeScriptBin "nixmd"
          ''
          #!${pkgs.runtimeShell}

          export PATH="${pkgs.lib.makeBinPath runtimeInputs}:$PATH"
          export MARKDOWN_NIX="${markdown_nix}"
          export RUNTIME_NIX="${runtime_nix}"
          export NIXMD_SH="${nixmd_sh}"

          ${pkgs.runtimeShell} "$NIXMD_SH" "$@"
          '';
        nixmd-all = pkgs.linkFarmFromDrvs  "nixmd-all" [ nixmd ];
      });

      defaultPackage = forAllSystems (system: self.packages."${system}".nixmd-all);

      apps = forAllSystems (system: {
        nixmd = {
          type = "app";
          program = "${self.packages."${system}".nixmd}/bin/nixmd";
        };
      });
      defaultApp = forAllSystems (system: self.apps."${system}".nixmd);
      formatter = forAllSystems (system: self.legacyPackages."${system}".nixfmt);

      devShell =  forAllSystems (system:
        let pkgs = self.legacyPackages."${system}"; in
        pkgs.mkShell {
            buildInputs = [
              self.packages."${system}".nixmd
              pkgs.jq
              pkgs.inotify-tools
            ];
            buildPhase = "";
            shellHook = ''
            '';
          }
      );
  };
}
