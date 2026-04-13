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

### Precedence

### Associativity

### Conflicts
