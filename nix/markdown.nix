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

type Parser symbol result = [symbol] -> [([symbol],result)]

Parser takes symbols and returns a success list of remaining symbols, and the result of the parse

parsers can be composed

<|>
<*>
<@ "applies" operator

nix types:
function
list
int

what is a symbol?
- it is a chunk of source text

what if parsers enclose a source text? -- the markdown?

Reduces string allocations perhaps - is that a problem?
BUILD IT FIRST profile later

What is simplest? MVP? Vert slice?
Ok: if something goes wrong I want useful error messages

I like the slice idea, it makes math simple
[offset len text]
elemAt slice 0 = offset
elemAt slice 1 = len
elemAt slice 2 = text

same order as substring

are ALL strings this? naw

Parser symbol result = symbol -> Err | [value off len]
Err = _ -> string
Can be invoked with null to resolve

Errs can stack up and be invoked into an array of error messages
*/

with builtins;
rec {
  # slice helpers
  /*
  a slice is an array containing [ val offset length ]
  */
  makeSlice = text: [ 0 (stringLength text) text ];
  
  /*
  return the text that a slice represents
  */
  dumpSlice = slice: substring (elemAt slice 0) (elemAt slice 1) (elemAt slice 2);

  /*
  format offset and length for errors
  */
  loc = slice: "[${toString (elemAt slice 0)}:${toString (elemAt slice 1)}]";

  /*
  fail constructs an error
  */
  fail = msg: _: msg;

  /*
  construct an anonymous error
  */
  failLoc = name: slice: _: "${name}${loc slice}";

  /*
  construct a contextual error
  */
  failLocMsg = name: slice: msg: _: "${name}${loc slice} - ${msg}";

  /*
  failWith adds an err to the end of the err
  */
  failWith = err: newErr: _: "${err null}\n${newErr null}";

  /*
  return the first n characters of a slice in a string
  */
  peekN = n: slice:
    let
      offset = elemAt slice 0;
    in
      substring offset n (elemAt slice 2);

  # slice operators
  /*
  return a slice removing the first n characters
  */
  dropN = n: slice:
    [ ((elemAt slice 0) + n) ((elemAt slice 1) - n) (elemAt slice 2) ];

  /*
  return a parser that matches the 
  token :: Eq [s] => [s] -> Parser s [s]

  token k xs | k==take n xs = [ (drop n xs, k) ]
           | otherwise = []
             where n = length k
  */
  token = k: slice:
    let tokenLength = stringLength k; in
    if tokenLength + (elemAt slice 0) > (elemAt slice 1)
      then failLocMsg "token" slice "expected ${k} got overflow"
    else

    let doesMatch = (peekN tokenLength slice) == k; in
    if !doesMatch
      then failLocMsg  "token" slice "expected ${k} got ${peekN tokenLength slice}"
    else 

    [ (dropN tokenLength slice) k ];

  # combinators

  # (*>) :: Parser a -> Parser b -> Parser b
  /*
  andThen
    runs the first parser
  */


  # (<*) :: Parser a -> Parser b -> Parser a
  # (<$) :: a -> Parser b -> Parser a
  # a *> b = run a then output b
  # a <* b = run a then b then output a
  # v <$ f = run a then apply f to the value


}
