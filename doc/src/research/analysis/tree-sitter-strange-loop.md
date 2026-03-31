# `[talk]` `[seminal]` Tree-sitter - A New Parsing System for Programming Tools

Source: Strange Loop 2018

Link: https://www.thestrangeloop.com/2018/tree-sitter---a-new-parsing-system-for-programming-tools.html

Video: https://www.youtube.com/watch?v=Jes3bD6P0To

Speaker: Max Brunsfeld, GitHub Atom team

Keywords:

- Parsing
- Incremental parsing
- Syntax tree
- Code navigation

Takeaway:

> Tree-sitter takes the approach of a compiler generator:
>
> - GLR parsing
> - Error recovery with GLR parsing also
> - Incremental parsing by reparse but with the old AST as a reference

## Introduction

Developer tools that support multiple languages have historically been built on regex-based code analysis.

Syntax highlighting in Atom, VS Code, and Sublime Text uses TextMate grammars, which are regular-expression pattern sets. Code folding uses indentation heuristics. Symbol search uses pattern matching over raw text. (Confirmed fact!)

Regex-based tooling has a hard ceiling:

- Regex cannot represent nested structure or scope boundaries. Balanced delimiters, block nesting, type-sensitive disambiguation - none of this is expressible.
- Reparsing an entire file on every keystroke is too slow for real-time use. Compiler parsers are designed for batch runs, not interactive editing.
- Incomplete code breaks everything. While typing, code is almost always syntactically invalid. A parser that rejects invalid input cannot be used in an editor.
- Every language needed its own editor plugin written from scratch, with no shared interface.

Tree-sitter was built to fix all of this.

- A library for parsing source code written in C and C++.
- Language-agnostic: Cover a wide range of languages.
- Unified: Unified API for different languages.
- Incremental: No need to reparse the whole file.
- Error recovery: Recover on error instead of aborting.

IDEs' limitations:

- Language-specific.
- No IDEs at the time were incremental.

Language servers' limitations:

- Fixed feature set.
- RPC + parsing from scratch on every changes.
- Each maintain a different set of dependencies.

Tree-sitter's strengths:

- Arbitrary analysis based on syntax tree.
- In-process incremental parsing.
- No dependencies.

## Features

### Syntax Highlighting

- In Sublime Text 3/Vscode/Old Atom, syntax highlighting seems to be plagued with highlighting inconsistencies:
  - Different colors for different types in different contexts.
  - Same variables had different colors.
  - Fields were not highlighted.

- A concrete example: Long lines of code (typically seen in bundled javascript) will break regex-based highlightings.

- Improvements of tree-sitter:
  - None of the problems above.
  - Very fast.

### Code Folding

- Typically based on indentation: Do not always work, especially when some weird code convention is used!

- With tree-sitter:
  - Folding always works.
  - Configurable code folding. This is unlocked by treesitter exposing a consistent AST.

### Extend Selection

- It's the feature where clicking on a position cause semantically larger code items to be selected.
- Works well with multi-cursor.

## How Tree-sitter work

### Writing a Grammar

- Kind of look like most compiler generator.
  - A context-free grammar in tree-sitter is a Javascript value in a file such as `grammar.js`.
  - Compiled into `parser.c`
  - The parser can then be imported.
- Bindings exist.

## Algorithms

### Seminal Paper

Based on Tim A. Wagner (1998)'s paper: Practical algorithms for Incremental Software Development Environments.

- Laid out methodology for efficient code analysis in IDE.
- Basic parsing theory to start with.
- Extend the theory to incremental parsing.
- Formally proofs of performance properties.
- How to handle ambiguities, errors, etc.

### LR Parsing

Good source: wikipedia.org/wiki/LR_parser.

- Looks from start to end without ever backtracking.
- As it reads the characters, they are grouped into tokens, tokens are grouped into subtrees, stored on a stack for consultation. The items on the stack are merged rapidly.

LR Parsing does not work for all languages. Although practically, a well-designed language shouldn't be a problem, but some languages have weird quirks.

Tree-sitter does some unique things based on LR Parsing.

### Extension: GLR Parsing

When ambiguities happen, fork the branch to work on multiple interpretations.

=> Tree-sitter is based on this.

### Error Recovery

- The tree should include error nodes.
- Invalid code is a source of lots of ambiguities.

Tree-sitter uses the same idea of GLR for resolving ambiguities.

### Incremental Parsing

- Walk the current AST tree and mark all nodes that contain the editted positions.
- Reparse like before, but it can now use the old tree as a reference.
