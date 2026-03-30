# loupe

An all-in-one suite of ergonomic APIs and CLI tools for code analysis & codebase querying, aiming for code comprehension, refactoring & automation.

These leverage well-known program analysis techniques, algorithms, and heuristics to answer very common questions about codebases. Loupe itself doesn't use AI, because I want a reliable, fast and simple tool. Nevertheless, AI agent is one of the intended consumer of this tool.

## Rationale

Personally, I'm not super hyped about AI-driven projects. I'm fine with quick, dirty, throwaway stuff that doesn't need long-term maintenance. However, I'm somewhat hesitant for anything serious. That being said, being pushed to produce by work's circumstances, I started prompting AI more and more, and sometime got really paranoid about code quality.

The thing is, AI sometimes uses really dirty workarounds, weird naming conventions, and weird folder structures. I'd tell it to refactor, rename, or reorganize things, and it'd take way longer than it should. More than 5 minutes for stuff that should be instant in a normal IDE, but doing that interactively would just confuse the AI anyway. It's very tiring, especially when I don't want my codebase to be a mess.

AI doing manual search is slow, token-consuming, and imprecise. AI writing a script to do it is faster but still imprecise, and code often ends up malformed. I kept watching it `grep` and `sed` its way through files repeatedly.

Then I thought: if AI had access to really good codebase analysis and language services (smart renaming, structural search, symbol-aware refactoring), that would change things significantly. So that's when I conceived of building some code analysis & quality assurance tools.

Loupe doesn't rely on AI, but it gives AI the tools to do structural work correctly. That's useful on its own, and even more useful when combined with AI.

## Components

Structure-wise, Loupe has 2 main parts: The API and the CLI interface.

Functionality-wise, Loupe is concerned with 4 aspects:

- Code analysis
- Code querying
- Code refactoring
- Quality assurance

Goals: Loupe is aimed to be:

- Ergonomic: Easy-to-use APIs.
- Extensible: Can be easily extended from the core API.
- Fast: Must be instant compared to AI manual code search.
- Simple: Should be rather self-contained and not too bloated.
