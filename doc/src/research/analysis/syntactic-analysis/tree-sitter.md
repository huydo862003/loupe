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

## Resources for the Design & Implementation

- General design: [tree-sitter doc](https://tree-sitter.github.io/tree-sitter/using-parsers/1-getting-started.html)

- Parsing functionality:
  - [tree_sitter/api.h header file](https://github.com/tree-sitter/tree-sitter/blob/master/lib/include/tree_sitter/api.h)
  - [Other language bindings similar to tree_sitter/api.h, especially the official ones](https://tree-sitter.github.io/tree-sitter/index.html#language-bindings).

## The Components of Tree-sitter

1. The core:
   1. The language rules in `TSLanguage` (see [API/User-facing Design](#apiuser-facing-design))
   2. The `TSParser` which carries out incremental parsing based on `TSLanguage` & The incremental GLR parsing/re-parsing algorithm itself (see [API/User-facing Design](#apiuser-facing-design))
   3. `TSTree` and `TSNode` are the well-known interfaces for tree-sitter API (see [API/User-facing Design](#apiuser-facing-design))
2. The high-level layers:
   1. Tree edit API (see [Tree Edit](#tree-edit))
   2. Language injection support (see [Language Injection Support](#language-injection-support))
   3. Concurrency support (see [Concurrency Support](#concurrency-support))
   4. Efficient tree traversal API (other than fetch nodes and their fields) (see [(Efficient) Tree Traversal](#efficient-tree-traversal))
   5. Tree query API (see [Tree Query](#tree-query))

## API/User-facing Design

Four main object types:

1. Languages (`TSLanguage` in the C API).
   - An (opaque) object representing the programming language parsing logic/rules (not the current parsing states).
   - The implementations for specific Language objects are generated by tree-sitter.
2. Parsers (`TSParser` in the C API).
   - The language parser itself, which can be assigned a language object.
   - Can accept some source code and produce a `TSTree`.
3. Syntax trees (`TSTree` in the C API).
   - The syntax tree of a piece of a source code.
   - Composed of `TSNode`s.
   - Can be editted to produce a new `TSTree`.
4. Syntax nodes (`TSNode` in the C API).
   - A single node in the syntax tree.
   - Tracks start and end positions & relation to other nodes.

Example flow using a generated parser in C:

1. Create a `TSParser` instance.
2. Set the `TSParser` with a `TSLanguage`.
3. Trigger the parser to produce a `TSTree`.
4. Query the `TSTree` and retrieve `TSNode`s.

Example program:

```c
#include <stdio.h>
#include <string.h>
#include <tree_sitter/api.h>

// **Language**
// Declare the external grammar function. This is generated by Tree-sitter
// and contains all the syntax rules for JSON.
const TSLanguage *tree_sitter_json(void);

int main() {
    // The source code we want to parse
    const char *source_code = "{\"name\": \"Gemini\"}";
    uint32_t source_len = strlen(source_code);

    // **Parser**
    // Create the parser and equip it with the JSON language grammar
    TSParser *parser = ts_parser_new(); // Dynamically allocated
    ts_parser_set_language(parser, tree_sitter_json());

    // **Parse tree**
    // Instruct the parser to read the string and build the entire tree.
    TSTree *tree = ts_parser_parse_string(
        parser,
        NULL,           // Previous tree (used for incremental parsing, NULL for first time)
        source_code,    // The actual code
        source_len      // Length of the code
    );

    // **Tree node**
    // Extract the absolute top node of the tree to begin our traversal.
    TSNode root_node = ts_tree_root_node(tree);


    // Cleanup memory
    ts_tree_delete(tree);
    ts_parser_delete(parser);

    return 0;
}
```

### Parser API

`TSParser` can accept input via a string buffer (`const * string` with `uint32_t length`) or via a custom `TSInput` (an interface with methods to consume the buffer).

- `ts_parser_parse_string`: Accept a string buffer - support incremental parsing.
  ```c
  TSTree *ts_parser_parse_string (
    TSParser *self,
    const TSTree *old_tree, // possibly for incremental parsing like in the Strange Loop talk
    const char *string,
    uint32_t length
  )
  ```
- `ts_parser_parse`: Accept a custom data structure consumer:
  ```c
  TSTree *ts_parser_parse(
   TSParser *self,
   const TSTree *old_tree, // possibly for incremental parsing like in the Strange Loop talk
   TSInput input
  );
  ```

### Syntax Nodes (& Trees)

DOM-style interface for inspection:

- `ts_node_type`: The identifier for the node type, corresponding to the grammar rule it represents.
- `ts_node_start_byte`/`ts_node_end_byte`: Raw byte offsets.
- `ts_node_start_point`/`ts_node_end_point`: Zero-based editor coordinates (row/column). Only `\n` is considered a newline (which means `\r` is part of the previous line?).

- A `TSTree` has root nodes: `ts_tree_root_node`.
- A `TSNode` has children as a flat homogeneous array: `ts_node_child` with an index to the children.
- A `TSNode` has siblings: `ts_node_next_sibling`/`ts_node_prev_sibling`, which may return a **null node**.
- A `TSNode` has a parent: `ts_node_parent`.

#### Named and Anonymous Nodes

CSTs are very important for the full-fidelity images of some given source code. But code analysis sometimes need not care about trivial details of the code, such as whitespaces. Therefore, stripping these details can reduce the unnecessary details. For this, tree-sitter distinguishes between **named node**s (nodes that have explicit grammar rules) and **anonymous node**s (nodes that are inlined as simple strings in the grammar).

```js
if_statement: $ => seq("if", "(", $._expression, ")", $._statement);
^^^^^^^^^^^^           ^^^   ^^^                 ^^^
named node            anonymous nodes
```

#### Node Field Names

By default, child nodes are accessed via an index to the children array.

Sometimes, accesses via named fields are more convenient.

> This is like ANTLR, allowing both indexed accesses and named accesses.

```c
TSNode ts_node_child_by_field_name(
  TSNode self,
  const char *field_name,    // A unique field name assigned to the child nodes in the user-defined grammar
  uint32_t field_name_length
);
```

Providing the field name along with the field name length can be cumbersome and inefficient (because string comparisons need to be repeated), tree-sitter allows them to be interned into `TSFieldId`:

```c
uint32_t ts_language_field_count(const TSLanguage *);
const char *ts_language_field_name_for_id(const TSLanguage *, TSFieldId);
TSFieldId ts_language_field_id_for_name(const TSLanguage *, const char *, uint32_t);
```

### Tree Edit

Two required steps to sync the `TSTree` with the editted content:

1. Edit the syntax tree (range-only): Adjust the ranges of the tree nodes to match the source code.

   ```c
   typedef struct {
     uint32_t start_byte;
     uint32_t old_end_byte;
     uint32_t new_end_byte;
     TSPoint start_point;
     TSPoint old_end_point;
     TSPoint new_end_point;
   } TSInputEdit;

   void ts_tree_edit(TSTree *, const TSInputEdit *);
   ```

   > Why do you have to do this?
   > My initial guess is that tree-sitter need to track the edit steps? Therefore, it can be incremental? Suppose they would just accept a new source - they would need to diff the old and the new source somehow.

2. Trigger reparsing via `ts_parser_parse` by passing the old tree. The new tree internally shares structure with the old tree.

Nodes in the `TSTree` will have their positions changed. Nodes outside won't, and will be stale. Therefore, they must be updated via `ts_node_edit`.

### Language Injection Support

As detailed in the Zed's blog, many documents in various languages can appear in one source code.

Tree-sitter allows one to stitch disjointed segmeents of a file as one unified syntax tree.

```racket
typedef struct {
  TSPoint start_point;
  TSPoint end_point;
  uint32_t start_byte;
  uint32_t end_byte;
} TSRange;

void ts_parser_set_included_ranges(
  TSParser *self,
  const TSRange *ranges,
  uint32_t range_count
);
```

Example for this ERB program:

```html
<ul>
  <% people.each do |person| %>
  <li><%= person.name %></li>
  <% end %>
</ul>
```

The code roughly follow these steps:

1. Parse the entire document using the root templating language (e.g., ERB).
2. Traverse the resulting AST to identify nodes containing embedded languages (e.g., HTML content vs. Ruby code).
3. Extract the boundaries of these nodes and store them in separate `TSRange` arrays (one array for HTML ranges, one for Ruby ranges).
4. Change the parser's language to the embedded language (`ts_parser_set_language`).
5. Feed the corresponding range array to the parser (`ts_parser_set_included_ranges`).
6. Parse the original text again to generate a clean, isolated syntax tree for that specific embedded language.

### Concurrency Support

`TSTree` instances are not thread-safe. However, they can be cheaply copied via `ts_tree_copy(TSTree *)`:

- `TSTree`s are immutable.
- An atomic counter is incremented to keep track of completely freed `TSTree`s.

### (Efficient) Tree Traversal

Standard node APIs (`ts_node_child` and `ts_node_child_by_field_name`) are suitable for occasional accesses, but are not really efficient: They are stateless, which means repeated calls would require repeated computation.

For bulk accesses scenarios, tree cursors (`TSTreeCursor`) are used to ensure maximum performance when traversing a large number of nodes. While standard APIs recalculate positions from scratch, cursors are stateful objects that cache their path, allowing $O(1)$ navigation and lazy evaluation.

The usage flow is roughly as follows:

- Initialization: Start a cursor from any specific node.
  - `ts_tree_cursor_new(TSNode)`
- Navigation: Mutates the cursor's internal state. Returns `true` if the move succeeded, and `false` if there is no node to move to (or if it hits the initialization boundary).
  - `ts_tree_cursor_goto_first_child(TSTreeCursor *)`
  - `ts_tree_cursor_goto_next_sibling(TSTreeCursor *)`
  - `ts_tree_cursor_goto_parent(TSTreeCursor *)`
- Accessors: Retrieve data at the cursor's current location without moving it.
  - `ts_tree_cursor_current_node(const TSTreeCursor *)` _(triggers lazy evaluation)_
  - `ts_tree_cursor_current_field_name(const TSTreeCursor *)`
  - `ts_tree_cursor_current_field_id(const TSTreeCursor *)`

```c
// 1. Initialize the cursor (this node becomes the impenetrable boundary)
TSTreeCursor cursor = ts_tree_cursor_new(start_node);

// 2. Traversal Flow
// Try moving down into the children (O(1) operation)
if (ts_tree_cursor_goto_first_child(&cursor)) {

    // 3. Extract lightweight data directly
    const char *field = ts_tree_cursor_current_field_name(&cursor);

    // 4. Extract the full node struct only if actually needed
    TSNode current = ts_tree_cursor_current_node(&cursor);

    // 5. Move horizontally (O(1) operation)
    if (ts_tree_cursor_goto_next_sibling(&cursor)) {
        // Evaluates the next sibling
    }

    // 6. Move back up the tree
    ts_tree_cursor_goto_parent(&cursor);
}
```

### Tree Query

#### Syntax

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

#### Operators

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
- It **does not** enforce strict adjacency; undeclared nodes can still appear between the grouped items.
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

Without the anchor above, `@the-element` would be bound to every identifier in the array (? not sure how it would behave though?).

- After the last child within the parent pattern: Similarly to the above case.

- Between two child patterns: Match immediate siblings.

```racket
(dotted_name
  (identifier) @prev-id
  .
  (identifier) @next-id)
```

Note that anonymous nodes are not taken into account.
