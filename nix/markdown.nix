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
  
  /*
  takeRegex - consume characters until the regex does not match
  */
  takeRegex = regex:
    takeWhile (searchSlice: match regex (peekN 1 searchSlice) != null);

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
  mapReduce
    starting with root
    apply operator
    to the value of each parser
  */
  mapReduce = root: operator: parsers: slice:
    if length parsers == 0
      then [ slice root ]
    else

    let result = (head parsers) slice; in
    if failed result
      then failWith result "each" slice "one failed"
    else

    let
      newSlice = elemAt result 0;
      value = elemAt result 1;
      newRoot = operator root value;
    in

    mapReduce newRoot operator (tail parsers) newSlice;

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

  whitespace = takeRegex "[ \t\n]";

  /*
  lexeme
    run the parser and consume any remaining whitespace
  */  
  lexeme = parser: thenSkip parser whitespace;

  /*
  attribute
    take something that can resonably be an attribute
  */
  attribute = lexeme (takeRegex "[a-zA-Z0-9_]");

  /*
  store in set
    parse a value and store it in a set
  */
  storeAttribute = attribute: parser:
    fmap (value: { ${attribute} = value; }) parser;

  /*
  assuming each parser returns an attribute set combine all of the results
  */
  combineAttributes = parsers: mapReduce {} (root: value: root // value) parsers;

  /*
  combine
  */
  combine = parsers: mapReduce [] (root: value: root ++ [value]) parsers;

  # code fence with id

  codeFence = tag "```";
  storeCodeToken = pure { "token" = "code"; };
  storeCodeId = storeAttribute "id" attribute;
  storeCodeText = storeAttribute "text" (takeUntil codeFence);
  storeCodeAttrs = combineAttributes [ storeCodeToken storeCodeId storeCodeText ];
  codeBlockToken = between codeFence codeFence storeCodeAttrs;

  # self closing html tag

  htmlTagOpen = tag "<";
  # allowed tag types
  htmlTagArg = tag "arg";
  htmlTagLet = tag "let";
  htmlTagNix = tag "nix";
  htmlTagType = opt [ htmlTagArg htmlTagLet htmlTagNix ];
  # { token = ".." }
  storeHtmlTagType = lexeme (storeAttribute "token" htmlTagType);
  # attr=
  equals = lexeme (tag "=");
  htmlTagAttribute = thenSkip attribute equals;
  # "value"
  quote = tag "\"";
  htmlTagValue = between quote quote (takeUntil quote);
  # [ "attr" "value" ]
  combineHtmlAttributeValue = lexeme (combine [htmlTagAttribute htmlTagValue]);
  # [ [..] [..] .. ]
  storeHtmlTagAttributeValues = lexeme (storeAttribute "attributes" (many combineHtmlAttributeValue));
  # { attributes = [ .. ] }
  storeHtmlTagAttrs = combineAttributes [ storeHtmlTagType storeHtmlTagAttributeValues ];
  htmlTagClose = tag "/>";

  htmlTagToken = between htmlTagOpen htmlTagClose storeHtmlTagAttrs;

  /*
  execution
  */
  evalFile = filename: let
    contents = readFile filename;
  in
    stringLength contents;
}
