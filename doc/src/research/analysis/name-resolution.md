# Name Resolution

Name resolution is about figuring out what each identifier in the code actually refers to. Given a variable, function call, or type annotation, which declaration does it point to? This requires understanding scoping rules, imports, visibility modifiers, and the module system of the language in question.

Getting this right is critical for go-to-definition, find-all-references, and rename refactoring. The approaches here range from formal scope graph models to Datalog-based relational encodings to tree-sitter-based graph construction DSLs.

Scoping rules vary wildly across languages, so Loupe needs a resolution model that encodes rules as data, not code (language-agnostic). When a file changes, only affected names should be re-resolved (incremental). And since every go-to-definition and rename triggers resolution, it has to be instant (fast).

## Subpages

- [Scope Graph](name-resolution/scope-graph.md): a formal model where scoping rules are encoded as a graph of declarations, references, and scope edges. Language-agnostic by design.
- [Stack Graphs](name-resolution/stack-graphs.md): GitHub's adaptation of scope graphs for language-agnostic code navigation, designed to work without a full type checker.
- [`tree-sitter-graph` DSL](name-resolution/tree-sitter-graph.md): a DSL for constructing graphs (including stack graphs) directly from tree-sitter parse trees.
