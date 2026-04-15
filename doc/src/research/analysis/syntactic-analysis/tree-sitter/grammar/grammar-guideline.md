# Tree-sitter Grammar Guideline

Source: tree-sitter

Link: https://tree-sitter.github.io

## Takeaways

We want to choose the best CFG among the inifinite number of them to describe a language.

The best CFG is determined by:

- Direct correspondence between symbols in the grammar and the recognizable constructs in the language (ignore non-relevant symbols like trivia). -> Easier to analyze.
- Should closely adhere to LR(1) for performance reason.

> Tree-sitter grammars are said to be different from Yacc and Bison (in terms of grammar authoring) & different in nature from ANTLR grammars, PEG, ambiguous grammar (in language specifications). (? Why)

## Design Phase

Criteria for a tree-sitter grammar:

- **Intuitive mapping**: Grammar symbols should map to recognizable language constructs. The AST should mirror how developers think about code, not formal specifications.
- **Breadth-first development**: Start with skeleton rules covering major categories (declarations, statements, expressions), then incrementally flesh out details. Test frequently.
- **LR(1) compatibility**: Tree-sitter uses GLR parsing and performs best with LR(1)-compatible grammars (like Yacc/Bison), not ANTLR or PEG approaches.

### Design Process

1. Start with a formal specification of the language (probably containing a CFG, but this can be hard to just trivially translateinto a tree-sitter grammar).
2. Work out the just-enough high-level constructs of the programming language, typically: **Declarations**, **Definitions**, **Statements**, **Expressions**, **Types** and **Patterns**.
   > The start rule for the grammar is the first property in the `rules` object.
   > Perform a breadth-first design: Cover the language in breadth, not a subset of it.
3. Iteratively build down the high-level ocnstructs just enough, switch to other constructs. In the process, test often.
   > Tests for each rule are placed in `test/corpus`.

### Standard Rule Naming Conventions

Rule names are mostly unrestricted, but for the sake of comprehensibility, we should follow the following established conventions:

| Convention       | Example                   | Purpose                                                                                                                          |
| ---------------- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Root node        | `source_file`             | Represents entire file                                                                                                           |
| Major constructs | `expression`, `statement` | Top-level language concepts, typically represented as a supertype/choice of the more specific sub-expression/sub-statement rules |
| Block scopes     | `block`                   | Parent node for block scopes                                                                                                     |
| Types            | `type`                    | The types, such as `int`, `choice` and `void`                                                                                    |
| Identifiers      | `identifier`              | Variable names, function arguments and object fields, commonly used as the `word` token                                          |
| Strings          | `string`                  | Represent string literals                                                                                                        |
| Comments         | Represent comments        | Commonly put in an `extra`                                                                                                       |

### Good Grammar Rule Structure

Commonly, to write a grammar for an expression language, one typically defines the root rule that slowly propagate to expression rules for operators that have increasing precedence:

```js
Expression        -> Assignment
Assignment        -> Conditional
Conditional       -> Or
Or                -> And
And               -> Equality
Equality          -> Comparison
Comparison        -> Add
Add               -> Mul
Mul               -> Unary
```

However, the notorious problem with this is that it creates very deep nesting that is absolutely unnecessary. And furthermore, it's hard to know which type of expression a node represents.

Although this section of the doc doesn't specify how to properly does this, probably, `prec` should be leverage in this case for the best AST that is appropriate from the perspective of the user.

> Update: Check out the sections below [Precedence Usage](#precedence-usage).

### Precedence Usage

Continue from the above section.

In short, tree-sitter provides us with a whole lot of utilities for building more ergonomic ASTs, instead of weirdly deep structures.

```js
grammar({
  rules: {
    // ...
    expression: ($) =>
      choice(
        $.unary_expression,
        $.binary_expression,
        // ...
      ),

    unary_expression: ($) =>
      choice(
        seq("-", $.expression),
        // ...
      ),

    binary_expression: ($) =>
      choice(
        seq($.expression, "*", $.expression),
        seq($.expression, "-", $.expression),
        // ...
      ),
  },
});
```

This is a flat representation, but is highly ambiguous. Tree-sitter would complain:

```
Error: Unresolved conflict for symbol sequence:

  '-'  _expression  •  '*'  …

Possible interpretations:

  1:  '-'  (binary_expression  _expression  •  '*'  _expression)
  2:  (unary_expression  '-'  _expression)  •  '*'  …

Possible resolutions:

  1:  Specify a higher precedence in `binary_expression` than in the other rules.
  2:  Specify a higher precedence in `unary_expression` than in the other rules.
  3:  Specify a left or right associativity in `unary_expression`
  4:  Add a conflict for these rules: `binary_expression` `unary_expression`
```

This is reasonable, as tree-sitter is unsure whether `- 3 * 2` should be parsed as `- (3 * 2)` or `(-3) * 2`.

> The • character indicates the ambiguity point.

Remedy with `prec`:

```js
{
  // ...

  unary_expression: ($) =>
    prec(
      2,
      choice(
        seq("-", $.expression),
        seq("!", $.expression),
        // ...
      ),
    );
}
```

In this case, the `- 3 * 2` ambiguity is resolved.

### Associativity Usage

This case still causes an ambiguity `1 * 2 * 3` - because the `*` has the same precedence, so these two are valid derivations:

```
1 * 2 * 3 -> 1 * (2 * 3)
// expression
// -> binary_expression
// -> expression '*' expression
// -> number '*' (binary_expression)
// Result: (binary_expression 1 '*' (binary_expression 2 '*' 3))

1 * 2 * 3 -> (1 * 2) * 3
// expression
// -> binary_expression
// -> expression '*' expression
// -> binary_expression '*' number
// Result: (binary_expression (binary_expression 1 '*' 2) '*' 3)
```

`prec.left` and `prec.right` will tell tree-sitter whether to prioritize the former or the latter case.

In this case, `prec.left` should be used:

```js
{
  // ...

  binary_expression: $ => choice(
    prec.left(2, seq($.expression, '*', $.expression)),
    prec.left(1, seq($.expression, '+', $.expression)),
    // ...
  ),
}
```

### Conflicts Usage

By default, tree-sitter marks all conflicts as errors. But they can be desirable.

> The example in tree-sitter I think is a bit weird, as I think we can disambiguate `array` and `array_pattern` from the surrounding context alone (like in left-side of assignments or in declarations).

To mark something as intentionally conflicting, we use the top-level `configs` field:

```js
{
  name: "javascript",

  conflicts: $ => [
    [$.array, $.array_pattern],
  ],

  rules: {
    // ...
  },
}
```

### Hidden Rules (`_rule`)

Rules starting with `_` are hidden from the AST, though it still exists in the parser.

> I found this to be quite similar to inlined rules, but it seems that they differ a bit in that inlined rules are totally eliminated from the parser, but hidden rules are still known to the parser. I wonder how that would be different from the user's perspective.

### Fields Usage

Fields can be given names to allow named accesses instead of indexed accesses.

```js
function_definition: ($) =>
  seq(
    "func",
    field("name", $.identifier), // this one can be accessed via `ts_node_child_by_field_name`
    field("parameters", $.parameter_list),
    field("return_type", $._type),
    field("body", $.block),
  );
```

### Extras Usage

"Extra" tokens like comments, spaces can appear between any two significant tokens.

```js
grammar({
  name: "my_language",

  extras: ($) => [
    /\s/, // whitespace
    $.comment,
  ],

  rules: {
    comment: ($) =>
      token(
        choice(seq("//", /.*/), seq("/*", /[^*]*\*+([^/*][^*]*\*+)*/, "/")),
      ),
  },
});
```

> For complicated `extras` tokens, it's preferable to associate the pattern with a rule, to avoid bloating up the parser because tree-sitter will inline the rules everywhere. However, it's fine for whitespace character classes like `\s` or `[ \t\n\r]` as tree-sitter autodetects this.

### Supertypes usage

For abstract categories of syntax nodes ("expression", "type", "declaration"), they are represented as `choice`s between other sub-rules:

```js
expression: $ => choice(
  $.identifier,
  $.unary_expression,
  $.binary_expression,
  $.call_expression,
  $.member_expression,
  // ...
),
```

But, this causes `expression` to be added as a syntax node, creating an unnecessary nesting level. To eliminate these, we use `supertypes`:

```js
module.exports = grammar({
  name: "javascript",

  supertypes: ($) => [$.expression],

  rules: {
    expression: ($) =>
      choice(
        $.identifier,
        // ...
      ),

    // ...
  },
});
```

So how does `supertypes` differ from inlined rules or hidden rules? `supertypes` is optimized for this use case, and it can be queried (pattern matched), unlike inlined or hidden rules.

## Deep-dive & Optimization Guide - Lexical Analysis

Tree-sitter's parsing process = Parsing + Lexing.

### Token Conflict Resolution

Token conflicts are much more common than grammar rule conflicts, such as the keyword `"if"` and identifiers `/[a-z]+/`.

There are various scenarios of token conflicts:

- Context-aware lexing: Tree-sitter performs **lexing on-demand** during parsing. -> The lexer only match tokens that are possible at the current position in the file.
- Lexical precedence: Precedence values in side a `token` function will allow the lexer to break ties when two tokens can be matched at a given position.
- Match length: When multiple tokens of the same precedence can be matched at a given position, the token that matches the longest sequence will be chosen.
- Match specificity: If multiple tokens of the same precedence match the same sequence of characters, then bare-string tokens are prioritized over regexp tokens.
- Rule order: Otherwise, the first token in the grammar is prioritized.

> In short, these are the prioritization order (only tokens that can appear at a given position are considered):
>
> 1. The token precedence specified by `spec`.
> 2. The length of the matched token.
> 3. String over Regexp.
> 4. The earlier rule in the grammar is prioritized.

External scanners can produce tokens that are treated differently from regular tokens.

### Lexical Precedence & Parse Precedence

- **Lexical Precedence**: Decides _which token_ matches a specific piece of raw text. This is a lower-level operation and happens **first**.
- **Parse Precedence**: Decides _which structural rule_ should be chosen to interpret a sequence of already-extracted tokens.
- The tip is that: When you get completely stuck debugging a grammar, it is almost always a lexical precedence problem, not a structural one.
- Syntax distinction:
  - `token(prec(N, ...))` = Applies **Lexical** Precedence (prioritizes the token generation).
  - `prec(N, token(...))` = Applies **Parse** Precedence (prioritizes the structural rule, which won't help if the lexer is grabbing the wrong token).

### Keywords

- Problem: In many languages, keywords (like `if` or `instanceof`) are just specific strings that overlap with your generic `identifier` regex (like `/[a-z]+/`).

- Example:

  ```js
  if (a instanceofSomething) b();
    //  ^^^^^^^^^^^^^^^^^^^
    //   we're here
  ```

- Tree-sitter uses context-aware lexing:
  - In normal Javascript grammar, the parser expects a keyword/operator/etc. there (other than an identifier).
  - Therefore, `instanceofSomething` would never be matched as an identifier by tree-sitter in normal instances.
  - Rather than that, tree-sitter would likely consider keyword first (`instanceof`) then chops off and makes `Something` the following identifier, which is incorrect, as an identifier cannot immediately follow a keyword.

- The tree-sitter's solution is to use the `word` top-level configuration rule.

- With `word`, tree-sitter uses a 2-step process:
  1. It first matches the `word` token.
  2. If it's a match, then do nothing. Otherwise, it proceeds lexing as normal.

- Benefits:
  - Improved error detection.
  - (Side effect) Smaller & simpler lexing function, which is more efficient.

> To avoid ambiguity: The `word` token must not be reused in another rule.
> To allow reusing, one must `alias` the `word` token:
>
> ```js
> _type_identifier: $ => alias($.identifier, $.type_identifier),
> ```

So basically `alias` works somewhat like inlined or hidden rule, but for different use cases in mind.
