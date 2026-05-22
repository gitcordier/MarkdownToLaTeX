# Formal Specifications

## Version

2.0.1

## Subject

MarkdownToLaTeX 1.0.0 — preference acceptance.

## Endorsed module

`Preferences.tla`. The module is parametric: it never enumerates LaTeX keys.
`specifications.functional.latex.keys.2.0.0.txt` is the single source of truth
for the *contents* of `LUALATEX`; this document is the single source of truth
for the *logic*. The two evolve independently.

## Inputs to the spec

The User supplies an INI file at `preferences/preferences.ini`. The parser
yields a dictionary `user_preference_`, and we let

    user_preferences_keys = DOMAIN user_preference_

i.e. the set of keys it declares.

The recognized lualatex keys live in three abstract sets:

- `KEYS` — the syntactic universe (any string a parser could emit).
- `LUALATEX` — keys recognized by MarkdownToLaTeX. Subset of `KEYS`.
- `LUALATEX_CORE`, `LUALATEX_OPTIONS` — the disjoint partition of `LUALATEX`.

## `LualatexShape` assumption

```tla
ASSUME LualatexShape ==
  /\ LUALATEX \subseteq KEYS
  /\ LUALATEX_CORE \cup LUALATEX_OPTIONS = LUALATEX
  /\ LUALATEX_CORE \cap LUALATEX_OPTIONS = {}
  /\ LUALATEX_CORE /= {}
```

The fourth conjunct is a domain axiom: "mandatory" presupposes at least one
mandatory key. It is also the technical fact that makes the base case of
`AcceptanceConverseCorrect` discharge: in `Init`,
`user_preferences_keys = {}`, so `criterion({})` reduces to
`LUALATEX_CORE \subseteq {}`, which is `FALSE` exactly when
`LUALATEX_CORE /= {}`. Without this conjunct, `~criterion({})` is not a
theorem of the spec.

## Acceptance contract

Two MUST constraints 

| label | constraint                                 | meaning                           |
| ----- | ------------------------------------------ | --------------------------------- |
| C1    | `user_preferences_keys ⊆ LUALATEX`      | every supplied key is recognized. |
| C2    | `LUALATEX_CORE ⊆ user_preferences_keys` | every mandatory key is supplied.  |

These form the predicate `criterion(S)`. Two invariants are asserted:

```tla
Acceptance         == (state = "accepted") => criterion(user_preferences_keys)
AcceptanceConverse == (state /= "accepted") => ~criterion(user_preferences_keys)
```

Together they yield, at terminal states, the bi-implication

    state = "accepted"  <=>  criterion(user_preferences_keys).

The `Validate` action still uses `IF/THEN/ELSE` — not `<=>` — so future
versions may add conjuncts to `criterion` without altering the state machine.
The iff is a consequence of the two theorems, not an axiom of the machine.

## State machine

Three states; two actions:

    init  --Validate-->  accepted | rejected  --Done-->  (stutters)

| action       | from     | to                           | role                                                             |
| ------------ | -------- | ---------------------------- | ---------------------------------------------------------------- |
| `Validate` | `init` | `accepted` or `rejected` | non-deterministically loads a key set, then decides in one step. |
| `Done`     | terminal | terminal                     | stutter, prevents TLC deadlock at terminal states.               |

`Validate` has `Init` as its guard, so it fires at most once. After it fires,
`state /= "init"`, `Init` is false, and `Validate` is permanently disabled.
The non-deterministic choice of `user_preferences_keys'` over `SUBSET KEYS`
abstracts away the INI parser: the spec verifies the validator logic
independently of parsing details.

## Theorems

Three safety theorems, all proved by the canonical inductive-invariant pattern:
base case from `Init`, step case by case-analysis on `[Next]_vars`, conclusion
by `PTL`.

**`TypeCorrect`** — `Spec => []TypeOK`.

`state` always belongs to `{"init","accepted","rejected"}` and
`user_preferences_keys` is always a subset of `KEYS`. Standard structural
invariant; all obligations discharge by `BY DEF`.

**`AcceptanceCorrect`** — `Spec => []Acceptance`.

Nothing reaches `"accepted"` without `criterion` having held at the moment of
decision. Since `user_preferences_keys` is unchanged after `Validate`, it
continues to hold. All obligations discharge by `BY DEF`.

**`AcceptanceConverseCorrect`** — `Spec => []AcceptanceConverse`

## Verification — TLC

```
\* Preferences.cfg  (illustrative — partition is a placeholder)
SPECIFICATION Spec

CONSTANTS
  KEYS             = { "engine", "document", "fonts.main", "language",
                       "package:tikz", "package:tables", "intruder" }
  LUALATEX         = { "engine", "document", "fonts.main", "language",
                       "package:tikz", "package:tables" }
  LUALATEX_CORE    = { "engine", "document", "fonts.main", "language" }
  LUALATEX_OPTIONS = { "package:tikz", "package:tables" }

INVARIANT TypeOK
INVARIANT Acceptance
INVARIANT AcceptanceConverse
```

`"intruder"` belongs to `KEYS` but not `LUALATEX`, exercising the C1-violating
branch. Any `user_preferences_keys` that omits a `LUALATEX_CORE` key exercises
the C2-violating branch. Both should land in `"rejected"`.

## Verification — TLAPS

Open `Preferences.tla` in the TLA+ Toolbox and select *Prove obligations*.
All three theorems should discharge against the default backends (SMT, Zenon).
If an obligation does not close, the usual remedies are appending `OBVIOUS` to
a leaf step or nominating the backend explicitly (e.g. `BY SMT DEF …`).

## What the spec deliberately does *not* assert

- **No liveness.** `Spec == Init /\ [][Next]_vars` admits permanent stuttering.
  This matches the deployment model: the validator runs once per invocation.
  Adding `WF_vars(Validate)` would assert "eventually a decision is made" if a
  liveness obligation is required in a future version.
- **No value typing.** Only the key set matters for the current contract.
  Value constraints (types, ranges, cross-key consistency) are deferred.

## Map to the Python implementation (forthcoming)

| TLA+ artifact             | Python counterpart                                           |
| ------------------------- | ------------------------------------------------------------ |
| `state` variable        | `enum PreferencesState { INIT, ACCEPTED, REJECTED }`       |
| `user_preferences_keys` | `set(user_preference_.keys())`                             |
| `Validate` action       | INI parse +`if criterion(keys): … else: …` in one call   |
| `criterion(S)`          | a pure validator function on `set[str]`                    |
| `LUALATEX*` constants   | module-level `frozenset`s, loaded from the `.txt` record |

## Open items for the next step

1. Fix the concrete partition `LUALATEX_CORE` vs `LUALATEX_OPTIONS` over the
   41 keys in `specifications.functional.latex.keys.2.0.0.txt`. Until supplied,
   TLC runs use the illustrative `.cfg` above.
2. Decide whether liveness (eventual termination of the validator) belongs in
   the contract.

## References

- `Preferences.tla`
- `specifications.functional.latex.keys.2.0.0.txt`
- `nextStep.2.0.1.md`
- `kaizen.2.0.1.md` (update formal specifications)
