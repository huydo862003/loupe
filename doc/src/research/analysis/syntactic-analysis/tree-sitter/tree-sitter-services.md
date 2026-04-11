# Tree-sitter Services and Applications

Source: tree-sitter

Link: https://tree-sitter.github.io

## Takeaways

- Services decouple from grammar: Syntax highlighting, code navigation, and language injection are **query-based**, not grammar-based. Grammar describes "what is", queries describe "how to use it".
- **Capture names** are standardized (e.g., `@keyword`, `@definition.function`) instead of language-specific logic. Same queries work across all tools and editors.
- Scope and context via queries: Local variable tracking and language injection are **queries**, not lexical features. This keeps grammars simpler while enabling sophisticated analysis.
- **Standardization** enables portability: Same `.scm` query file and role/kind vocabulary work across editors and languages.
