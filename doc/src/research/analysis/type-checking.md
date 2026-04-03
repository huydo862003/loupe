# Type Checking

Type checking is about verifying that operations in the code are applied to values of compatible types. Beyond catching errors, type information powers features like auto-completion, signature help, and more precise code navigation.

The challenge for a tool like Loupe is doing this in a language-agnostic or at least language-parametric way, without reimplementing a full type checker for every supported language.

This is where the language-agnostic goal is most in tension with correctness. Loupe can't reimplement every language's type system, so the question is how much it can infer in a language-parametric way and when to defer to external checkers (e.g., via LSP). Whatever type reasoning Loupe does must be incremental (no full re-checks on edits) and fast enough to not block the user or AI agent.

## Subpages

- [Polymorphic Type Inference Engines & Template Checking](type-checking/polymorphic-type-inference-engines-template-checking.md): research on inference algorithms that can handle parametric polymorphism and template-style generics across languages.
- [Statix & Scopes-as-Types](type-checking/statix-scope-as-types.md): a constraint-based specification language that builds on scope graphs, treating scopes and types uniformly.
- [Relational Semantics via Datalog & Souffle](type-checking/relational-semantics-datalog-souffle.md): encoding name resolution as Datalog relations, enabling declarative and incremental resolution using the Souffle engine.
- [Lady Deirdre Framework](type-checking/lady-deirdre.md): a Rust framework for building incremental compilers and analyzers, with a focus on error-resilient parsing.
