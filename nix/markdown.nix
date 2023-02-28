/*
File ghoul: bootstrap a literate programming environment

The "real" file will be written in a general purpose systems programming language
(such as rust)
* speed is a goal
* better complexity management
* availability of libraries

This should be constructed in itself

To get there we have to implement a subset of the language to detangle the readme
(which implements the real environment)
*/

/*

Design:
http://cmsc-16100.cs.uchicago.edu/2017/Lectures/17/parsers.pdf - implements parser combinatorials in gofer (aka haskell lite)

initial goal:
implement arithmatic evaluator in nix

Example:
https://medium.com/@MrJamesFisher/nix-by-example-a0063a1a4c55 - demonstrates parsing the nix AST

Hasura writing a json parser in haskell
https://hasura.io/blog/parser-combinators-walkthrough/

Parsec style parser for markdown:
https://github.com/tiqwab/md-parser

soft requirment:
  - match rust `nom` so they can share combinators

parser = arguments -> slice -> result

result = [ slice value ] | [ slice null err ]
elemAt result 0 = slice
elemAt result 1 = value
elemAt result 2 = err

slice = [ offset length text ]
elemAt slice 0 == offset
elemAt slice 1 == length
elemAt slice 2 == text

err = _ -> string
Can be invoked with null to resolve
Can be composed to represent a stack trace

*/

with builtins;
rec {
  ##########
  # slices #
  ##########
  
 /*
  a slice is an array containing [ offset length text ]
  */
  makeSlice = text: [ 0 (stringLength text) text ];
  
  /*
  return the text that a slice represents
  */
  dumpSlice = slice: substring (elemAt slice 0) (elemAt slice 1) (elemAt slice 2);

  /*
  return the first n characters of a slice in a string
  */
  peekN = n: slice:
    let
      offset = elemAt slice 0;
    in
      substring offset n (elemAt slice 2);

  /*
  return a slice removing the first n characters
  */
  dropN = n: slice:
    [ ((elemAt slice 0) + n) ((elemAt slice 1) - n) (elemAt slice 2) ];
 
  /*
  format offset and length for errors
  */
  loc = slice: "[${toString (elemAt slice 0)}:${toString (elemAt slice 1)}]";

  ###########
  # failure #
  ###########


  /*
  construct a contextual error
  */
  fail = name: slice: msg: [ slice null (_: "${name}${loc slice} - ${msg}") ];

  /*
  failWith adds an err to the end of the err
  */
  failWith = result: name: slice: msg:
    [ slice null (_: "${(elemAt result 2) null}\n${name}${loc slice} - ${msg}") ];

  /*
  check if the err param is present
  */
  failed = result: length result == 3;

  /*
  dump the result if success or error if failure
  */
  dump = result:
    if failed result
      then let err = elemAt result 2; in
        err null
    else
      elemAt result 1;
  
  ###########
  # parsers #
  ###########

  /*
  consume the symbols if matched
  */
  tag = k: slice:
    let tokenLength = stringLength k; in
    if tokenLength > (elemAt slice 1)
      then fail "tag" slice "expected ${k} got overflow"
    else

    let doesMatch = (peekN tokenLength slice) == k; in
    if !doesMatch
      then fail "tag" slice "expected ${k} got ${peekN tokenLength slice}"
    else

    [ (dropN tokenLength slice) k ];

  ###############
  # combinators #
  ###############

  # (*>) :: Parser a -> Parser b -> Parser b
  /*
  skipThen 
    runs the first parser
    if it succeeds run the second parser
  */
  skipThen = parseA: parseB: slice:
    let resA = parseA slice; in
    if failed resA
      then failWith resA "skipThen" slice "A fail"
    else
    
    let resB = parseB (elemAt resA 0); in
    if failed resB
      then failWith resB "skipThen" slice "B fail"
    else

    resB;
}
