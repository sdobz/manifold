{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib;
  inherit (lib) runTests;
  runtime = import ./runtime.nix;
in
  runTests {
    testProducesEmptyOutput = {
      expr = (runtime {}).out;
      expected = "";
    };
  }
