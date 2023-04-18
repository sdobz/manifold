# Using Markdown to Tell a Story in Nix

Our cognition is rooted in the tradition of story telling, weaving a tale of motivation and structure

We are responsible for the semantics of a program, what it means and represents in the broader context of the problem being sovled.

Names have power, they give order to the chaos of creation, bridging the gap between our thought and communication.

## Motivation

The order that we tell a story tends to be told is different than what a computer expects. We start with genralities, they start with specifics.

## Markdown

Markdown has a graceful path to enhancement, it is palatable in plain text and is trivial to render into html. Headers, links, and embeds give us just enough to tell a structured story.

## Nix

Nix is a functional language that is designed to transform source code into software. From an operational perspective it is a DSL used to write build scripts.

## Workflow

1. Write markdown files describing the programs semantics
2. Describe the major features of the software
3. Add implementation details to the features
4. Run nixmd on the markdown to produce artifacts and inspect behavior
5. Refine the implementation
6. Package for distribution

## CLI

```bash
$ nixmd runtime <source.md>
Output the path to the runtime used to generate the evaluated text

$ nixmd evaluate <source.md>
  Output the path to the evaluated markdown 

nixmd diff <source.md>
  Output the diff between the source text and the evaluated text

nixmd fix <source.md>
  Overwrite the source markdown with the evaluated text

nixmd watch <source.md> <destination.md>
  Whenever source.md changes evaluate and write it to destination.md

nixmd test
  Run unit tests in bootstrap/*.test.nix
```

### Out



### Garbage Collection

Nix leaves footsteps. These files are linked to in the 

```bash
pwd 
```

# Implementation

## Bootstrap

Implement a version in pure nix, enough to prove the concept. It should fit into a single file less than 500 lines.

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

Potential tags:
* `<fetch <name>='https://<source>' />` - load filesystem or local data into a string
* `<out <attr>='path/to/file.ext' />` - write final state to 

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
    out = ''evaluated text'';
    nixmd = {}; # internal data structures
    global = {}; # Values added to each layer

    arbitraryKeys = "anything"; # transformations can add arbitrary data
    codeBlockIds = "contents of code block"; # Code blocks are added
}
```

Each transformation adds a layer to the fixed-point used to describe the software.

```nix
final: prev: {
    # final represents the final data structure, this enables out-of-order evaluation
    # prev represents the state immediately before this layer runs
}
```

# Theory

## Philosophy

```
 synchronous semantics
asynchronous operations
```

source code runtime

(via axiom)[https://github.com/daly/axiom]:
> To quote Fred Brooks, "The Mythical Man-month"
>
>  "A basic principle of data processing teaches the folly of trying to
>   maintain independent files in synchronization... Yet our practice in
>   programming documentation violates our own teaching. We typically
>   attempt to maintain a machine-readable form of a program and an
>   independent set of human-readable documentation, consisting of prose
>   and flowcharts ... The solution, I think, is to merge the files, to
>   incorporate the documentation in the source program."
>
> "A common fallacy is to assume authors of incomprehensilbe code
> will somehow be able to express themselves lucidly and clearly
>  in comments." -- Kevlin Henney
>
>   "A programmer who cannot explain their ideas clearly in natural
>    language is incapable of writing readable code." -- Tim Daly

A sufficiecntly lucid explanation of your programs behavior can be interpreted as the program itself


# Terms

* Parser - a function that consumes a stream of symbols into another form, and returns the remainder
* Combinator - a higher order function that sequences parsers
* Fixed point - an argument to a function that evaluates to itself. `f(x) = x^2, f(1) == 1`
* Source Text - the original markdown
* Artifact - A file produced by evaluating the source text
* Evaluated Text - the original markdown with all expressions evaluated

# Nontrivial demonstration

Itself in rust

* dependency on an operating system call
* described functionally as a monad on a process
* that executes asynchronously
* matching source text in a file
* producing output that matches an artifact

https://doc.rust-lang.org/cargo/reference/build-scripts.html

rerun-if instructions 

## Reference material

* [tangledown.py](https://github.com/rebcabin/tangledown)
* [nix parsec](https://github.com/kanwren/nix-parsec/blob/master/parsec.nix)
* [nom-rs](https://github.com/rust-bakery/nom)
* [hasura parser-combinator](https://hasura.io/blog/parser-combinators-walkthrough/)
* [functional parsers](http://cmsc-16100.cs.uchicago.edu/2017/Lectures/17/parsers.pdf)
* [monadic runtime](https://dev.to/javalin/zero-boilerplate-zero-runtime-errors-coding-with-monads-26n9)
* [frontmatter - markdown cms](https://frontmatter.codes/)
* [structure editor](https://en.wikipedia.org/wiki/Structure_editor)
* [1982 Syntax-directed editing--towards integrating programming environments](https://apps.dtic.mil/sti/pdfs/ADA117970.pdf)
* [axiom - computer algebra system](https://github.com/daly/axiom)
* [Nixpkgs overlays are monoids ](https://www.haskellforall.com/2022/01/nixpkgs-overlays-are-monoids.html)
* [parsing the nix AST](https://medium.com/@MrJamesFisher/nix-by-example-a0063a1a4c55)
* [writing a json parser in haskell](https://hasura.io/blog/parser-combinators-walkthrough/)
* [Parsec style parser for markdown](https://github.com/tiqwab/md-parser)
* [rust webassembly what it's all about](https://sdfgeoff.github.io/wasm_minigames/what_its_all_about.html)
* [fall-from-grace demo language](https://github.com/Gabriella439/grace)

## TODO

1. ~~Fixed point~~
2. ~~Organize files~~
3. ~~CLI interface~~
4. 

# Motivating project

A rust debugger

that can render interactive widgets

in a browser notebooks

based off of templates

https://rust-analyzer.github.io/

use it to build cad models

based on sdf surfaces

and derive gcode from it
