# Code Indexing & Navigation

Code indexing is about pre-computing a structured index of symbols, references, and relationships in a codebase so that navigation queries (go-to-definition, find references, call hierarchy) can be answered quickly without re-analyzing the code on every request.

The main design tension is between index freshness and cost. A full re-index on every change is expensive, but a stale index gives wrong answers. Formats like SCIP and LSIF try to standardize what gets stored, while systems like Glean and Kythe focus on how to store and query it at scale.

Loupe's index format must not assume a specific language (language-agnostic), must support cheap partial updates when files change (incremental), and must answer navigation queries instantly even on large codebases (fast).

## Subpages

- [SCIP - A Better Code Indexing Format than LSIF](code-indexing-navigation/scip-vs-lsif.md): Sourcegraph's comparison of SCIP vs LSIF, arguing for a simpler, more debuggable indexing format.
- [Code Navigation for AI SWEs](code-indexing-navigation/code-navigation-ai.md): a practical look at how AI coding agents can leverage code navigation infrastructure.
- [SCIP](code-indexing-navigation/scip.md): a deep dive into the SCIP indexing format itself.
- [Glean](code-indexing-navigation/glean.md): Meta's system for collecting, deriving, and querying facts about code at scale.
- [Google Kythe](code-indexing-navigation/kythe.md): Google's ecosystem for building tools that work with code, centered on a language-agnostic graph schema.
- [OpenGrok](code-indexing-navigation/opengrok.md): Oracle's fast source code search and cross-reference engine.
- [livegrep](code-indexing-navigation/livegrep.md): a regex-based code search tool optimized for speed over large repositories.
- [Mycroft](code-indexing-navigation/mycroft.md): a code indexing and navigation tool.
