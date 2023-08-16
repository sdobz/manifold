## Talking to humans with Markdown

Markdown has a graceful path to enhancement, it is palatable in plain text and is trivial to render into html. Headers, links, and embeds give us a story to remember

## Describing dependencies with Nix

Nix is a functional language that is designed to transform source code into software. From an operational perspective it is a DSL used to write build scripts.

## Parser / Testing

Use unit tests to construct the parser

```
nix eval --impure --expr 'import ./nix/markdown.test.nix {}'
```

Markdown source text is fed character by character into parser combinators. Four source text transformations are recognized.

Available tags are:
* `<io print='<expr>' println='<expr>' />` - Print the result of the expression to the output markdown
* `<!-- io -->...<!-- /io -->` - Bounds printed, omitted in subsequent evaluations
* `<with <param>='<default expr>' ... />` - Add attributes to the global scope of every expression
* `<let <binding>='"string value"' ... />` - assign a name to an expression

Potential tags (flake based build):
* `<flake inputs.somePackage.url='...' outputs.${system}.packages.asdf='...' />` - Use nix flake to do a thing

### Syntax issues

All quotes are single quotes.

Including a string in the expression can be done like so:
`<let someBinding='"string ${expandion}"' />`

Remaining parser work:
* Escaping self closing html tags is currently not possible.
* Escaping single quotes is currently not possible
* IO termination is not complete

## Runtime

The source text is eventually resolved to an attribute set (dictionary / hash map / object / etc) that contains a description of all artifacts. This is ALSO a nix derivation to the output directory

```nix
{
    src = ''source text'';
    out = ''evaluated text'';
    ast = {}; # abstract syntax tree for the src text
    manifold = {}; # internal data structures
    global = {}; # Global state
    
    # prelude - 

}
```

Each transformation adds a layer to the fixed-point used to describe the software.

```nix
final: prev: {
    # final represents the final data structure, this enables out-of-order evaluation
    # prev represents the state immediately before this layer runs
}
```