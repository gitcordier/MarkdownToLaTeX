# specifications.formal

## Version

1.3.0

## Subject

Formal specification of the User-intent decision procedure for
MarkdownToLaTeX 1.0.0, per `nextStep_1_2_3.md`.

This document accompanies the TLA+ module `Directory.tla.txt`. It is the
deliverable of kaizen step 1.3.0.

## Transient weakening still in force

`markdown_to_latex(input)` is the identity mapping. The decision procedure
specified here governs whether the User's working directory is *ready* for
that mapping; it does not specify the mapping itself.

---

## 1. The question being formalized

The User runs MarkdownToLaTeX 1.0.0 from a working directory `DIR`. Before
any conversion can begin, the package must decide whether `DIR` is *ready*:
does it contain a well-formed `preferences.json` at the canonical path
`$DIR/preferences/preferences.json`, with the required schema keys at the
top level and a legal value for `"document class"`?

The answer is one of two **terminal verdicts**:

| Verdict       | Meaning                                          |
|---------------|--------------------------------------------------|
| `MUST_DO`     | `DIR` is ready; conversion may proceed.          |
| `NOT_MUST_DO` | `DIR` is not ready; conversion must not start.   |

The headline property required by `nextStep_1_2_3.md` is

> `MUST_DO XOR NOT_MUST_DO = TRUE` at termination,

i.e. the decision procedure is **total** (it always terminates) and
**deterministic** (it terminates with exactly one verdict).

---

## 2. Semantic stance: proof-state, not Kripke

`Directory.tla` does **not** model the filesystem as a state that mutates
over time. It models the *evidence we have accumulated* about a fixed
filesystem. Every proof flag starts `FALSE` (nothing proven yet) and may
flip to `TRUE` only as the corresponding check succeeds. A flag never
flips back. The starting condition is therefore literally
`Directory(FALSE, FALSE, ...)` — the empty proof state — with `Init` as
the only place where this is asserted.

To distinguish *"not yet attempted"* from *"attempted and refuted"* — the
two readings of `FALSE` — we add a per-step boolean record `attempted`.
This is option (a) from the design discussion.

---

## 3. The chain of nine checks

The procedure is a linear chain. Each step is a pair of TLA+ actions
(`*_SUCCESS` / `Fail(s)`), guarded by `Ready(s)`: every predecessor
proven, the step itself not yet attempted, the verdict still `UNKNOWN`.

| #   | Step name                       | Proves                                                          |
|-----|---------------------------------|-----------------------------------------------------------------|
| 1   | `is_dir`                        | `DIR` is a directory                                            |
| 2   | `preferences_is_dir`            | `DIR/preferences` is a directory                                |
| 3   | `preferences_has_file`          | `DIR/preferences/preferences.json` is a regular file            |
| 4a  | `json_author`                   | top-level key `"author"` present                                |
| 4b  | `json_email`                    | top-level key `"email"` present                                 |
| 4c  | `json_name`                     | top-level key `"name"` present                                  |
| 4d  | `json_main_font`                | top-level key `"main font"` present                             |
| 4e  | `json_document_class`           | top-level key `"document class"` present                        |
| 4f  | `json_document_class_legal`     | value at `"document class"` ∈ `LegalDocumentClass`              |

Step 4f is the only step that flips `verdict` to `MUST_DO`. Any failure
flips `verdict` to `NOT_MUST_DO` and halts the chain.

The two-step split between 4e (presence) and 4f (legality of value) is
deliberate: the implementation can then distinguish *"key missing"* from
*"key present but value illegal"* without losing any specification fidelity.

`LegalDocumentClass` is a `CONSTANT` of legal triples. Per the seed
choice, it is initialized in the model file with the single default
triple drawn from `scopeStatement_1_2_0.md`:

```tla
LegalDocumentClass = {
    [class |-> "article", size |-> "10pt", paper |-> "a4paper"]
}
```

Extending this set later is a model-file change; the module is untouched.

---

## 4. State-transition diagram

![Directory.tla state-transition diagram](directory_state_diagram.png)

`Init` has every proof flag `FALSE`, `attempted` all `FALSE`, and
`verdict = UNKNOWN`. Each `*_SUCCESS` action flips one flag `TRUE` and
advances the chain. The final success additionally sets
`verdict := MUST_DO`. From any `Ready` step, a `Fail(s)` action sets
`verdict := NOT_MUST_DO` and terminates.

---

## 5. Module structure (`Directory.tla.txt`)

| Section                | Role                                                                |
|------------------------|---------------------------------------------------------------------|
| `EXTENDS`              | `TLAPS, FiniteSets`                                                  |
| `CONSTANTS`            | `LegalDocumentClass` (with finiteness and shape `ASSUME`)            |
| `Verdict`, `Step`      | enumerations of the verdict alphabet and the 9 step names           |
| `Predecessors(s)`      | the linear ordering of steps                                         |
| `VARIABLES`            | `directory`, `attempted`, `verdict`                                 |
| `Type`, `TypeOK`       | shape of the proof-evidence record                                  |
| `Proven(s)`            | reads the proof flag for step `s`                                   |
| `AllProven`            | every flag `TRUE`                                                    |
| `InitDirectory`, `Init`| pristine state                                                       |
| `Ready(s)`             | guard for every step's actions                                      |
| `Check_*_SUCCESS`      | nine success actions (one per step)                                 |
| `Fail(s)`              | parameterised failure action                                        |
| `Next`                 | disjunction of the nine successes plus `\E s \in Step : Fail(s)`    |
| `Spec`                 | `Init /\ [][Next]_vars /\ WF_vars(Next)`                             |
| Invariants `Inv_*`     | type-correctness, monotonicity, verdict stability, soundness        |
| Theorems `T1`–`T6`     | obligations to be discharged in the next kaizen iteration           |

### Why weak fairness on `Next`

Without `WF_vars(Next)`, a behavior could stutter forever in an
intermediate state, neither succeeding nor failing the next check. Weak
fairness forbids that: any continuously-`Ready` step must eventually
fire. Combined with the chain's finite length (9 steps), this gives
`<>Terminated` — theorem T3.

### Why nondeterminism between `*_SUCCESS` and `Fail(s)`

The specification does not say *which* of the two fires when a step is
`Ready`; the filesystem does. From the spec's point of view both are
admissible at every step. The implementation in `utilities.py` /
`user/call.py` will resolve the nondeterminism by actually consulting the
filesystem.

---

## 6. Theorem obligations (T1–T6)

These are stated in the module; their proofs belong to the *Properties*
slot of the kaizen flow, to be discharged with TLAPS or Isabelle in a
subsequent kaizen step.

| ID  | Theorem                                                                                |
|-----|----------------------------------------------------------------------------------------|
| T1  | `Spec => []TypeOK` — the type invariant is preserved.                                  |
| T2  | `Spec => Inv_VerdictStable` — once decided, the verdict is permanent.                  |
| T3  | `Spec => <>Terminated` — the procedure halts with `verdict ∈ {MUST_DO, NOT_MUST_DO}`. |
| T4  | `Spec => [](Terminated => XORComplete)` — the headline XOR property.                   |
| T5  | `Spec => []Inv_MustDoSound` — `MUST_DO ⇒ all flags TRUE`.                              |
| T6  | `Spec => []Inv_NotMustDoSound` — `NOT_MUST_DO ⇒ at least one flag FALSE`.              |

T4 is the property `nextStep_1_2_3.md` asks for explicitly. T5 and T6
together pin down the *meaning* of the two verdicts in terms of the
proof flags, which is what makes the spec usable as a contract for the
Python implementation.

---

## 7. Bridge to the Python implementation

Each TLA+ step maps to a predicate that will live in `utilities.py` and
be composed by `user/call.py`, per `specifications_code_1_2_0_md.txt`.
The mapping is one-to-one:

| TLA+ action                            | Python predicate (proposed)                          |
|----------------------------------------|------------------------------------------------------|
| `Check_IS_DIR_SUCCESS`                 | `is_directory(DIR)`                                  |
| `Check_PREFS_IS_DIR_SUCCESS`           | `is_directory(DIR / "preferences")`                  |
| `Check_PREFS_HAS_FILE_SUCCESS`         | `is_regular_file(DIR / "preferences" / "preferences.json")` |
| `Check_JSON_AUTHOR_SUCCESS`            | `"author" in parsed`                                  |
| `Check_JSON_EMAIL_SUCCESS`             | `"email" in parsed`                                   |
| `Check_JSON_NAME_SUCCESS`              | `"name" in parsed`                                    |
| `Check_JSON_MAIN_FONT_SUCCESS`         | `"main font" in parsed`                               |
| `Check_JSON_DOC_CLASS_SUCCESS`         | `"document class" in parsed`                          |
| `Check_JSON_DOC_CLASS_LEGAL_SUCCESS`   | `parsed["document class"] in LEGAL_DOCUMENT_CLASS`    |

`LEGAL_DOCUMENT_CLASS` lives in `constants/user.py`; its value is the
Python rendering of the `LegalDocumentClass` set.

The TLA+ verdicts map to a Python enum with two members; the User-facing
behavior of `MUST_DO` is "proceed", and of `NOT_MUST_DO` is "raise a
single, well-typed exception that names the failed step." Exception
shape is an *implementation* concern and stays out of this specification,
per the decision retiring `is_error`.

---

## 8. Open follow-ups (for the next kaizen iteration)

1. Discharge T1–T6 with TLAPS. T1, T2, T5, T6 are straightforward
   inductive invariants; T3 needs a fairness argument; T4 follows from
   T2 plus the structure of the success/failure actions.
2. Lift the transient weakening on `markdown_to_latex` once the
   directory-readiness contract is honored by the implementation.
3. Add the `PROJECT` file and `input/markdown/` checks (Feature 5 in
   `scopeStatement_1_2_0.md`) — these are the next layers of the chain
   and were already foreshadowed in the original `Directoty_tla.txt`
   TODO block.

---

## 9. Files delivered by this kaizen step

| File                              | Role                                              |
|-----------------------------------|---------------------------------------------------|
| `Directory.tla.txt`               | the TLA+ module (replaces the prior draft)        |
| `specifications.formal.md`        | this document — narrative + theorems + bridge    |
| `directory_state_diagram.png`     | state-transition diagram (referenced in §4)       |
