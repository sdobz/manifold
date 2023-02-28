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

    testFail = {
      expr = md.fail "oops" null;
      expected = "oops";
    };

    testFailLoc = {
      expr = md.failLoc "parser" loremSlice null;
      expected = "parser[0:11]";
    };

    testFailLocMsg = {
      expr = md.failLocMsg "parser" loremSlice "is borked" null;
      expected = "parser[0:11] - is borked";
    };

    testFailWith = let
      err = md.fail "err 1";
    in {
      expr = md.failWith err (md.fail "err 2") null;
      expected = "err 1\nerr 2";
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

    testTokenOverflow = {
      expr = md.token "lorem ipsum 123" loremSlice null;
      expected = "token[0:11] - expected lorem ipsum 123 got overflow";
    };

    testTokenMiss = {
      expr = md.token "bad" loremSlice null;
      expected = "token[0:11] - expected bad got lor";
    };
  }
