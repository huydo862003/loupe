# Code Intelligence Platforms

Code intelligence platforms are end-to-end systems that combine parsing, analysis, indexing, and querying into a cohesive developer experience. These are the tools that actually ship code navigation, diagnostics, and refactoring to users, whether through an IDE (via LSP), a web UI (Sourcegraph), or a compiler API (Roslyn).

Studying these platforms helps identify what a complete code intelligence stack looks like and where the integration points are. Most of them are tied to one language or ecosystem. Loupe wants the same depth of features, but language-agnostic, incremental, and fast by default.

## Subpages

- [Code Property Graphs (CPG) & the Joern Framework](code-intelligence-platforms/cpg.md): a graph-based representation that merges ASTs, control flow graphs, and program dependence graphs into a single queryable structure.
- [Language Server Protocol (LSP)](code-intelligence-platforms/lsp.md): the standard protocol for IDE-backend communication, decoupling language tooling from editors.
- [Using Roslyn APIs to Build a .NET IL Interpreter](code-intelligence-platforms/roslyn-il-interpreter.md): a practical case study of building on top of Roslyn's semantic model.
- [Sourcegraph](code-intelligence-platforms/sourcegraph.md): a code intelligence platform providing search, navigation, and insights across large codebases via a web UI.
- [Cymbal](code-intelligence-platforms/cymbal.md): a code intelligence tool.
