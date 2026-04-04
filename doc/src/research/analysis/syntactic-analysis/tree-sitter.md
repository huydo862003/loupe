# `[tool]` `[tool-dive]` Tree-sitter

Source: tree-sitter

Link: https://tree-sitter.github.io

## Abstract

This article goes into the following aspects of tree-sitter, a parser generator tool and an incremental parsing library:

1. The context in which tree-sitter emerged from & Which problems tree-sitter intended to solve.
2. The design philosophy of tree-sitter.
3. The design inside tree-sitter.
   a. The components of tree-sitter.
   b. The AST structure used in tree-sitter.
   c. The incremental parsing algorithm.
4. How to build a tree-sitter grammar & use it.

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
