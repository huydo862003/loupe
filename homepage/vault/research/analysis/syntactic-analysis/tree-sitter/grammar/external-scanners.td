# External Scanners

External scanners are custom scanners plugged into tree-sitter. These are needed as the approach of using regexes to specify tokens does not suffice for some non-regular token grammars such as:

- Off-side rule (indent and dedent tokens in Python).
- Heredocs in Bash & Ruby.

Tree-sitter resolves this by allowing authors to plug in external scanners.

## Usage

1. Add an `externals` top-level configuration:

   ```js
   grammar({
     // ...
     externals: ($) => [$.indent, $.dedent, $.newline],
   });
   ```

   This section declares the names of all the external tokens, which can be used elsewhere in the grammar.

2. Add `src/scanner.c` (mandatory) as a C source file containing the external scanner.

3. In `src/scanner.c`, define an `enum` containing the names of the external tokens. The order must match the order in the grammar's `externals` (names can differ).

   ```c
   #include "tree_sitter/parser.h"
   #include "tree_sitter/alloc.h"
   #include "tree_sitter/array.h"

   enum TokenType {
     INDENT,
     DEDENT,
     NEWLINE
   }
   ```

4. Write the custom scanning logic based on 5 actions: `create`, `destroy`, `serialize`, `deserialize` and `scan`.
   - `create`: Create the scanner object.

     ```c
     void * tree_sitter_<your_language>_external_scanner_create() {}
     ```

   - `destroy`: Free memory of the scanner object.

     ```c
     void tree_sitter_<your_language>_external_scanner_destroy(void *scanner) {}
     ```

   - `serialize`: Serialize the scanner's state into a byte buffer & return the number of written bytes. This is called by tree-sitter after the external scanner successfully recognizes a token.

     ```c
     unsigned tree_sitter_<your_language>_external_scanner_serialize(
       void *scanner,
       char *buffer
     ) {}
     ```

   - `deserialize`: Restore the state of the scanner from the written bytes.

     ```c
     void tree_sitter_<your_language>_external_scanner_deserialize(
       void *scanner,
       const char *buffer,
       unsigned length
     ) {}
     ```

   - `scan`: Tree-sitter will trigger this method with a set of the valid symbols for the external scan to scan these tokens.

     ```c
     bool tree_sitter_<your_language>_external_scanner_scan(
       void *scannar,
       TSLexer *lexer, // The tree-sitter lexer exposed to the external scanner, which the external scanner will call
       const bool *valid_symbols // a binary array such that `valid_symbols[TOKEN_TYPE]` indicates whether that token type is valid
     ) {}
     ```

   The names are in the following format: `tree_sitter_<your_language>_external_scanner_<action>`.

   > So basically, we can think of `src/scanner.c` as an interface with methods that tree-sitter can call. Alternatively, we can think of `src/scanner.c` utilize the action hooks to hook into tree-sitter.

## Utils

See more here: https://tree-sitter.github.io/tree-sitter/creating-parsers/4-external-scanners.html#external-scanner-helpers
