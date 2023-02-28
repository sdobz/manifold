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

    testFail = let 
      result = md.fail "parser" loremSlice "is borked";
    in {
      expr = md.dump result;
      expected = "parser[0:11] - is borked";
    };

    testFailWith = let
      result = md.fail "p" loremSlice "1";
    in {
      expr = md.dump (md.failWith result "p" loremSlice "2");
      expected = "p[0:11] - 1\np[0:11] - 2";
    };

    testNotFailed = {
      expr = md.failed [ loremSlice null ];
      expected = false;
    };

    testFailed = {
      expr = md.failed [ loremSlice null (_: "err") ];
      expected = true;
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

    testTagMatch = {
      expr = md.tag "lor" loremSlice;
      expected = [ emipsSlice "lor" ];
    };

    testTagOverflow = {
      expr = md.dump (md.tag "lorem ipsum 123" loremSlice);
      expected = "tag[0:11] - expected lorem ipsum 123 got overflow";
    };

    testTagMiss = {
      expr = md.dump (md.tag "bad" loremSlice);
      expected = "tag[0:11] - expected bad got lor";
    };

    testSkipThenOk = let
      lorem = md.tag "lorem ";
      ipsum = md.tag "ipsum";
      parser = md.skipThen lorem ipsum;
    in {
      expr = md.dump (parser loremSlice);
      expected = "ipsum";
    };
  }
