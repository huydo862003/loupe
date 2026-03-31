# `[blog]` `[overview]` Code Navigation for AI SWEs: What We've Learned So Far

Source: engines.dev

Link: https://www.engines.dev/blog/code-navigation

Keywords:

- Code navigation
- LSP

Takeaways:

> I think:
>
> - Stack Graphs.
> - Glean.
> - SCIP.
>
> are the ones that are worth looking into.
>
> I want to solve the problem at the API/indexing format rather than wrapping existing binaries.

AI SWE is probably AI software engineer. It is AI as a software engineer, not an engineer working in AI.

## Introduction

The core framing: AI agents need code navigation the same way humans do. You can't just throw files at a model and hope it figures out where things are.

The question is how to help AI SWE navigate a codebase.

## Existing Approaches

The field is split on how to solve this:

- **SWE-Agent**: brute-force string search across the entire codebase, then shows the LLM 100 lines at a time through a file viewer.
  > Basically, a naive heuristic where you grep through the codebase and show the matches lines in their surrounding context.
- **CodeMonkey**: passes all files into a small LLM and ranks them by relevance.
  > Basically, delegate to a narrower but faster LLM to act like a "semantic search" so that the bigger LLM can work more efficiently.
- **Moatless**: semantic search to identify relevant files.
  > Semantic search is a little vague? Does it mean Moatless performs a semantic analysis.
- **OpenHands / Engines**: expose navigation as explicit agent tools, such as _find all references_ and _go to definition_.
  > Basically my idea, focus on the tools first, then AI is just an integration.

The last approach maps cleanly onto what a language server already provides. The question is which backend to use.

## Ideal system

- **Scalable**: index at most once per commit.
- **Incremental**: re-index only changed files on new commits.
- **Flexible**: navigate any arbitrary commit hash.

No existing open-source system hits all four.

## Systems Evaluated

- **lsproxy**: auto-detects language then spins up the right LSP server.

- **Stack Graphs** (GitHub):
  - An advanced ata structure that powers Github's web-based code navigation.
  - Desirable properties:
    - Incremental.
    - Theoretically language-agnostic.
    - Fast queries via path tracing on a prebuilt graph.
  - Under the hood, uses tree-sitter + custom `.tsg` grammar files per language to build the graph. Maintaining `.tsg` files is tiring.

> The Stack Graphs architecture is the right idea: incremental, no running server required, commit-aware. The `.tsg` maintenance burden is the only real blocker.

- **Glean** (Meta):
  - Stores arbitrary facts about a codebase (user-defined schema + Angle query language).
  - Desirable properties:
    - Incremental: Only reindex new changes.
    - Scalable: Still work on Meta's massive C++ codebase.
    - Flexible: Many queries beyond simple code navigation is supported.
    - Navigate arbitrary commits: Facts can be associated with any commits.
    - Can ingest SCIP as a schema, so it covers a wide range of language support.
  - Drawbacks:
    - Glean uses Thrift for its RPC protocol. The Thrift definition Glean uses relies on Meta's internal Thrift client.

> Basically, Glean is the right direction, just some issues with open-source.

- **multilspy**: Python wrapper over an LSP server.
  - Easy to set up.
  - Support multi-language.
  - Drawbacks:
    - A bit bloated, as it downloads language server binaries.
    - LSP server's lifetime is tied to the Python process.

**Sourcegraph**: SCIP offers a precise code navigation API. However, it's not open source.

## Their Solution

They concluded that they want:

- The language agnostic approach of Glean/Stack Graph.
- The usability of lsproxy.

Their first step though, was wrapping multispy.

- A server component with MCP support.
- A Docker container for sandboxing.

> They are solving the problem at a totally different level: Ready-to-use binary, rather than API/indexing format. I want to research the solution at the Glean/SCIP level first.

## Personal Takeaways

I think:

- Stack Graphs.
- Glean.
- SCIP.

are the ones that are worth looking into.

I want to solve the problem at the API/indexing format rather than wrapping existing binaries.
