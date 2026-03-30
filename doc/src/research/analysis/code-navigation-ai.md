# `[blog]` `[overview]` Code Navigation for AI SWEs: What We've Learned So Far

Source: engines.dev

Link: https://www.engines.dev/blog/code-navigation

Keywords:

- Code navigation
- LSP

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

The last approach maps cleanly onto what a language server already provides. The question is which backend to use.
