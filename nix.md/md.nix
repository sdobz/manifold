#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=md.nix --no-substitute
#! nix-shell --pure -i md_nix

/*
Transform markdown into nix that can transform into the markdown
*/

let prev = rec {
  text = '''';
/*
elemAt result 0 = src<T>
elemAt result 1 = value<V>
elemAt result 2 = ctx[]
*/

/*
elemAt ast 0 == offset
elemAt ast 1 == length
elemAt ast 2 == text

How to "query"? Run parser on AST? Results? GC?

md = src<text>
srcMd = [ name|null parent|null children|null ]

Parsers run on linear sequences of symbols
hypothesis: AST is a graph, must be "linearized"?

"Pointer" to a node, stack

next = ctx: if child[0] else next parent

(type system is hidden behind the type of ctx,
how do we know what value is? - it ran through a parser)
parser name must be unique
attrs on a set.......
yea hashmap

{
  <name> = md: final: prev: {
<code body>
  };
}

runtime:
define self, extend with args, evaluate

withinName = srcAst: name: parseAst:
= [ ast "" ]

opt -> match
transform = ast: match (notText ++ [ text ])
= [ ast "match" [ ast  ] ]

Final "result" value is a flake
parseMd = ast: thenSkip (many transforms) eof
= [ ast "md" transformArr ]

final = {src: meta: flake: md:}
*/
prelude = rec {
  ##########
  # nodeps #
  ##########

  inherit (builtins) elemAt substring length stringLength match head tail transforms concatStringsSep replaceStrings filter;

  ###############
  # text parser #
  ###############

  /*
    an md is an array containing [ parents|null child[] src ]
    a src is an array containing [ name offset length text ]
  */
  makeTextMd = text: let src = [ 0 (stringLength text) text ];
    in [ null [] src ];

  /*
    return the text that a slice represents
  */
  dumpMd = slice: substring (elemAt slice 0) (elemAt slice 1) (elemAt slice 2);

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
  fail = name: msg: slice: [ slice null (_: "${name}${loc slice} - ${msg}") ];

  /*
    add an err to the end of the err
  */
  failWith = result: name: msg: slice:
    [ slice null (_: "${(elemAt result 2) null}\n${name}${loc slice} - ${msg}") ];

  /*
    failed - check if the err param is present
  */
  failed = result: length result == 3;

  /*
    dump - print the result if success or error if failure
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
    tag - consume the symbols if matched
  */
  tag = k: slice:
    let tokenLength = stringLength k; in
    if tokenLength > (elemAt slice 1)
      then fail "tag" "expected ${k} got overflow" slice 
    else

    let doesMatch = (peekN tokenLength slice) == k; in
    if !doesMatch
      then fail "tag" "expected ${k} got ${peekN tokenLength slice}" slice
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
      then failWith result "bind" "not successful" slice
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

    fail "opt" "no parser succeeded" slice;

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
      then failWith result "each" "one failed" slice
    else

    let
      newSlice = elemAt result 0;
      value = elemAt result 1;
      newRoot = operator root value;
    in

    mapReduce newRoot operator (tail parsers) newSlice;

  mustConsume = parser: slice:
    let
      beforeOffset = elemAt slice 0;
      result = parser slice;
      afterOffset = elemAt (elemAt result 0) 0;
    in
      if beforeOffset == afterOffset
        then (if failed result then failWith result else fail) "mustConsume" "failed to consume" slice
        else result;

  /*
  eof
    fails if there is remaining input
  */
  eof = slice:
    if elemAt slice 1 != 0
      then fail "eof" "expected EOF" slice
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
  attribute = lexeme (mustConsume (takeRegex "[a-zA-Z0-9_\\.\\-]"));

  /*
  store in set
    parse a value and store it in a set
  */
  storeAttribute = attribute: parser:
    fmap (value: { ${attribute} = value; }) parser;
  
  /*
  annotateText
    assuming value is an attrSet add "text" to the value
  */
  annotateText = parser: slice:
    let
      startOffset = elemAt slice 0;
      result = parser slice;
    in
      if failed result
        then result
      else

      let
        remaining = elemAt result 0;
        endOffset = elemAt remaining 0;
        text = peekN (endOffset - startOffset) slice;
      in

      [ remaining ((elemAt result 1) // { text = text; }) ];

  /*
  assuming each parser returns an attribute set combine all of the results
  */
  combineAttributes = parsers: mapReduce {} (root: value: root // value) parsers;

  /*
  combine
    Run an array of parsers, storing the results of each in an array
  */
  combine = parsers: mapReduce [] (root: value: root ++ [value]) parsers;

  #######
  # AST #
  #######

  # code fence with id

  codeFence = tag "```";
  whitespaceCodeFence = skipThen whitespace codeFence;
  storeCodeId = storeAttribute "id" attribute;
  storeCode = storeAttribute "code" (takeUntil whitespaceCodeFence);
  storeCodeType = pure { "type" = "code"; };
  storeCodeAttrs = combineAttributes [ storeCodeId storeCode storeCodeType  ];
  codeNode = annotateText (between codeFence whitespaceCodeFence storeCodeAttrs);

  # self closing html tag

  htmlTagOpen = tag "<";
  # allowed tag types
  # { token = ".." }
  storeHtmlTagType = lexeme (storeAttribute "type" htmlTagType);
  # `attr=` => {name="attr";}
  equals = lexeme (tag "=");
  storeHtmlTagAttribute = storeAttribute "name" (thenSkip attribute equals);
  # `"value"` => {value="value";}
  quote = tag "'";
  storeHtmlTagValue = storeAttribute "value" (between quote quote (takeUntil quote));
  # {name="attr";value="value";}
  combineHtmlAttributeValue = lexeme (combineAttributes [storeHtmlTagAttribute storeHtmlTagValue]);
  # [ {..} {..} ]
  storeHtmlTagAttributes = lexeme (storeAttribute "attributes" (many combineHtmlAttributeValue));
  # { attributes = [ .. ] }
  storeHtmlTagAttrs = combineAttributes [ storeHtmlTagType storeHtmlTagAttributes ];
  htmlTagClose = tag "/>";
  
  htmlTagWith = tag "with";
  htmlTagLet = tag "let";
  htmlTagIO = tag "io";
  htmlTagFlake = tag "flake";
  htmlTagType = opt [ htmlTagWith htmlTagLet htmlTagIO htmlTagFlake ];

  htmlTagNode = annotateText (between htmlTagOpen htmlTagClose storeHtmlTagAttrs);

  # io output
  ioStart = tag "<!-- io -->";
  ioEnd = tag "<!-- /io -->";
  ioNode = annotateText (between ioStart ioEnd (fmap (_: {type = "io-skip";}) (takeUntil ioEnd)));

  # the rest of the text
  notPlainText = opt [ codeNode htmlTagNode ioNode ];

  storePlainTextType = pure { "type" = "text"; };
  plainText = mustConsume (takeUntil notPlainText);
  storePlainText = storeAttribute "text" plainText;
  plainTextNode = combineAttributes [ storePlainText storePlainTextType ];


  parseNixmd = thenSkip (many nodes) eof;

  ###########
  # runtime #
  ###########

  escape = replaceStrings [ "\n" "\r" "\t" "\\" "\"" "\${" ] [ "\\n" "\\r" "\\t" "\\\\" "\\\"" "\\\${" ];
  quoteNodeText = node: "\"${escape node.text}\"";

  # it feels like this could be written as a parser over the ast rather than string construction...
  overlay = evalLines: outLines:
    "    (final: prev: with final.global; rec {\n${
      if length evalLines > 0 then concatStringsSep "" (map (evalLine: "      ${evalLine}\n") evalLines) else ""
    }${
      if length outLines > 0 then "      out = prev.out + builtins.concatStringsSep \"\" [\n${concatStringsSep "" (map (outLine: "          ${outLine}\n") outLines)}      ];\n" else ""
    }    })\n";

  nodeOverlay = {
    "with" = node: overlay (
      map ({name, value}: "global.${name} = if builtins.hasAttr \"${name}\" __args then __args.\${\"${name}\"} else ${value};") node.attributes
    ) [ (quoteNodeText node) ];
    "let" = node: overlay (
      map ({name, value}: "${name} = ${value};") node.attributes
    ) [ (quoteNodeText node) ];
    "io" = node:
      let
        printlns = filter (attribute: attribute.name == "println") node.attributes;
        printlnStrings = foldl' (all: attr: all ++ [ "\"\\n\"" "(${attr.value})" "\"\\n\"" ]) [] printlns;
        prints = filter (attribute: attribute.name == "print") node.attributes;
        printStrings = map (attr: "(${attr.value})") prints;
      in
        overlay [] ([ (quoteNodeText node) "\"<!-- io -->\"" ] ++ printStrings ++ printlnStrings ++ [ "\"<!-- /io -->\"" ]);
    "io-skip" = node: "";
    "code" = node: overlay [ "${node.id} = \"${escape node.code}\";" ] [ (quoteNodeText node) ];
    # "text" = node: overlay [] [ (quoteNodeText node) ];
    "flake" = node: overlay [] [];
  };

  # language syntax

  nodes = opt [
    plainTextNode
    htmlTagNode
    codeNode
    ioNode
  ];


  nodeOverlays = ast: map (node: (nodeOverlay.${node.type} node)) ast;

  #######
  # Fix #
  #######

  dumpRuntime = runtimePath: filename: let
    contents = readFile filename;
    result = parseNixmd (makeSlice contents);
  in
    if failed result
      then dump result
    else
    
    let ast = elemAt result 1; in
    
    nixmdRuntime (readFile runtimePath) ast;

  nixmdRuntime = runtime: ast:
    replaceStrings
      [ "/* overlays */" ]
      [ ( concatStringsSep "\n" (nodeOverlays ast) ) ]
      runtime;

  traceID = id: trace id id;
}; }; 
in prev
