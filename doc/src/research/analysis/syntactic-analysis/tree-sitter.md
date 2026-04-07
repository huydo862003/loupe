# `[tool]` `[tool-dive]` Tree-sitter

Source: tree-sitter

Link: https://tree-sitter.github.io

## Abstract

This article goes into the following aspects of tree-sitter, a parser generator tool and an incremental parsing library:

1. The context in which tree-sitter emerged from & Which problems tree-sitter intended to solve.
2. The design philosophy of tree-sitter.
3. Concepts/Features of tree-sitter.
4. The design inside tree-sitter.
   a. The components of tree-sitter.
   b. Code analysis: The incremental parsing algorithm.
   c. Code analysis: The AST structure exposed by tree-sitter.
   d. Code query: The query system.
5. How to build a tree-sitter grammar & use it.

## Introduction

Tree-sitter is:

- A parser generator tool, taking a grammar described in JS and yielding an incremental parsing library in C.
- Runtime in various languages to load the generated C library.

## The Context

Covered in [the Strange Loop talk](./tree-sitter-strange-loop.md).

Roughly:

- Before tree-sitter, most IDE (vscode, sublime) features (such as syntax-highlighting, code folding) were implemented in terms of regexes.
- This caused a lot of problems:
  - Inconsistent highlighting: The same type of tokens were not in the same color in some edge cases (weird formatting convention) or even in some pretty common case.
  - Regexes highlighting can easily break, such as when inspecting the bundled JS.
  - Slow (at least slower than tree-sitter).
- So, tree-sitter was created to addressed these issues, reporting:
  - Faster processing of source code.
  - Consistent highlighting.
  - Enable many DX features.
  - Unified interface for toolings.

## Design Philosophy

Some of the design philosophy of tree-sitter can be found in [the Strange Loop talk](./tree-sitter-strange-loop.md):

- Arbitrary analysis based on syntax tree.
- In-process incremental parsing.
- No dependencies.

On the tree-sitter homepage, tree-sitter aims to, quoted in verbatim, be:

- **General** enough to parse any programming language
- **Fast** enough to parse on every keystroke in a text editor
- **Robust** enough to provide useful results even in the presence of syntax errors
- **Dependency-free** so that the runtime library (which is written in pure C11) can be embedded in any application

Addtional source: https://zed.dev/blog/syntax-aware-editing.

- Tree-sitter was designed with IDE-centric workflow in mind.
- Concrete syntax tree to retain locations of all tokens in the source to support many editor features.
- Support flexible queries (tree-queries) to match on some specific set of structural patterns. -> Basically, tree-sitter supports both generating the tree & querying the tree, totally obviating the need to write custom tree traversal code. Supporting a new language = tree-sitter parser & a set of queries.
  > This is pretty much a (syntactic) code analysis and query tool like Loupe wants to be.

## Practical Use Cases

Source: https://zed.dev/blog/syntax-aware-editing.

- These features in Zed are implemented using tree-sitter queries:
  - Syntax highlighting (example query from their blog):

    ```racket
    ["do" "for" "while"] @keyword

    (function
    name: (identifier) @function)

    (pair
    key: (property_identifier) @function.method
    value: [(function) (arrow_function)])
    ```

  - Symbol outlines (example query from their blog) - fuzzy search symbols within another symbol/context:

    ```racket
    (impl_item
      "impl" @context
      trait: (_)? @name
      "for"? @context
      type: (_) @name) @item

    (function_item
      (visibility_modifier)? @context
      (function_modifiers)? @context
      "fn" @context
      name: (_) @name) @item
    ```

  - Auto-indentation (example query from their blog):

    ```racket
    (statement_block "}" @end) @indent

    [
      (assignment_expression)
      (member_expression)
      (if_statement)
    ] @indent
    ```

  - Language injection (example query from their blog) - sometimes, inside a source code in a language comes another language (e.g. HTML & JS or Rust macro):

    ```racket
    (script_element
      (raw_text) @content
      (#set! "language" "javascript"))
    ```

    > Kind of look like Lexer mode in ANTLR.
