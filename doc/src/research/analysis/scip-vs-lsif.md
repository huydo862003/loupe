# `[blog]` `[overview]` SCIP - A Better Code Indexing Format than LSIF

Source: sourcegraph's blog

Link: https://sourcegraph.com/blog/announcing-scip

Keywords:

- Indexing format

> "Sourcegraph Inc. is a company developing code search and code intelligence tools that semantically index and analyze large codebases so that they can be searched across commercial, open-source, local, and cloud-based repositories."

## Abstract

## Introduction

An indexing format is a quickly queryable representation of an entity. Previously, we have LSIF (Language Server Index Format), an open-source standard by Microsoft that serves as a standard indexing format for codebases, enabling rich code navigation, highlighting, etc. This article identified some pain points of LSIF, and thus, the motivation for SCIP.

As indexing formats enable a large part of the Sourcegraph ecosystem, this is a crucial component, especially for code navigation.

## Background

There are two fundamentally different ways to implement code navigation: text/heuristic-based and semantic.

Text-based approaches (ctags, tree-sitter) are faster and language-agnostic, but they make mistakes. "Go to definition" might take you to a function with the same name in a different module. "Find references" might miss usages behind aliases or dynamic dispatch. Good enough for quick exploration, bad for anything that requires correctness.

It's worth separating ctags and tree-sitter here, because they're quite different in what they actually do.

- ctags is purely text/regex-based. It scans source files and extracts symbol names and their locations using patterns, with no real parsing. No understanding of scope, types, or imports. "Go to definition" just finds the nearest thing with that name. Inherently search-based.

- Tree-sitter is a proper incremental parser. It builds a full, language-aware AST, so it actually understands syntax. In principle it could do more than ctags. But it stops at the **syntax level**: it doesn't resolve names. It can tell you "this token is an identifier," but not "this identifier refers to _that_ declaration over in _that_ file." That resolution step (name binding, type inference, import resolution) requires a type-checker or a full compiler front-end, which tree-sitter doesn't do and isn't meant to do.

So the bottleneck isn't parsing, it's _name resolution_. To know where a symbol actually comes from, you need the full semantic graph of the program, not just its syntax tree. That's what language servers (via LSP) and indexers (via LSIF/SCIP) provide, sitting on top of a compiler.

Semantic approaches actually run a language-aware indexer, essentially a compiler front-end, that resolves symbols with full type information. The results are compiler-accurate: no false positives, no missed references, cross-repository aware. The catch is that this is expensive to set up. You need a working build environment, a language-specific indexer, and a pipeline to feed the output into wherever you're querying from.

Sourcegraph built their precise navigation on LSIF. The flow is: a language-specific indexer runs against your codebase and dumps an LSIF file, you push that file to Sourcegraph, Sourcegraph ingests and indexes it, and from that point on you get compiler-accurate navigation across repos.

<div style="text-align: center">

```mermaid
flowchart TB
    subgraph row1 [" "]
        direction LR
        A[Codebase] --> B[Language-specific indexer]
        B -->|LSIF file| C[Upload to Sourcegraph]
    end
    subgraph row2 [" "]
        direction LR
        D[Sourcegraph backend] -->|Stores index| E[(Database)]
        E --> F[Compiler-accurate code navigation]
    end
    C --> D
```

</div>

> This is actually a new workflow for me...

## Detour: LSIF Format

LSIF is newline-delimited JSON (one object per line). Every line is either a **vertex** or an **edge**, distinguished by a `"type"` field. Every object also has an `"id"` (a monotonically-increasing integer) and a `"label"` (the semantic kind).

```json
{ "id": 7,  "type": "vertex", "label": "resultSet" }
{ "id": 10, "type": "edge",   "label": "next", "outV": 8, "inV": 7 }
```

Vertices represent things: documents, ranges (spans of code), result hubs, hover content, definition locations, reference sets. Edges connect them using `outV` (from) and `inV` / `inVs` (to). The IDs carry no meaning on their own; they're just handles for wiring the graph together.

Key vertex types:

| Label              | What it represents                                    |
| ------------------ | ----------------------------------------------------- |
| `document`         | A source file                                         |
| `range`            | A span within a file (`start`/`end` line + character) |
| `resultSet`        | A hub shared by all ranges of the same symbol         |
| `hoverResult`      | The hover popup content                               |
| `definitionResult` | Where a symbol is defined                             |
| `referenceResult`  | All definition and reference locations                |

Key edge types:

| Label                     | Meaning                                       |
| ------------------------- | --------------------------------------------- |
| `contains`                | Document owns ranges. Project owns documents  |
| `next`                    | Range delegates to its resultSet              |
| `textDocument/hover`      | resultSet points to hover content             |
| `textDocument/definition` | resultSet points to definition locations      |
| `textDocument/references` | resultSet points to reference set             |
| `item`                    | Binds a result vertex back to concrete ranges |

The `resultSet` is the central design idea. Consider a symbol like `foo` that appears 50 times across a codebase — once as a definition and 49 as references. Naively, you'd attach hover content, definition location, and reference list to each of those 50 ranges individually. That's a lot of duplication.

Instead, LSIF introduces a `resultSet` as a shared hub: all 50 ranges point to the same `resultSet` via a `next` edge, and the actual results (hover, definition, references) hang off the `resultSet` once. When you query "what's the hover for range(19)?", you follow `next` to get the `resultSet`, then follow `textDocument/hover` to get the result.

It's a reasonable design for compactness, but it adds an indirection step to every query. And because everything is wired by opaque IDs, you have to load the entire graph into memory to efficiently resolve anything — you can't jump to a range and read its data directly, you have to chase IDs across the whole file.

## Challenges of LSIF

Sourcegraph has built dozens of LSIF indexers, from prototype to production grade, covering Go, Java, Scala, Kotlin, TypeScript, and JavaScript.

At scale, that means 45k+ repos with precise navigation enabled and 4k+ LSIF uploads processed per day. At that point, the cracks in the protocol become hard to ignore.

Most of the pain traces back to one design decision: LSIF uses a graph encoding with opaque numeric IDs to connect vertices and edges. Here's what that looks like for this TypeScript snippet:

```typescript
// main.ts
function foo(): void {} // line 0: foo is defined here

const x = 1;
foo(); // line 3: foo is referenced here
```

The LSIF graph for this looks like (notation: `vertexLabel(id)` where the number is the opaque integer ID assigned by the indexer):

<div style="text-align: center">

```mermaid
flowchart TB
    classDef docNode fill:#4A90D9,color:#fff,stroke:#2c6fad
    classDef rangeNode fill:#5CB85C,color:#fff,stroke:#3d8b3d
    classDef resultSetNode fill:#F0AD4E,color:#000,stroke:#c87f0a
    classDef resultNode fill:#9B59B6,color:#fff,stroke:#6c3483

    doc["document(4)<br/>main.ts"]:::docNode
    doc -->|contains| r8(["range(8)<br/>line 0: foo definition"]):::rangeNode
    doc -->|contains| r19(["range(19)<br/>line 3: foo reference"]):::rangeNode

    r8 -->|next| rs(("resultSet(7)")):::resultSetNode
    r19 -->|next| rs

    rs -->|textDocument/hover| hov["hoverResult(11)"]:::resultNode
    rs -->|textDocument/definition| def["definitionResult(13)"]:::resultNode
    rs -->|textDocument/references| ref["referenceResult(16)"]:::resultNode

    def -->|item| r8
    ref -->|item definitions| r8
    ref -->|item references| r19
```

</div>

Every connection is expressed as `{id, type: "edge", outV: N, inV: M}` where N and M are opaque integers. That single choice cascades into a bunch of problems:

1. **No machine-readable schema, no static types**:
   - LSIF has no formal schema. Every line is a free-form JSON object, so when writing an indexer or reader you're working with raw maps and doing manual field access.

2. **Large in-memory data structures**: Because edges reference IDs that may not have appeared yet in the file, you can't process LSIF as a stream. You have to buffer everything first, then resolve references. For a large repo with millions of ranges and edges, this means holding the full graph in memory before you can answer a single query.

```mermaid
flowchart LR
    A["Read line 1<br/>range(8)"] --> B["Read line 2<br/>edge next outV=8 inV=7"]
    B --> C["resultSet(7) not seen yet<br/>must buffer"]
    C --> D["Read line 3<br/>resultSet(7)"]
    D --> E["Now resolve<br/>buffered edges"]
```

3. **Opaque IDs make debugging painful**: When something goes wrong, you're staring at a wall of numbers with no context. There's no way to tell what ID 7 or ID 13 represents without mentally tracing the whole graph from the start.
   ```json
   {"id":14,"type":"edge","label":"textDocument/definition","outV":7,"inV":13}
   {"id":15,"type":"edge","label":"item","outV":13,"inVs":[8],"document":4}
   ```

What is `outV:7`? What is `inV:13`? What range is `8`? You have to scroll back through the file and match IDs by hand.

4. **Incremental indexing is hard**: IDs are globally monotonically increasing. If you index file A and get IDs 1 to 500, then index file B and get IDs 501 to 1000, you can't independently re-index just file A later since the new IDs would collide or require renumbering. Merging two separately-generated LSIF outputs is also non-trivial because both start their IDs from 1.

   ```
   Index run 1 (full):   range(8) -> resultSet(7) -> definitionResult(13)
   Index run 2 (file A): range(1) -> resultSet(2) -> definitionResult(3)  // ID collision
   ```

> The vibe I get is that the problem of LSIF is that it's too monolithic & isn't modular. Local analysis of LSIF file is not really possible - a global picture is required.

SCIP addresses all of this by replacing the graph encoding with a Protobuf schema built around human-readable string IDs for symbols, dropping the concepts of "monikers" and "resultSet" entirely.
