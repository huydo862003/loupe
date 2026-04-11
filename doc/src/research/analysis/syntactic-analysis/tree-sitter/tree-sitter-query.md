# Tree-sitter Query System

Source: tree-sitter

Link: https://tree-sitter.github.io

## Takeaways

- Separate grammar from navigation: **Queries** enable applications without modifying grammar, keeping grammar focused on parsing and semantics.
- **Declarative patterns** are more maintainable and portable than imperative traversal code written in each binding language.
- **Portability**: The same `.scm` query file works across all language bindings and tools for standardized highlighting and navigation.
- **Architecture**: C core extracts queries; language bindings evaluate predicates and directives. This splits parsing (fast, in C) from filtering (flexible, in bindings).

## Quick Reference

| Pattern        | Purpose                | Example                                     |
| -------------- | ---------------------- | ------------------------------------------- |
| Capture        | Extract a matched node | `(identifier) @name`                        |
| Wildcard       | Match any node         | `(_)` matches any named node                |
| Field name     | Match by field         | `left: (identifier)` matches specific child |
| String literal | Match anonymous node   | `"if"` or `"("`                             |
| Negation       | Must not have field    | `!type_parameters`                          |
| Quantifier     | Repetition             | `(arg)* ` or `(arg)+`                       |
| Alternation    | Match one of several   | `["if" "while" "for"]`                      |
| Anchor         | Position constraint    | `.` before/after/between children           |
| Predicate      | Conditional filter     | `(#eq? @name "foo")`                        |
| Directive      | Metadata attachment    | `(#set! language "javascript")`             |

## Syntax

- Query: A series of patterns that is used to extract certain code structure out of the source code.
- Pattern: An S-expression matching a certain set of syntax nodes.

Pattern's structure:

```racket
(<node-type> ...<children-patterns>)
```

For example:

```racket
(binary_expression (number_literal) (number_literal))
```

would match a binary expression with two children of type number literal.

Children can be omitted, the remaining nodes would described the expected order of children nodes.

```racket
(<node-type> <child-1> <child_2>)
;            ^^^^^^^^  ^^^^^^^^
;            <child_1> needs only precede <child_2>, some other nodes may be in between
```

For example:

```racket
(binary_expression (number_literal))
```

would match any binary expression with a number literal as its child.

**Fields**: Child patterns can be named to be correspondent with field names, and recommended so:

```racket
(assignment_expression
  left: (member_expression
    object: (call_expression)))
```

If in the grammar rule `assignment_expression`, there are 2 field named `left` and `object`, then this query would return all `assignment_expression`s whose `left` and `object` are `member_expression` and `call_expression`.

**Negated fields**: A field name prefixed with `!` indicates a lack of such field.

```racket
(class_declaration
  name: (identifier) @class_name
  !type_parameters)
```

**Anonymous nodes**: `(<pattern>)` only applies to named nodes. To reference anonymous nodes, double quotes the textual contents.

```racket
(binary_expression
  operator: "!="
  right: (null))
```

**Wildcard nodes**: `_` and `(_)` are used to matched any nodes. The only difference is that `(_)` can match any named node and `_` can match any named/anonymous node.

```racket
(call (_) @call.inner)
;         ^^^^^^^^^^^
;         any nodes inside a call
```

**`ERROR` nodes**: An unrecognized piece of text and can also be queried.

```racket
(ERROR) @error-node
```

**`MISSING` nodes**: Missing expected nodes will be inserted as special missing nodes in the syntax tree.

- To recover from syntax errors, the parser inserts zero-width "phantom" tokens (like a forgotten semicolon) to keep the syntax tree valid.
- Instead of allocating a completely new, heavyweight structural node in memory, it simply attaches an internal "missing" flag to that generated token.
- This approach saves memory and processing power because the token occupies zero physical characters in your source code.

> Something's a bit confusing here - Tree-sitter seems to mention nodes and tokens interchangeably.

```racket
(MISSING) @missing-node
(MISSING identifier) @missing-identifier
(MISSING ";") @missing-semicolon
```

**Supertype nodes**: Supertypes in queries can be used to match any subtypes.

> Supertype here means roughly like supertype in OOP: A ggrammar rule that can specializes to multiple sub-grammar rules. The supertype itself won't be a standalone node in the AST, rather like a union type though.

```racket
(expression) @any-expression
; ^^^^^^^^^
; match any subtypes of `expression`
```

Match specific subtypes (named or anonymous):

```racket
(expression/binary_expression) @binary-expression
(expression/"()") @empty-expression
```

## Operators

**The `@` operator**: Specific nodes in the pattern can be extracted out by suffixing the node with a **capture name**

```racket
(assignment_expression
  left: (identifier) @the-function-name
                    ; ^^^^^^^^^^^^^^^^^
  right: (function))
```

**The quantification operators `+` & `*`**: Similar to those in regular expressions.

**Sequence group**:

- The sequence group `()` creates an anonymous block of sibling nodes.
- Its primary use case is grouping nodes so you can apply quantifiers (`*`, `+`, `?`) to an entire repeating sequence.
- Example: Matching a repeating comma-separated list using `( (",") (identifier) )*`.
- It does not enforce strict adjacency; undeclared nodes can still appear between the grouped items.
- Use `()` to repeat a pattern, and use `.` (the anchor operator, see below) to glue nodes tightly together.

**Alternation operator `[]`**: Similar to character classes in regular expressions.

```racket
[
  "break"
  "delete"
  "else"
  "for"
  "function"
  "if"
  "return"
  "try"
  "while"
] @keyword
```

The alternants can be quantified.

**Anchor operator `.`**: Used to constrain the ways in which child patterns are matched, with different behaviors based on its position in a query.

- Before the first child within the parent pattern: That child is only matched when it's the first **named node** of the parent.

```racket
(array . (identifier) @the-element)
;         ^^^^^^^^^^
;         must be the first
```

Without the anchor above, `@the-element` would be bound to every identifier in the array, and accessing it would return an arrays of all identifiers.

- After the last child within the parent pattern: Similarly to the above case.

- Between two child patterns: Match immediate siblings.

```racket
(dotted_name
  (identifier) @prev-id
  .
  (identifier) @next-id)
```

Note that anonymous nodes are not taken into account.

## Predicates

**The predicate syntax `#...?`**: Add arbitrary conditions or metadata to a pattern. Predicate names start with `#` and end with `?`, and can accept captures or strings as arguments.

**The `eq?` predicate**: Compares a capture's text against a string or another capture.

- Includes variants: `#not-eq?`, `#any-eq?`, `#any-not-eq?`.
- By default, quantified captures require _all_ matched nodes to pass the predicate. The `any-` prefix overrides this to match if _at least one_ node passes.

```racket
((identifier) @variable.builtin
  (#eq? @variable.builtin "self"))
```

```racket
(
  (pair
    key: (property_identifier) @key-name
    value: (identifier) @value-name)
  (#eq? @key-name @value-name)
)
```

**The `match?` predicate**: Matches a capture's text against a regular expression.

- Also supports the `not-` and `any-` prefixes.

```racket
((identifier) @constant
  (#match? @constant "^[A-Z][A-Z_]+"))
```

**The `any-of?` predicate**: Checks if a capture's text strictly equals any string in a provided list.

```racket
((identifier) @variable.builtin
  (#any-of? @variable.builtin
        "arguments"
        "module"
        "console"))
```

**The `is?` predicate**: Asserts that a capture has a specific internal property (e.g., using `#is-not? local` to ensure a matched variable is not a local variable).

## Directives

**The directive syntax `#...!`**: Associates arbitrary metadata with a pattern or alters its output. They function similarly to predicates but end with `!` instead of `?`.

**The `set!` directive**: Associates arbitrary key-value metadata pairs with a matched pattern (commonly used for language injections).

```racket
((comment) @injection.content
  (#match? @injection.content "/[*\/][!*\/]<?[^a-zA-Z]")
  (#set! injection.language "doxygen"))
```

**The `select-adjacent!` directive**: Takes two capture names and filters the first capture's text so that only nodes adjacent to the second capture are preserved.

**The `strip!` directive**: Takes a capture and a regular expression, removing any matched text from that capture's final output.

> Note
>
> - The core Tree-sitter C library does not execute predicates or directives.
> - It simply extracts them from your query and passes them along as raw metadata.
> - It is entirely up to the higher-level bindings (like Rust, Python, JS, WASM) to read that metadata and actually run the filtering logic (like evaluating `#eq?`).
>
> So, if a predicate isn't working, it might be because the specific language binding you are using hasn't implemented support for it yet, not necessarily because your query syntax is wrong.

## Query API

**Creating a query (`ts_query_new`)**: You create a query by passing in the language and a string containing your patterns.

- If it fails, `error_offset` indicates the exact byte where it failed.
- `error_type` indicates the cause (`Syntax`, `NodeType`, `Field`, or `Capture`).

```c
TSQuery *ts_query_new(
  const TSLanguage *language,
  const char *source,
  uint32_t source_len,
  uint32_t *error_offset,
  TSQueryError *error_type
);
```

**Thread safety and state (`TSQuery` vs `TSQueryCursor`)**:

- `TSQuery`: The parsed query itself. It is immutable and can be safely shared across multiple threads.
- `TSQueryCursor`: Holds the state required to actually run the query. It is not thread-safe, but you can reuse a single cursor for many executions to save memory.

```c
TSQueryCursor *ts_query_cursor_new(void);
```

**Executing a query (`ts_query_cursor_exec`)**: Prepares the cursor to find matches within a specific syntax node (usually the root node of your parsed code).

```c
void ts_query_cursor_exec(TSQueryCursor *, const TSQuery *, TSNode);
```

**Iterating matches (`ts_query_cursor_next_match`)**: Steps through the successful query matches one by one.

- Returns `true` and populates the `match` structure, or `false` when there are no more matches.
- `TSQueryMatch` contains metadata (which pattern matched) and an array of captured nodes.
- `TSQueryCapture` contains the actual `TSNode` from the syntax tree and the index of its capture name.

```c
typedef struct {
  TSNode node;
  uint32_t index;
} TSQueryCapture;

typedef struct {
  uint32_t id;
  uint16_t pattern_index;
  uint16_t capture_count;
  const TSQueryCapture *captures;
} TSQueryMatch;

bool ts_query_cursor_next_match(TSQueryCursor *, TSQueryMatch *match);
```
