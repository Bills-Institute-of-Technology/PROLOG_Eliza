# PROLOG_Eliza

A SWI-Prolog implementation of the classic ELIZA chatbot, originally created by Joseph Weizenbaum at MIT (1964–1967).

---

## Background

ELIZA is one of the earliest natural language processing programs. It simulates conversation by applying a set of pattern-matching and text-transformation rules drawn from a separate, interchangeable **script file**. The most famous script, **DOCTOR**, simulates a Rogerian psychotherapist and contains roughly 40 keyword-driven conversation patterns.

ELIZA does not "understand" language. Its conversational illusion is produced entirely by:

1. Scanning user input for high-priority **keywords**.
2. Matching the sentence against a **decomposition pattern** associated with that keyword.
3. Applying a **reassembly rule** to transform fragments of the user's input into a response.
4. Falling back to a set of generic prompts when no keyword or pattern matches.

The definitive description of the program is Weizenbaum's 1966 paper, a copy of which is held in this repository:
> `reference/weizenbaum.eliza.1966.pdf`

---

## Why SWI-Prolog?

The preliminary research for this project evaluated Python, Haskell, and Prolog as implementation languages and reached the following conclusions:

- **Python** is the most pragmatic choice — readable, well-resourced, and quick to prototype — but requires procedural code to explicitly manage the search and rule-application loop that Prolog provides natively.
- **Haskell** offers declarative elegance and pure functional modeling of the transformation pipeline, but is not inherently geared toward the specific kind of rule-based inference at ELIZA's core.
- **Prolog** is the most *philosophically aligned* choice:
  - ELIZA's engine is fundamentally an **inference engine** that applies rules to input — exactly what Prolog is designed for.
  - The script's keyword/decomposition/reassembly structure maps **directly onto Prolog predicates and facts**.
  - Prolog's built-in **unification** mechanism is a natural fit for ELIZA's pattern-matching task.
  - **Backtracking** handles cycling through multiple reassembly rules without extra bookkeeping.
  - The declarative style allows the *script* (the conversational knowledge) to be cleanly separated from the *engine* (the inference logic).

---

## ELIZA Script Architecture

An ELIZA script is composed of four layers:

| Layer | Purpose |
|---|---|
| **Keywords + Priority** | Each keyword has a numeric priority rank. The engine selects the highest-priority keyword found in the input. |
| **Decomposition rules** | Wildcard patterns (e.g. `* i am *`) that match against the tokenised input. Synonym lists broaden matching. |
| **Reassembly rules** | Templates that reconstruct a response using captured fragments from the decomposition match. Multiple rules cycle in sequence. |
| **Pre/Post substitutions** | Pre-substitutions normalise input (e.g. `don't` → `do not`); post-substitutions flip pronouns (e.g. `I` → `you`, `my` → `your`) before the response is emitted. |

If no keyword matches, ELIZA cycles through a list of generic fallback responses (e.g. *"Tell me more."*, *"Please continue."*).

---

## Prolog Representation

The script maps naturally onto a small set of Prolog predicates:

```prolog
% script(+Keyword, +Priority, +DecompositionRules)
script(father, 2, [
    decomp([_,father,_], [tell,me,more,about,your,father]),
    decomp([_,father,_], [how,do,you,feel,about,your,father])
]).

script(i, 0, [
    decomp([i,am,X],   [why,are,you,X,'?']),
    decomp([i,feel,X], [tell,me,more,about,those,feelings])
]).

% subst(+InputWord, -OutputWord)  — pronoun flipping
subst(i,  you).
subst(my, your).
subst(me, you).
subst(am, are).
```

The main engine predicate `eliza(+Input, -Response)` uses `findall/3` and `sort/4` to select the highest-priority matching rule, then delegates to `match_pattern/3` and `reassemble_response/3`. If no rule fires, a `fallback_response/1` predicate cycles through the generic responses via a dynamic index.

---

## Project Goals

- Implement a faithful SWI-Prolog version of the ELIZA engine, closely following the architecture described in Weizenbaum (1966).
- Represent the DOCTOR script entirely as Prolog facts, keeping script data cleanly separated from engine logic.
- Support the full pipeline: tokenisation, pre-substitution, keyword priority selection, wildcard decomposition, pronoun-flipped reassembly, and fallback cycling.
- Provide an interactive top-level query loop runnable in the standard SWI-Prolog REPL.

---

## Prolog Implementation of Shrader's 1973 BASIC Program

The file `eliza_shrader_1973.pl` is a SWI-Prolog translation of Jeff Shrager's 1973 BASIC ELIZA variant (as published in *Creative Computing*). It preserves the classic keyword scan, conjugation swaps, rotating response ranges, repeated-input handling, and an interactive conversation loop.

Run it in SWI-Prolog:

1. Start SWI-Prolog:
   - `swipl`
2. Load the program:
   - `[eliza_shrader_1973].`
3. Start the interactive loop:
   - `eliza_run.`
4. Exit the ELIZA loop:
   - Type `bye` or `bye.` at the `You:` prompt.

---

## References

- Weizenbaum, J. (1966). *ELIZA — A Computer Program For the Study of Natural Language Communication Between Man and Machine*. *Communications of the ACM*, 9(1), 36–45. (`reference/weizenbaum.eliza.1966.pdf`)
- elizagen.org / findingeliza.org — rediscovered original MAD-SLIP source code (2024/2025).
- Norvig, P. — *Paradigms of Artificial Intelligence Programming* (Python ELIZA implementation).
- SWI-Prolog/SWISH `eliza.pl` — reference Prolog implementation.
