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
  pure = x: slice:
    [ slice x ];
  
  /*
  regex - if a match is successful
    then return the array of capture groups as a result and consume
  */

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
    if it succeeds run the second parser
  */
  skipThen = parseA: parseB: bind parseA (_: parseB);

  /*
  frontmatter
  */

  # toml parsing

  /*
  action - performed during derivation
  */

  # eval'd?

  /*
  tag
  */

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
