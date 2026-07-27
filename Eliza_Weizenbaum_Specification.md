# ELIZA Weizenbaum 1966 Specification (SWI-Prolog)

## Purpose

This document translates Joseph Weizenbaum's 1966 ELIZA paper into an actionable implementation specification for this repository.

Source article:
- `reference/weizenbaum.eliza.1966.pdf`

Primary goal:
- Build a faithful ELIZA engine in SWI-Prolog that follows the paper's architecture (keyword-driven decomposition/reassembly scripting), while using modern Prolog organization and maintainability practices.

---

## Scope

Note: User-facing runtime behavior (interactive loop/terminal I/O) is a project-level runtime add-on described in the **Runtime Layer** section, while the original paper primarily defines the transformation-engine model.

### In Scope
- Script-driven ELIZA engine (engine separated from script data)
- Keyword precedence/ranking
- Decomposition and reassembly rules
- Substitutions (pronoun/person shifts and normalizations)
- `NONE` fallback behavior when no keyword transformation applies
- `NEWKEY` behavior (abandon current key and retry next key)
- Rule cycling to avoid repeating same response too frequently
- Optional memory mechanism (deferred response retrieval)
- Script extensibility via data-driven representation

### Out of Scope (for initial implementation)
- Full historical MAD-SLIP parity at internal data-structure level
- Full psychological modeling / belief-structure inference
- Runtime in-session script editor equivalent to the historical `EDIT` command

---

## Design Principles from the 1966 Paper

1. **Script is data, not code**
   - ELIZA engine must be general-purpose.
   - Conversational behavior must reside in script facts.

2. **Keyword-triggered transformation**
   - Input is scanned for keywords.
   - Higher-ranked keywords should take precedence.

3. **Context through decomposition**
   - A keyword alone is insufficient; decomposition rules establish minimal context.

4. **Response generation through reassembly**
   - A matched decomposition rule selects a reassembly rule.
   - Reassembly inserts captured fragments and may redirect processing.

5. **Robust behavior with no suitable key**
   - Reserved fallback behavior (`NONE`) is required.

6. **Iterative script growth**
   - Start small; expand scripts through observed interactions.

---

## Runtime Layer (Project Add-On to Original Specification)

The original Weizenbaum paper primarily specifies the ELIZA **transformation engine** and script mechanics. In this project, we add a separate **runtime layer** to provide a practical user-facing conversation experience in SWI-Prolog.

This runtime layer is intentionally treated as an add-on, not a change to the historical core model.

### Runtime responsibilities
- Start and reset a session
- Read user input from terminal/REPL
- Call the core engine for each turn
- Print formatted ELIZA responses
- Provide clean exit controls (e.g., `bye`, `bye.`)

### Separation of concerns
- **Engine layer**: keyword scan, decomposition/reassembly, ranking, fallback, optional memory behavior
- **Runtime layer**: interactive loop, prompt/response I/O, session command handling

### Suggested runtime API
- `eliza_run/0` — starts an interactive loop
- `eliza_reset/0` — clears per-session mutable state
- `eliza_reply/2` or `eliza_reply/3` — single-turn response generation

### Implementation note
This follows the same pattern as the `eliza_shrader_1973.pl` translation in this repository, where the transformation logic exists independently and the discussion loop is provided by an explicit runtime predicate.

---

## Recommended Project Structure (Prolog Best Practice)

A split between engine and script is strongly recommended.

- `src/eliza_engine.pl`
  - Core algorithm (tokenization, scan, ranking, decomposition matching, reassembly, control flow)
- `src/eliza_runtime.pl`
  - CLI/REPL loop (`eliza_run/0`), session state handling
- `src/eliza_types.pl` (optional)
  - Shared predicates/helpers for rule term normalization/validation
- `scripts/doctor_script.pl`
  - Script facts (keywords, decomposition rules, reassemblies, substitutions, tags/classes)
- `scripts/shrader_script.pl` (optional separate historical variant)
- `test/eliza_engine_tests.pl`
  - PlUnit tests for matching, ranking, control operators, substitutions

If this repository remains small, `src/eliza_engine.pl` + `scripts/*.pl` is sufficient.

---

## Core Data Model (Suggested Prolog Representation)

### 1) Keyword entries
```prolog
keyword(KeyAtom, Rank, KeySpec).
```
- `KeyAtom`: canonical keyword id (e.g., `you`, `what`, `computer`)
- `Rank`: integer precedence (default 0)
- `KeySpec`: reference to decomposition/reassembly rules

### 2) Decomposition rules
```prolog
decomp(KeyAtom, DecompId, Pattern).
```
Pattern supports paper semantics:
- `0` => zero or more words wildcard
- `N` => exactly `N` words
- literal words
- tag/class alternatives (see DLIST below)

Example term form:
```prolog
pattern([wild(0), lit(you), wild(0), lit(me)]).
```

### 3) Reassembly rules
```prolog
reassembly(KeyAtom, DecompId, ReasmIndex, Action).
```
`Action` variants:
- `text(Tokens)` — generate response with captured-slot insertion
- `goto(OtherKey)` — equivalent class redirect (`=WHAT` style)
- `newkey` — equivalent to `(NEWKEY)`
- `pre(RewriteTokens, GotoKey)` — pre-transform then continue as another key
- `memory(StoreTemplate)` — push transformed text to memory queue

### 4) Substitutions
Two forms are useful:
```prolog
substitute(Input, Output).
normalize(Input, Output).
```
- `normalize/2` for contractions/spelling variants (`dont` -> `don't`, etc.)
- `substitute/2` for person/pronoun inversion (`my` <-> `your`, `i` <-> `you`, etc.)

### 5) Tags / classes (DLIST concept)
```prolog
tag_word(mother, [noun, family]).
```
Used in decomposition patterns with class match tokens, e.g. `class(family)`.

### 6) Session state
Use dynamic predicates for per-session mutable state:
```prolog
:- dynamic last_reassembly_index/3.
:- dynamic memory_queue/1.
:- dynamic previous_input/1.
```

---

## Processing Pipeline

1. **Input normalization**
   - Upper/lower normalization strategy (consistent internal canonical form)
   - Apostrophe handling and punctuation policy
   - Tokenization into words

2. **Initial substitutions**
   - Apply unconditional word substitutions during/after scanning as needed

3. **Keyword scan**
   - Left-to-right scan over tokens
   - Collect matching keyword candidates and associated ranks
   - Build a ranked key queue ("keystack" equivalent)

4. **Keyword selection**
   - Choose highest rank first
   - Preserve useful secondary order for fall-through attempts

5. **Decomposition attempt loop**
   - For selected key, test decomp rules in declared order
   - On failure, try next decomp for same key
   - If all fail, proceed to `newkey` behavior (next key candidate)

6. **Reassembly selection**
   - For matched decomp, choose reassembly via cyclical index
   - Advance index so alternates are used over time

7. **Control directives**
   - Handle `goto(Key)` by switching key context
   - Handle `newkey` by popping next candidate key
   - Handle `pre(...)` by rewriting then continuing pipeline

8. **Fallback (`NONE`)**
   - If no usable key path remains, apply `NONE` key rules

9. **Memory response (optional but recommended)**
   - Store selected transformed statements in FIFO
   - Under configurable conditions, emit memory recall when no key matches

10. **Emit response**
   - Join tokens with normalized spacing/punctuation

---

## Detailed Behavioral Requirements

### Keyword ranking
- Rank default is `0` when omitted.
- Higher rank dominates lower rank.
- Ties should preserve deterministic behavior (prefer earliest encountered keyword unless script says otherwise).

### Decomposition matching
- Must support:
  - unconstrained wildcard (`0`)
  - fixed-word-count wildcard (`N`)
  - literal tokens
  - class/tag alternatives
- Matching should be word-boundary-safe.

### Reassembly insertion
- Captured components from decomposition are addressable by index (`3`, `4`, etc.).
- Reassembly may mix literals with captures.

### Rule cycling
- For each `(KeyAtom, DecompId)`, rotate through reassemblies before repeating.

### Equivalence classes
- Keywords like `HOW`, `WHEN` may redirect to `WHAT` rules via `goto(what)`.

### NEWKEY semantics
- Abandon current key path and continue with next available ranked key candidate.

### NONE semantics
- Reserve a key (`none`) with universal decomposition and content-light reassemblies.

### Memory semantics (paper-inspired)
- Reserve pseudo-key `memory`.
- Store transformed candidates to FIFO.
- Allow retrieval as fallback under defined conditions (counter/interval configurable).

---

## SWI-Prolog Recommendations

### Libraries
- `library(lists)` for list operations
- `library(apply)` for maplist/foldl patterns
- `library(readutil)` for interactive line input
- `library(plunit)` for unit tests
- `library(dcg/basics)` if implementing tokenizer/parser via DCG

### Coding style and maintainability
- Keep script facts in separate module(s) from inference engine
- Export a narrow public API, e.g.:
  - `eliza_reply/3` (`+Script,+Input,-Response`) or `eliza_reply/2` in single-script mode
  - `eliza_run/0` for interactive loop
  - `eliza_reset/0` for session state reset
- Avoid hard-coded script values in engine predicates
- Keep dynamic state isolated and resettable
- Prefer deterministic predicates where practical (`det`/cuts used intentionally)

### Testing requirements
Minimum tests should verify:
- keyword ranking precedence
- decomposition matching cases (`0`, `N`, class tags)
- `goto` / `newkey` behavior
- response cycling correctness
- fallback behavior
- pronoun/person substitution stability

---

## Script Authoring Guidelines

1. Define keyword inventory and ranks first.
2. Add decomposition patterns from specific to general.
3. Keep a final catch-all decomposition per key when needed.
4. Provide multiple reassemblies per decomposition for variation.
5. Use equivalence redirects to avoid duplicated rule sets.
6. Keep `NONE` responses generic and non-committal.
7. Introduce `MEMORY` transforms selectively to reduce repetition.
8. Grow script iteratively based on observed conversation transcripts.

---

## Practical Milestones

1. **Milestone 1: Minimal faithful core**
   - Keywords + rank
   - Decomp/reassembly
   - Rule cycling
   - NONE fallback

2. **Milestone 2: Full control operators**
   - `goto` / equivalence keys
   - `newkey`
   - preliminary rewrite (`pre`-style)

3. **Milestone 3: Tag classes + memory**
   - DLIST-style class matching
   - memory queue retrieval policy

4. **Milestone 4: Usability and tests**
   - interactive loop polish
   - comprehensive PlUnit coverage
   - script validation utilities

---

## Constraints and Risks

- OCR artifacts in source scans can introduce script typos; validate against known ELIZA script references where available.
- Overly broad decomposition rules can dominate and reduce conversational quality.
- Excessive dynamic state without clear reset semantics can make debugging difficult.

---

## Acceptance Criteria for This Specification

A Prolog implementation is considered aligned with this specification if:
- Engine and script are separated (or intentionally justified if not)
- Keyword ranking and decomposition/reassembly pipeline are implemented
- `NONE` fallback and reassembly cycling are present
- At least one script (e.g., DOCTOR-style) runs through `eliza_run/0`
- Behavior is covered by targeted unit tests

---

## Notes on Historical Context

The original system was implemented in MAD-SLIP on MIT's MAC time-sharing environment. This specification preserves the behavioral model while mapping implementation details to idiomatic SWI-Prolog.
