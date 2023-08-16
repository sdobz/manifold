# Storytelling

Our cognition is rooted in the tradition of story telling, weaving a tale of motivation and structure

We are responsible for the semantics of a program, what it means and represents in the broader context of the problem being sovled.

Names have power, they give order to the chaos of creation, bridging the gap between our thought and communication.

## Naming things is hard

Understanding a line of code requires that you understand both what the programmer intends it to do, and what the computer actually does with it

## Semantic system

Manifold attachs a semantic to specific parts of human readable text, typically described in the form of an interactive code session a la `notebooks`.

Manifold can then synchronize these semantics with  

## Natural Language

>   "A programmer who cannot explain their ideas clearly in natural
>    language is incapable of writing readable code." -- Tim Daly


## Talking to humans with Markdown

Markdown has a graceful path to enhancement, it is palatable in plain text and is trivial to render into html. Headers, links, and embeds give us a story to remember

## Describing dependencies with Nix

Nix is a functional language that is designed to transform source code into software. From an operational perspective it is a DSL used to write build scripts.

## Computationally effecient Rust

Rust is a general purpose programming language with a robust type system, mature tooling, and is well suited to 

### Examples

## Community

Since a semantic is internally complete, you can easily share them with other people and compose them together.

## Workflow

1. Write markdown files describing the programs semantics
2. Describe the major features of the software
3. Use parsers to agree with the computer (runtime vs 
)
4. Run manifold on the markdown to produce artifacts and inspect behavior
5. Refine the implementation
6. Package for distribution

## CLI

```bash
$ manifold help
  Print this text

$ manifold test


$ manifold evaluate --help <source.md>
  Build and execute a runtime for the source file and output the evaluated text

manifold diff --help <source.md>
  Output the diff between the source text and the evaluated text

manifold fix --help <source.md>
  Overwrite the source markdown with the evaluated text

manifold watch --help <source.md>
  Whenever the source markdown 

manifold test
  Run all tests

manifold <source.md> - --help
Use stdin
```

## Diff

When the contents of a file don't agree 

### Garbage Collection

Nix leaves footsteps. These files are linked to in the 

```bash
pwd 
```

# Implementation

In each supported language: Parse the source text, and build a runtime binary in that language. This runtime can be fed the same source text again. If it does not match it exits with an error and emits a diff file

## UX

Type checks are done by line. Lines are covered in states:
* Parsed character by character
* Undo tracked - history color (bloom filter)
* Deterministic when running isolated, allow cumulative diffing for language editor? Deterministic after save

* Async actions collected and reduced
* Execute async actions with a debounce
* Find the most recently changed line, start there
* Match text since last ran, replace

* If something fails a type check highlight it red

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

## Introspection

A slice is part of a stream of bytes. Each slice has metadata describing where it came from. Slices should be (??? able to be recreated from the serialization of this metadata)

As a result of recognizing the stream of bytes side effects can occur.

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

A fixed point is where the future and the past agree, where the evaluation is what you expect and the result is deterministic

Build your program like a proof, with deductive reasoning and arbitrary order

- Me

## Type and Effect system

A functional perspective on this code is that it describes types in terms of streams of bytes, 

https://en.wikipedia.org/wiki/Effect_system

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
* [scripting with nix](http://www.chriswarbo.net/projects/nixos/scripting_with_nix.html)
* [error context in rust](https://udoprog.github.io/rust/2023-05-22/abductive-diagnostics-for-musli.html)
* [parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)

## TODO

1. ~~Fixed point~~
2. ~~Organize files~~
3. ~~CLI interface~~
5. Readme as entrypoint
6. Polyglot cli

Head dump:
md.nix, when imported, turns into a flake
The default app of this flake can parse markdown into a flake
Which attempts to fix the markdown

md.nix - a nix script that can interpret markdown into a flake
nix-md - a bin produced by that flake that can interpret markdown

# Motivating project

## Bash slideshow

Use markdown slideshow ecosystem (marp) to produce bash tutorials

## Rust 3d prototype environment

A rust debugger

that can render interactive widgets

in a browser notebooks

based off of templates

https://rust-analyzer.github.io/

use it to build cad models

based on sdf surfaces

and derive gcode from it

## Web scraping

Write parsers for each website, use fixed point for when scraping happens etc

## Table of contents

## Autocomplete

## Rhythmic Video Editing

Define "important point" in each shot
Specify a bpm, trim shots to the beat

Semantically identify the important thing

## Patterns in languages

* Create parsers that can recognize cases of patterns
* Describe pattern in a doc, then list instances of it
* Jr programmer: add this thing

## FEATURES.nix.md

Runs tests, add/remove checkmarks with matching nameso

## ideas

"vendor" tag that takes a url and sends it to 