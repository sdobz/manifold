{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib;
  inherit (lib) runTests;
  md = import ./markdown.nix;

  loremSlice = [ 0 11 "lorem ipsum" ];
  emipsSlice = [ 3  8 "lorem ipsum" ];
in
  runTests {
    testMakeSlice = {
      expr = md.makeSlice "lorem ipsum";
      expected = loremSlice;
    };

    testDumpSlice = {
      expr = md.dumpSlice emipsSlice;
      expected = "em ipsum";
    };

    testLocSlice = {
      expr = md.loc loremSlice;
      expected = "[0:11]";
    };

    testPeekStart = {
      expr = md.peekN 3 loremSlice;
      expected = "lor";
    };

    testPeekMiddle = {
      expr = md.peekN 2 emipsSlice;
      expected = "em";
    };

    testDrop = {
      expr = md.dropN 3 loremSlice;
      expected = emipsSlice;
    };

    testTokenMatch = {
      expr = md.token "lor" loremSlice;
      expected = [ emipsSlice "lor" ];
    };

    testTokenMiss = {
      expr = md.token "bad" loremSlice;
      expected = "token[0:11]: expected bad got lor";
    };
  }
