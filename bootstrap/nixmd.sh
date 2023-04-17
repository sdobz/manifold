set -o pipefail

if [ -z "${MARKDOWN_NIX+xxx}" ] || [ -z "${RUNTIME_NIX+xxx}" ] || [ -z "${NIXMD_SH+xxx}" ]; then
    echo "MARKDOWN_NIX, RUNTIME_NIX, NIXMD_SH must be set to absolute paths to those files" >&2
    exit 1
fi

sub_help() { #                    - Output subcommands
    echo "Usage: nixmd <subcommand> [options]"
    echo "Subcommands:"
    grep "^sub_" "$NIXMD_SH" | sed 's/sub_\([a-z\-]*\).*#\(.*\)/  \1\2/g'
    echo ""
}

sub_build() { # <source.md>       - Print path to nix runtime
    local sourceText="$(realpath "$1")"
    shift
    local runtimeName="$(basename "$sourceText").nix"
    nix-build \
        --impure \
        --no-out-link \
        --expr "\
            let md = import \"$MARKDOWN_NIX\"; \
                pkgs = import <nixpkgs> {}; in \
            pkgs.writeText \"$runtimeName\" (md.dumpRuntime \"$RUNTIME_NIX\" \"$sourceText\")" \
            "$@"
}

sub_evaluate() { # <source.md>    - Print path to evaluated nix
    local sourceText="$(realpath "$1")"
    shift
    local runtimeName="$(basename $sourceText).nix"
    local evaluationName="$runtimeName.md"
    nix-build \
        --impure \
        --no-out-link \
        --expr "\
            let md = import \"$MARKDOWN_NIX\"; \
                pkgs = import <nixpkgs> {}; \
                runtimeNix = pkgs.writeText \"$runtimeName\" (md.dumpRuntime \"$RUNTIME_NIX\" \"$sourceText\"); in \
            pkgs.writeText \"$evaluationName\" (import runtimeNix {}).out" \
            "$@"
}

sub_diff() { # <source.md>        - Print the difference between source and evaluated texts
    local sourceText="$(realpath "$1")"
    shift
    local evalText="$(sub_evaluate "$sourceText" "$@")"
    diff "$sourceText" "$evalText"
}

sub_fix() { # <source.md>         - Replace the source markdown with its fixed variant
    local sourceText="$(realpath "$1")"
    shift
    local evalText="$(sub_evaluate "$sourceText" "$@")"
    cp "$evalText" "$sourceText"
}

sub_eval-nix() { # "expr"         - Import markdown and run command
    local cmd="$1"
    shift
    nix eval \
        --impure \
        --expr "with import \"$MARKDOWN_NIX\"; $cmd" \
        "$@"
}

sub_ast() { # <source.md>         - Dump the AST for this markdown file
    local sourceText="$(realpath "$1")"
    sub_evalNix "dumpAst \"${sourceText}\"" --json
}

subcommand="${1:-}"
case $subcommand in
    "" | "-h" | "--help")
        sub_help
        ;;
    *)
        shift
        sub_${subcommand} $@
        if [ $? = 127 ]; then
            echo "Error: '$subcommand' is not a known subcommand." >&2
            echo "       Run 'nixmd help' for a list of known subcommands." >&2
            exit 1
        fi
        ;;
esac
