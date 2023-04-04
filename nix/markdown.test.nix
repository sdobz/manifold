{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) lib;
  inherit (lib) runTests;
  md = import ./markdown.nix;

  loremSlice = [ 0 11 "lorem ipsum" ];
  emipsSlice = [ 3  8 "lorem ipsum" ];
in
  runTests {
    ##########
    # slices #
    ##########

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

    ###########
    # failure #
    ###########

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

    ###########
    # parsers #
    ###########

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

    testPure = {
      expr = md.dump (md.pure "result" loremSlice);
      expected = "result";
    };

    testFmap = let
      justLorem = md.pure "lorem";
      appendSinAmatTo = value: value + " sin amat";
      parser = md.fmap appendSinAmatTo justLorem;
    in {
      expr = md.dump (parser loremSlice);
      expected = "lorem sin amat";
    };

    testFmapFail = let
      notLorem = md.tag "not lorem";
      appendSinAmatTo = value: value + " sin amat";
      parser = md.fmap appendSinAmatTo notLorem;
    in {
      expr = md.dump (parser loremSlice);
      expected = "tag[0:11] - expected not lorem got lorem ips";
    };

    testTakeUntil = let
      ips = md.tag " ips";
      parser = md.takeUntil ips;
    in {
      expr = md.dump (parser emipsSlice);
      expected = "em";
    };

    testTakeRegex = let
      testSlice = md.makeSlice "abbacadaba";
      parser = md.takeRegex "[abc]";
    in {
      expr = md.dump (parser testSlice);
      expected = "abbaca";
    };

    ###############
    # combinators #
    ###############

    testBindCallsFunction = let
      matchLorem = md.tag "lorem";
      appendDolor = str: md.pure "${str} dolor";
      parser = md.bind matchLorem appendDolor;
    in {
      expr = md.dump (parser loremSlice);
      expected = "lorem dolor";
    };

    testBindPropagatesFailure = let
      matchIpsum = md.tag "ipsum";
      appendDolor = str: md.pure "${str} dolor";
      parser = md.bind matchIpsum appendDolor;
    in {
      expr = md.dump (parser loremSlice);
      expected = "tag[0:11] - expected ipsum got lorem\nbind[0:11] - not successful";
    };

    testSkipThen = let
      lorem = md.tag "lorem ";
      ipsum = md.tag "ipsum";
      parser = md.skipThen lorem ipsum;
    in {
      expr = md.dump (parser loremSlice);
      expected = "ipsum";
    };

    testSkipThenFail = let
      lorem = md.tag "not lorem ";
      ipsum = md.tag "ipsum";
      parser = md.skipThen lorem ipsum;
    in {
      expr = md.dump (parser loremSlice);
      expected = "tag[0:11] - expected not lorem  got lorem ipsu\nbind[0:11] - not successful";
    };

    testThenSkip = let
      lorem = md.tag "lorem";
      ipsum = md.tag " ipsum";
      parser = md.thenSkip lorem ipsum;
    in {
      expr = md.dump (parser loremSlice);
      expected = "lorem";
    };

    testThenSkipFail = let
      lorem = md.tag "not lorem";
      ipsum = md.tag " ipsum";
      parser = md.thenSkip lorem ipsum;
    in {
      expr = md.dump (parser loremSlice);
      expected = "tag[0:11] - expected not lorem got lorem ips\nbind[0:11] - not successful";
    };

    testBetween = let
      lor = md.tag "lor";
      emIp = md.tag "em ip";
      sum = md.tag "sum";
      parser = md.between lor sum emIp;
    in {
      expr = md.dump (parser loremSlice);
      expected = "em ip";
    };

    testOpt = let
      notLorem = md.tag "not lorem";
      lorem = md.tag "lorem";
      parser = md.opt [ notLorem lorem ];
    in {
      expr = md.dump (parser loremSlice);
      expected = "lorem";
    };

    testOptNoMatch = let
      notLorem = md.tag "not lorem";
      alsoNotLorem = md.tag "also lorem";
      parser = md.opt [ notLorem alsoNotLorem ];
    in {
      expr = md.dump (parser loremSlice);
      expected = "opt[0:11] - no parser succeeded";
    };

    testFold = let
      parse1 = md.tag "1";
      operator = root: _value: root + 1;
      parser = md.fold 0 operator parse1;
      fiveOnes = md.makeSlice "11111";
    in {
      expr = md.dump (parser fiveOnes);
      expected = 5;
    };

    testMany = let
      parse1 = md.tag "1";
      operator = root: _value: root + 1;
      parser = md.many parse1;
      threeOnes = md.makeSlice "111";
    in {
      expr = md.dump (parser threeOnes);
      expected = [ "1" "1" "1" ];
    };

    testEof = let
      loremIpsum = md.tag "lorem ipsum";
      parser = md.thenSkip loremIpsum md.eof;
    in {
      expr = md.dump (parser loremSlice);
      expected = "lorem ipsum";
    };

    testEofFail = let
      loremIpsum = md.tag "lorem ipsum";
      extraLoremSlice = md.makeSlice "lorem ipsum!!1";
      parser = md.thenSkip loremIpsum md.eof;
    in {
      expr = md.dump (parser extraLoremSlice);
      expected = "eof[11:3] - expected EOF";
    };

    #########
    # lexer #
    #########
    testLexeme = let
      lorem = md.lexeme (md.tag "lorem");
      ipsum = md.tag "ipsum";
      parser = md.thenSkip lorem ipsum;
      result = parser loremSlice;
    in {
      expr = md.dump result;
      expected = "lorem";
    };

    testAttribute = {
      expr = md.dump (md.attribute loremSlice);
      expected = "lorem";
    };

    testStoreAttribute = {
      expr = md.dump (md.storeAttribute "firstWord" md.attribute loremSlice);
      expected = { firstWord = "lorem"; };
    };
  }
