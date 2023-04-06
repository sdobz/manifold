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
        markdown_nix = ./nix/markdown.nix;
        runtime_nix = ./nix/runtime.nix;
        runtimeInputs = [ pkgs.nix ];
      in rec {
        nixmd = pkgs.writeScriptBin "nixmd"
          ''
          #!${pkgs.runtimeShell}
          set -o errexit
          set -o nounset
          set -o pipefail

          export PATH="${pkgs.lib.makeBinPath runtimeInputs}:$PATH"

          if  [ $# -lt 2 ] || [ ! -f "$2" ]; then
              echo "Usage: $0 <cmd> <somefile.md>"
              exit 1
          fi
          CMD="$1"
          SOURCE_TEXT="$(realpath "$2")"
          MARKDOWN_NIX="''${MARKDOWN_NIX:-${markdown_nix}}"
          nix-instantiate \
            --read-write-mode \
            --show-trace \
            --eval -E "\
              with import \"$MARKDOWN_NIX\"; \
              $CMD \"$SOURCE_TEXT\""
          '';
        nixmd-build = pkgs.writeScriptBin "nixmd-build"
          ''
          #!${pkgs.runtimeShell}
          set -o errexit
          set -o nounset
          set -o pipefail

          export PATH="${pkgs.lib.makeBinPath runtimeInputs}:$PATH"

          if  [ $# -lt 1 ] || [ ! -f "$1" ]; then
              echo "Usage: $0 <somefile.md>"
              exit 1
          fi
          SOURCE_TEXT="$(realpath "$1")"
          shift
          OUTPUT_FILENAME="$(basename "$SOURCE_TEXT").nix"
          MARKDOWN_NIX="''${MARKDOWN_NIX:-${markdown_nix}}"
          RUNTIME_NIX="''${RUNTIME_NIX:-${runtime_nix}}"
          nix-build \
            --impure \
            --expr "\
              let md = import \"$MARKDOWN_NIX\"; \
                  pkgs = import <nixpkgs> {}; in \
              pkgs.writeText \"$OUTPUT_FILENAME\" (md.dumpRuntime \"$RUNTIME_NIX\" \"$SOURCE_TEXT\")" \
               "$@"
          '';
        nixmd-run = pkgs.writeScriptBin "nixmd-run"
          ''
          #!${pkgs.runtimeShell}
          set -o errexit
          set -o nounset
          set -o pipefail

          export PATH="${pkgs.lib.makeBinPath runtimeInputs}:$PATH"

          if  [ $# -lt 1 ] || [ ! -f "$1" ]; then
              echo "Usage: $0 <somefile.md.nix> <somefile.md>"
              exit 1
          fi
          MD_NIX="$(realpath "$1")"
          shift
          OUTPUT_FILENAME="$(basename "$MD_NIX").md"

          nix-build \
            --impure \
            --expr "\
              let nixmd = import \"$MD_NIX\" {}; \
                  pkgs = import <nixpkgs> {}; in \
              pkgs.writeText \"$OUTPUT_FILENAME\" nixmd.out" \
              "$@"
          '';
        nixmd-all = pkgs.linkFarmFromDrvs  "nixmd-all" [ nixmd nixmd-build nixmd-run ];
      });

      defaultPackage = forAllSystems (system: self.packages."${system}".nixmd-all);

      apps = forAllSystems (system: {
        nixmd = {
          type = "app";
          program = "${self.packages."${system}".nixmd}/bin/nixmd";
        };
        nixmd-build = {
          type = "app";
          program = "${self.packages."${system}".nixmd-build}/bin/nixmd-build";
        };
        nixmd-run = {
          type = "app";
          program = "${self.packages."${system}".nixmd-run}/bin/nixmd-run";
        };
      });
      defaultApp = forAllSystems (system: self.apps."${system}".nixmd);
      formatter = forAllSystems (system: self.legacyPackages."${system}".nixfmt);

      devShell =  forAllSystems (system:
        let pkgs = self.legacyPackages."${system}"; in
        pkgs.mkShell {
            buildInputs = [
              self.packages."${system}".nixmd
              self.packages."${system}".nixmd-build
              self.packages."${system}".nixmd-run
              pkgs.jq
            ];
            buildPhase = "";
            shellHook = ''
            '';
          }
      );
  };
}
