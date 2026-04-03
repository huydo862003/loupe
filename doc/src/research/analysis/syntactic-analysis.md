# Syntactic Analysis

Syntactic analysis is about parsing source code into structured representations, typically abstract syntax trees (ASTs) or concrete syntax trees (CSTs). This is the first step in any code analysis pipeline: before you can reason about symbols, types, or data flow, you need a reliable parse of the source text.

The key concerns here are incremental parsing (re-parsing only what changed after an edit), error recovery (producing a useful tree even when the code is incomplete or malformed), and multi-language support (handling many grammars without writing a custom parser for each).

For Loupe, the parser must support many languages through shared infrastructure (language-agnostic), patch existing trees on edits rather than re-parse from scratch (incremental), and stay off the critical path, since everything downstream depends on it (fast).

## Subpages

- [Tree-sitter - Strange Loop 2018](syntactic-analysis/tree-sitter-strange-loop.md) and [Tree-sitter](syntactic-analysis/tree-sitter.md): the dominant incremental parsing framework, designed for editor use cases. Produces concrete syntax trees with error recovery, supports many languages via community grammars.
- [Roslyn](syntactic-analysis/roslyn.md): the .NET Compiler Platform, which exposes rich syntax tree APIs including full-fidelity syntax trees with trivia, incremental parsing, and syntax walkers/rewriters for C# and VB.NET.
- [Spoofax Language Workbench](syntactic-analysis/spoofax.md): a platform for defining languages declaratively, including their syntax, name binding, and type systems.
