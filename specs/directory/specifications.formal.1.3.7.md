# specifications.formal

## Version

1.3.7

## Subject

Formal specification *and* machine-checked safety proofs of the User-intent
decision procedure for MarkdownToLaTeX 1.0.0, per `nextStep_1_3_6.md`.

This document accompanies the TLA+ module `Directory.1.3.7.tla` and the
LuaLaTeX figures file `figures.1.3.7.tex`. It is the deliverable of kaizen
step 1.3.7 and supersedes `specifications.formal.1.3.0.md`.

## Transient weakening still in force

`markdown_to_latex(input)` is the identity mapping. The decision procedure
specified here governs whether the User's working directory is *ready* for
that mapping; it does not specify the mapping itself.

---

## 1. The question being formalized

The User runs MarkdownToLaTeX 1.0.0 from a working directory `DIR`. Before
any conversion can begin, the package must decide whether `DIR` is *ready*
at the file-system layer:

1. `is_dir`: `DIR` exists and is a directory;
2. `has_preferences_dir`: `DIR/preferences` exists and is a directory;
3. `has_JSON_preferences`: `DIR/preferences/preferences.json` exists and
   is a regular file.

The answer is one of two **terminal verdicts**:

| Verdict    | Meaning                                              |
| ---------- | ---------------------------------------------------- |
| `OK`     | `DIR` passed all three checks; conversion may run. |
| `NOT_OK` | `DIR` failed some check; conversion must not run.  |

The headline property required by `nextStep_1_3_6.md` is

> `OK XOR NOT_OK = TRUE` whenever the procedure has halted,

i.e. the procedure is **deterministic** at every reachable state (the
verdicts are mutually exclusive) and **total** at every halt state (one
of the two verdicts holds).

Validation of the JSON *content* (schema keys, legal value of
`"document class"`, etc.) is **out of scope** for this iteration. It is
deferred to a later kaizen step. This is the only material reduction in
scope from `specifications.formal.1.3.0.md`, which carried nine checks.

---

## 2. Semantic stance: two records, two semantics

`Directory.1.3.7.tla` does **not** model the file system as a state that
mutates over time. It models the *evidence we have accumulated* about a
fixed file system, and it does so with two records of the same structural
type but opposite reading conventions:

- **`directory : Knowledge`** — the *trial verdict*. Each flag is `TRUE`
  unless and until a check disproves it. `Init` sets every flag to `TRUE`
  (no disproof yet). Transitions can only flip `TRUE` → `FALSE`, and never
  back. So `directory.is_dir = FALSE` means *step 1 has been disproved*;
  `directory.is_dir = TRUE` means *step 1 has not been disproved (yet)*.
- **`check : Knowledge`** — the *inquiry log*. Each flag is `TRUE` iff the
  corresponding check has been performed. `Init` sets every flag to
  `FALSE` (no inquiry yet). Transitions can only flip `FALSE` → `TRUE`,
  and never back. So `check.is_dir = TRUE` means *step 1's check has been
  run*; `check.is_dir = FALSE` means *step 1's check has not yet run*.

This is the key change from version 1.3.0, which used a single `directory`
record of proof flags plus a separate `attempted` record. The 1.3.7
formulation merges those two ideas into one structural type and lets the
*action shapes* carry the meaning. The shared type is named `Knowledge`.

The asymmetry of `Init` (`TRUE` for trial, `FALSE` for inquiry) is what
makes the headline XOR provable as a state-level disjointness lemma rather
than as a liveness property.

---

## 3. The chain of three checks

The procedure is a linear chain. Each step has two action shapes — a
success and a failure — and a guard that keeps subsequent steps from
firing once a failure has occurred.

| # | Step name                | TLA+ guard                                                               | Proves                                                 |
| - | ------------------------ | ------------------------------------------------------------------------ | ------------------------------------------------------ |
| 1 | `is_dir`               | `NothingHasBeenChecked /\ NothingHasBeenDisproved`                     | `DIR` is a directory                                 |
| 2 | `has_preferences_dir`  | `hasBeenChecked(1) /\ hasNotBeenChecked(2) /\ ND`                      | `DIR/preferences` is a directory                     |
| 3 | `has_JSON_preferences` | `hasBeenChecked(1) /\ hasBeenChecked(2) /\ hasNotBeenChecked(3) /\ ND` | `DIR/preferences/preferences.json` is a regular file |

`ND` abbreviates `NothingHasBeenDisproved` in the guards above. This
clause is what closes the chain after the first failure: once any flag
has been flipped to `FALSE` in `directory`, every step's guard becomes
unsatisfiable, and only `NoDeadlockNext` fires.

For each step `n`, the success action `Next*` flips `check.<n> := TRUE`
and leaves `directory` unchanged; the failure action `NextNo*` flips
`check.<n> := TRUE` *and* `directory.<n> := FALSE` simultaneously. The
two halves of each action are not parallel: the failure action mutates
both records in one atomic step.

`NoDeadlockNext` is the four-way disjunction of stutter steps, one per
halt configuration (success at step 3, failure at step 1, failure at
step 2, failure at step 3). All four share the same body
`UNCHANGED <<directory, check>>`, so they collapse to a single
state-transition shape in any safety proof.

---

## 4. State-transition diagram and reachable space

The reachable state space has exactly seven states, arranged as a depth-3
tree rooted at `Init`. They are drawn in **figure F1** of
`figures.1.3.7.tex`. The companion **figure F2** in the same file shows
the truth-table evaluation of `OK`, `NOT_OK`, `OK ∨ NOT_OK`, `OK ∧ NOT_OK`, and `OK ⊕ NOT_OK` at each of the seven reachable states.

Three of the seven states are *pending* (neither verdict holds, the chain
has not yet halted). Four are *halt* states: one `OK`, three `NOT_OK`
(one per step at which the procedure can fail).

---

## 5. Module structure (`Directory.1.3.7.tla`)

| Section                                                                                                        | Role                                                                            |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `EXTENDS`                                                                                                    | `TLAPS, FiniteSets, Naturals`                                                 |
| `VARIABLES`                                                                                                  | `directory`, `check`                                                        |
| `Knowledge`, `TypeOK`                                                                                      | shared structural record type and its instantiation                             |
| `isTrue(n)`, `hasBeenDisproved(n)`                                                                         | proof-flag accessors over `directory`                                         |
| `hasBeenChecked(n)`, `hasNotBeenChecked(n)`                                                                | inquiry-log accessors over `check`                                            |
| `NothingHasBeenChecked`, `NothingHasBeenDisproved`, `AllChecked`                                         | derived predicates                                                              |
| `OK`, `NOT_OK`                                                                                             | verdict predicates                                                              |
| `InitDirectory`, `InitCheck`, `Init`                                                                     | initial state (asymmetric: directory all `TRUE`, check all `FALSE`)         |
| `NecessaryCondition*`                                                                                        | shared guards for each step's success/failure pair                              |
| `NextHasDir` … `NextHasNoJsonPreferences`                                                                 | six per-step actions                                                            |
| `NoDeadlockNext*`                                                                                            | four halt-configuration stutter actions                                         |
| `Next`                                                                                                       | seven-way disjunction of all proper actions plus `NoDeadlockNext`             |
| `Spec`                                                                                                       | `Init /\ [][Next]_vars` (no fairness clause)                                  |
| `ChainOrderCheck`, `Soundness`, `DisprovalImpliesChecked`, `AtMostOneDisproved`, `VerdictsExclusive` | invariant predicates                                                            |
| `DirectoryMonotoneStep`, `CheckMonotoneStep`                                                               | step-properties for monotonicity                                                |
| `Inv`                                                                                                        | five-way conjunction of state invariants used as the master inductive invariant |
| `T_Inv`, `T1`–`T8`                                                                                      | nine theorems, all with complete TLAPS proof bodies                             |

### Why no fairness clause

This kaizen step is scoped to **safety only**. No `WF`, no `<>`, no
liveness theorem. Termination of the chain is not proven and is not
required for the headline: the XOR property reduces to a state-level
disjointness lemma between `OK` and `NOT_OK` once their definitions are
unfolded.

The cost of this scoping is that the spec admits behaviors that stutter
forever in an intermediate (pending) state. That is a faithful model of
"the User has not yet asked the file system the next question"; making
it impossible would require fairness, which is deferred.

### Why the success / failure split, and why nondeterministic

The specification does not say *which* of `Next*` and `NextNo*` fires
when a step's guard holds; the file system does. From the spec's point
of view both are admissible at every step. The implementation in
`utilities.py` / `user/call.py` resolves the nondeterminism by actually
consulting the file system.

---

## 6. Theorem inventory (T_Inv, T1–T8)

These nine theorems are stated *and proven* in `Directory.1.3.7.tla`,
with complete structured TLAPS proof bodies. They are also catalogued
in **figure F3** of `figures.1.3.7.tex`.

| ID    | Theorem                                    | Role                                                                                  |
| ----- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| T_Inv | `Spec => []Inv`                          | Master inductive invariant.                                                           |
| T1    | `Spec => []TypeOK`                       | The type invariant is preserved.                                                      |
| T2    | `Spec => []ChainOrderCheck`              | `hasBeenChecked` respects step order.                                               |
| T3    | `Spec => []Soundness`                    | A later check having run implies all earlier flags survived their checks.             |
| T4    | `Spec => []DisprovalImpliesChecked`      | Any disproved flag was actually checked.                                              |
| T5    | `Spec => []AtMostOneDisproved`           | At most one flag is `FALSE` in `directory`.                                       |
| T6    | `Spec => [][DirectoryMonotoneStep]_vars` | `directory` is monotone non-increasing.                                             |
| T7    | `Spec => [][CheckMonotoneStep]_vars`     | `check` is monotone non-decreasing.                                                 |
| T8    | `Spec => []VerdictsExclusive`            | The headline:`OK` and `NOT_OK` are disjoint, hence XOR holds at every halt state. |

### Why a single master invariant T_Inv

The invariant conjuncts (T1–T5) are mutually dependent during the
inductive step: the step-2 cases need T2 (chain order on `check`) before
T3 (soundness) can be re-established; the failure cases need T4
(disproval implies checked) to hold pointwise; T5 needs both
`NothingHasBeenDisproved` from the action's guard and T4 to rule out
prior disproofs. Bundling them into a single `Inv` and proving
`Spec => []Inv` by induction discharges all five at once. T1–T5 then
fall out as one-line corollaries.

The proof of T_Inv has the standard TLAPS three-step shape:

1. `Init => Inv` — five sub-lemmas, one per conjunct of `Inv`.
2. `Inv /\ [Next]_vars => Inv'` — eight cases on `Next` (six proper
   actions, `NoDeadlockNext`, and `UNCHANGED vars`).
3. `QED BY <1>1, <1>2, PTL DEF Spec`.

### Why T6 and T7 are independent of T_Inv

T6 and T7 are *step-properties*: they relate primed to unprimed
variables, not just states. They are therefore not state predicates and
not candidates for inclusion in `Inv`. They are proven by an independent
case-split on `[Next]_vars`, examining each action's effect on the
relevant record. The case-splits are simpler than T_Inv's because each
action's effect on `directory` (resp. `check`) is structurally trivial:
either unchanged, or one specific field flipped in the
TRUE→FALSE (resp. FALSE→TRUE) direction.

### Why T8 is a tautology

`VerdictsExclusive == ~ (OK /\ NOT_OK)` is a *propositional* tautology
once the verdict definitions are unfolded:

- `OK => NothingHasBeenDisproved` (by definition);
- `NOT_OK <=> ~NothingHasBeenDisproved` (by `\E n : ~isTrue(n) <=> ~ \A n : isTrue(n)`);
- so `OK /\ NOT_OK => FALSE`.

The TLAPS proof reduces to two `BY DEF …` lines — one for `Init` and one
for the inductive step — followed by `PTL`. No case-split on `Next` is
needed.

---

## 7. Bridge to the Python implementation

Each TLA+ step maps to a predicate that lives in `utilities.py` and is
composed by `user/call.py`, per `specifications.code.1.3.6.md`. The
mapping is one-to-one and reduces from nine entries (in 1.3.0) to three:

| TLA+ action                                               | Python predicate (proposed)                                   |
| --------------------------------------------------------- | ------------------------------------------------------------- |
| `NextHasDir` / `NextHasNoDir`                         | `is_directory(DIR)`                                         |
| `NextHasPreferencesDir` / `NextHasNoPreferencesDir`   | `is_directory(DIR / "preferences")`                         |
| `NextHasJsonPreferences` / `NextHasNoJsonPreferences` | `is_regular_file(DIR / "preferences" / "preferences.json")` |

The TLA+ verdicts map to a Python enum with two members; the User-facing
behavior of `OK` is "proceed", and of `NOT_OK` is "raise a single,
well-typed exception that names the failed step." The exception shape is
an *implementation* concern and stays out of this specification, per
the decision retiring `is_error`.

---

## 8. Out of scope and open follow-ups

1. **JSON content validation.** Schema keys (`"author"`, `"email"`,
   `"name"`, `"main font"`, `"document class"`) and legality of the
   value at `"document class"` are deferred. Adding them is a second
   linear chain of six steps grafted on after step 3, with the same
   action shape and the same monotonicity / soundness invariants. The
   1.3.0 specification has the design.
2. **Liveness.** Termination (`Spec => <>(OK \/ NOT_OK)`) requires a
   `WF_vars(Next)` clause and a separate inductive argument. This is the
   natural follow-on theorem T9 and is the principal known unprovable
   property of the current spec.
3. **Lift the transient weakening on `markdown_to_latex`** once the
   directory-readiness contract is honored by the implementation.
4. **PROJECT file and `input/markdown/` checks** (Feature 5 in
   `scopeStatement_1_2_0.md`). These are the next layers of the chain
   beyond the JSON content validation.

---

## 9. Files delivered by this kaizen step

| File                               | Role                                                                                                              |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `Directory.1.3.7.tla`            | the TLA+ module with TLAPS-checked safety theorems T1–T8                                                         |
| `specifications.formal.1.3.7.md` | this document — narrative, theorem inventory, Python bridge                                                      |
| `figures.1.3.7.tex`              | LuaLaTeX companion: state-transition diagram (F1), truth table over reachable states (F2), theorem inventory (F3) |
