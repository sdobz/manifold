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
# with rec {
#   foldr = op: nul: list:
#     let
#       len = length list;
#       fold' = n:
#         if n == len
#         then nul
#         else op (elemAt list n) (fold' (n + 1));
#     in fold' 0;
# };
with {
  traceID = id: trace id id;
};
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
  
  /*
  pure - consume nothing and return this value
  */
  pure = value: slice:
    [ slice value ];

  /*
  fmap - call the function with the value the parser produced
  */
  fmap = f: parser: slice:
    let result = parser slice; in
    
    if failed result
      then result
    else let
      remainder = elemAt result 0;
      value = elemAt result 1;
    in

    [ remainder (f value) ];
  
  /*
  takeWhile - consume characters until the test fails
  */
  takeWhile = testSlice: slice:
    let
      offset = elemAt slice 0;
      length = elemAt slice 1;
      text = elemAt slice 2;
      search = searchOffset:
        if searchOffset >= length || !(testSlice (dropN searchOffset slice))
          then searchOffset
          else search (searchOffset + 1);

      foundOffset = search 0;
    in

    [ (dropN foundOffset slice) (substring offset foundOffset text) ];

  /*
  takeUntil - consume characters until the parser succeeds
  */
  takeUntil = parseUntil:
    takeWhile (searchSlice: failed (parseUntil searchSlice));

  ###############
  # combinators #
  ###############

  /*
  bind aka >>=
    parse - run this, and if it succeeds
    f - call this function with the result (returns a new parser)
    which is then run on the remainder
  */
  bind = parse: f: slice:
    let result = parse slice; in
    if failed result
      then failWith result "bind" slice "not successful"
    else
    
    (f (elemAt result 1)) (elemAt result 0);

  /*
  skipThen 
    runs the first parser
    if it succeeds return the results of the second parser
  */
  skipThen = parseA: parseB: bind parseA (_: parseB);

  /*
  thenSkip
    runs the first parser and store the results
    then consume using the second
  */
  thenSkip = parseA: parseB: bind parseA (resultA: fmap (_: resultA) parseB);

  /*
  between
    run the three parsers
    and resolve to the middle value
  */
  between = parseStart: parseEnd: parseMiddle:
    skipThen parseStart (thenSkip parseMiddle parseEnd);

  /*
  opt
    run each parser until once succeeds, or fail
  */
  opt = parsers: slice:
    let result = (head parsers) slice; in

    if !(failed result)
      then result
    else

    if length parsers > 1
      then opt (tail parsers) slice
    else

    fail "opt" slice "no parser succeeded";

  /*
  fold
    run the parser zero or more times
    applying the operator
    stops on failure
  */
  fold = root: operator: parser: slice:
    let result = parser slice; in
    if failed result
      then [ slice root ]
    else
    
    let
      newSlice = elemAt result 0;
      value = elemAt result 1;
      newRoot = operator root value;
    in

    fold newRoot operator parser newSlice;

  /*
  many
    run a parser until it fails, collecting the results in a list
  */
  many = parser: slice:
    fold [] (collection: value: collection ++ [value]) parser slice;

  /*
  eof
    fails if there is remaining input
  */
  eof = slice:
    if elemAt slice 1 != 0
      then fail "eof" slice "expected EOF"
      else [ slice null ];

  #########
  # lexer #
  #########

  isWhitespace = slice:
    let nextChar = peekN 1 slice; in
    nextChar == " " || nextChar == "\t" || nextChar == "\n";
  
  lexeme = parser: thenSkip parser (takeWhile isWhitespace);

  isIdentifier = slice:
    let nextChar = peekN 1; in
    match "[a-zA-Z0-9_]" name != null;

  identifier = lexeme (takeWhile isIdentifier);

  codeFence = tag "```";

  # htmlTag
  # attributePair
  # quotedExpression

  # do we tokenize?
  # can the source code be runtime'd linearly?
  # no in the case of compositonal args

  # { arg, arg, arg }:
  # let
  # code block -> super: self: { thinger = ''<body>''; }

  /*
  execution
  */
  evalFile = filename: let
    contents = readFile filename;
  in
    stringLength contents;
}

/*

https://richardstartin.github.io/posts/xxhash


final function signature:
md.dump md.parseMD md.makeSlice sourceText
->
write to file (woven)

alternative tangle/weave, storyteller:
juggler: throw/catch
carpenter: cut/join
plumber!: pipe/filter
category theory: monad/set
astronomer: lens
biologist: scope
async/await

"at a point in time"

what IS this?
- source code runtime
- observable nix evaluation

syntactically valid in multiple contexts
The belief that you should not attempt to synchronize semantics across documents

 synchronous semantics
asynchronous operations

md = 
  | frontmatter - toml state declaration
  +  imports
  |  

+++
_inherit = "nix/markdown.nix"
+++

  | source - text (markdown)

# context
copied verbatim

  | action - stateful transformation

```bash nix shell -p hello
hello --greeting \(greeting)
```
  | retain - track memory used by program
  | * evict over time
  | * cache expiration


  | tags - view evaluated state

<code value="previous.stdout">
hi
</code>

  | trigger - initiate transform
  | state - changes through runtime
  +  timeseries - loldb (making a video that replays the sensor data)
  |  "hooks" - signals

action =
  | trigger - how this action appears (enum)
  | deps - which values have to be resolved for this action to "fire"
  | ref - how to identify this action
  | implicit output

state =
  | status - enum (error, etc)
  | 

tag =
  | expression
  | reference

how to determine evaluation order? topological sort evaluation

tags are nixmd

<nixmd story="${expre}"  />

expr:
  run this command
  depend on every reference to state
  path: some fs reference
  state returns: a typed artifact produced by the previous expression


(lexeme - trim trailing whitespace from all symbols)
transform to <frontend

into: literate programming?

weave -> grammar

mkDerivation - passed "nix" results in the same dir but woven

When run it produces a derivation and uses that to satisfy the result
Expressions could be pure nix evaluations
Final file is just a string interpolation of the source text

frontmatter:
describes runtime, comprised of
* nix scope

result:
somefile.nix

silly idea:
control a machine
require "camera running"
goal: gcode sender on esp32



post gcode

unity frontend? backend?


realtime 2d - view graph automatically pans to location in 3d space
can navigate both simultaneously

*/
