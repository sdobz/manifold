#!/usr/bin/env bash

cp "$(./nixmd-build SyntaxDemo.md --no-link)" SyntaxDemo.md.nix
cp "$(nixmd-run SyntaxDemo.md.nix --no-link)" SyntaxDemo.md.nix.md
