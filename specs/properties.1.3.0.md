# properties

## Version

1.3.0

## Subject

Proof strategy for theorems T1–T6 stated in `specifications.formal.1.3.0.md`
and now carried with proof bodies in `Directory.1.3.0.tla.txt`. This
document is the *Properties* slot of the kaizen flow described in
`kaizen.1.3.0.md`: it explains how each obligation is discharged by
TLAPS, what each proof actually rests on, and where iteration in the TLA
Toolbox is expected.

The transient weakening on `markdown_to_latex` remains in force, exactly
as in 1.3.0's specification slot.

## Companion deliverables

| File                              | Role                                                            |
|-----------------------------------|-----------------------------------------------------------------|
| `Directory.1.3.0.tla.txt`         | TLA+ module with all proof bodies — replaces the prior draft.   |
| `properties.1.3.0.md`             | this document — proof strategy and iteration guide.             |
| `properties.figures.1.3.0.tex`    | LuaLaTeX file with three TikZ figures supporting the narrative. |

## Reading order in this document

§1 maps theorems to the spec, names the helpers, and gives a one-line
strategy for each.
§2 explains the proof-state idiom that makes everything inductive.
§3–§9 walk theorem by theorem.
§10 lists what is OMITTED and how the user is expected to iterate in the
TLA Toolbox.

---

## 1. Theorem map

The proof-dependency DAG is the subject of Figure 2 in
`properties.figures.1.3.0.tex`. Stated in prose:

| ID  | Theorem                                              | Depends on               | Strategy            |
|-----|------------------------------------------------------|--------------------------|---------------------|
| T1  | `Spec ⇒ □TypeOK`                                    | (none)                   | inductive invariant |
| T2  | `Spec ⇒ Inv_VerdictStable`                           | (none)                   | action-level case   |
| H   | `Spec ⇒ □Inv_ProvenAttempted` (helper lemma)         | T1                       | inductive invariant |
| T5  | `Spec ⇒ □Inv_MustDoSound`                            | T1                       | inductive invariant |
| T6  | `Spec ⇒ □Inv_NotMustDoSound`                         | T1, H                    | inductive invariant |
| T4  | `Spec ⇒ □(Terminated ⇒ XORComplete)`                | T1                       | tautology in alphabet |
| T3  | `Spec ⇒ ◇Terminated`                                | T1, fairness, leads-to chain | WF1 chain           |

T3 is the only liveness obligation and is consequently the only one with
an `OMITTED` proof body in the TLA module — see §9 below.

## 2. The proof-state idiom

`Directory.tla` does not model the filesystem; it models the *evidence
we have accumulated about a fixed filesystem*. Every proof flag starts
`FALSE` and may flip to `TRUE` only via the corresponding success
action; flags never flip back. The `attempted` record disambiguates "not
yet attempted" from "attempted and refuted."

Two structural properties drop out of this idiom and make every safety
proof straightforward:

- *Monotonicity of evidence.* Each success action flips exactly one
  proof flag, from `FALSE` to `TRUE`. No action ever flips a flag from
  `TRUE` to `FALSE`. The same holds for `attempted`.
- *Verdict latching.* Every action that *changes* `verdict` is guarded
  by `Ready(_)`, which itself requires `verdict = "UNKNOWN"`. So once
  `verdict ≠ "UNKNOWN"`, no Ready-guarded action can fire — only stutter
  is enabled. T2 is the formal statement of this fact.

Both properties are inductive: they hold at `Init` (vacuously, in the
verdict-latching case) and are preserved by every disjunct of `Next`.
That is the entire shape of every safety proof in this module.

## 3. T1 — Type-correctness

**Statement.** `Spec ⇒ □TypeOK`.

**Strategy.** Standard inductive invariant. Two-step proof:

1. `Init ⇒ TypeOK`. Direct: unfolding `Init` and `InitDirectory` gives
   a `directory` literal whose every leaf is `FALSE ∈ BOOLEAN`, an
   `attempted` function whose every entry is `FALSE`, and `verdict =
   "UNKNOWN" ∈ Verdict`.
2. `TypeOK ∧ [Next]_vars ⇒ TypeOK'`. By cases on the eleven disjuncts of
   `[Next]_vars` (nine successes, one failure family, plus stutter).
   For every success action, the EXCEPT update preserves the record
   shape because the field being updated already had type `BOOLEAN` and
   is being set to `TRUE`. For failure, `directory` is unchanged, and
   `attempted'` and `verdict'` stay in their respective sets. Stutter
   is trivial.

**Discharge.** Each case is `BY <case>, DEF <action>, <helper>`. TLAPS
should close every case automatically given the right `DEF` hints.

**Iteration risk.** Low. If anything fails, the most likely culprit is
the dotted-path EXCEPT syntax (e.g. `[directory EXCEPT
!.preferences.is_dir = TRUE]`). If TLAPS chokes on it, replace with the
explicit nested form `[directory EXCEPT !.preferences = [@ EXCEPT
!.is_dir = TRUE]]` — semantically identical, easier on the parser.

## 4. T2 — Verdict stability

**Statement.** `Spec ⇒ Inv_VerdictStable`, i.e. `□[verdict ≠ "UNKNOWN"
⇒ verdict' = verdict]_vars`.

**Strategy.** Action-level invariant. The proof in the module shows the
action-relation `[Next]_vars ∧ verdict ≠ "UNKNOWN" ⇒ verdict' = verdict`
and lifts it to the temporal statement via PTL.

**Why it works in one step per case.** For each of the eight non-final
success actions, `UNCHANGED verdict` is a conjunct, so `verdict' =
verdict` immediately. For the final success action and for any
`Fail(s)`, `Ready(_)` requires `verdict = "UNKNOWN"`, contradicting the
hypothesis — so those cases close by contradiction. Stutter is direct.

**Iteration risk.** Low. The proof is mechanical case-splitting.

## 5. Helper H — `Inv_ProvenAttempted`

**Statement.** `Spec ⇒ □(∀s ∈ Step : Proven(s) ⇒ attempted[s])`.

**Why we need it.** T6 (NotMustDoSoundness) requires deducing that some
flag is `FALSE` after `Fail(s)` fires. `Fail(s)` is guarded by
`Ready(s)`, which requires `¬attempted[s]`. The bridge "from
`¬attempted[s]`, conclude `¬Proven(s)`" is exactly the contrapositive of
this helper.

**Strategy.** Inductive. At `Init`, every `Proven(s)` is `FALSE`, so the
implication is vacuous. In the step case, the only actions that flip a
proof flag are the nine success actions, and each of them simultaneously
sets the corresponding `attempted` entry. Failures and stutter never
flip a proof flag, and `attempted` only grows. So the invariant is
preserved.

**Iteration risk.** Low. Same shape as T1, just on a slightly
non-trivial state predicate.

## 6. T5 — `MUST_DO` soundness

**Statement.** `Spec ⇒ □(verdict = "MUST_DO" ⇒ AllProven)`.

**Strategy.** Inductive. Init has `verdict = "UNKNOWN" ≠ "MUST_DO"`, so
the implication is vacuous.

For the step case, suppose `verdict' = "MUST_DO"`. Two subcases:

- *The action does not change `verdict`* (any `Check_*_SUCCESS` save the
  final, plus stutter). Then `verdict = "MUST_DO"` pre-state. By the
  inductive hypothesis, `AllProven` held pre-state. The non-final
  success actions all require `Ready(_)`, which requires `verdict =
  "UNKNOWN"` — contradiction; these subcases are vacuous. Only stutter
  survives, which preserves `AllProven`.
- *The action changes `verdict` to `"MUST_DO"`*. The only such action
  is `Check_JSON_DOC_CLASS_LEGAL_SUCCESS`. Its `Ready` guard requires
  every predecessor proven (steps 1..8); the action itself flips the
  ninth flag. So `AllProven'` holds.

**Iteration risk.** Low to moderate. The most likely place TLAPS may
need help is unfolding `Predecessors("json_document_class_legal")` to
literally enumerate the eight predecessor strings. If needed, supply
`DEF Predecessors` explicitly and add a one-step lemma stating the
equality with the literal set.

## 7. T6 — `NOT_MUST_DO` soundness

**Statement.** `Spec ⇒ □(verdict = "NOT_MUST_DO" ⇒ ¬AllProven)`.

**Strategy.** Inductive, using H as a side condition.

The only action setting `verdict' = "NOT_MUST_DO"` is `Fail(s)` for some
`s`. `Ready(s)` requires `¬attempted[s]`. By H, `Proven(s)` is also
`FALSE`. `Fail(s)` leaves `directory` unchanged, so `Proven(s)' =
Proven(s) = FALSE`, witnessing `¬AllProven'`.

For every other action that changes `verdict`, the change is to
`"MUST_DO"`, contradicting `verdict' = "NOT_MUST_DO"`. For non-changing
actions, `verdict = "NOT_MUST_DO"` pre-state, and the same `Ready`
argument as in T5 makes those subcases vacuous (only stutter survives;
`directory` unchanged; ¬`AllProven` carried over by IH).

**Iteration risk.** Moderate. The tricky bit is the joint induction
with H. The proof in the module already lists both as preconditions
in the `<1>2` step and pulls both in at QED time via
`TypeCorrectness, ProvenAttemptedInvariant`. If TLAPS struggles, split
out a tiny intermediate lemma "`Fail(s) ∧ TypeOK ∧ Inv_ProvenAttempted
⇒ ¬Proven(s)'`" and chain it.

## 8. T4 — XOR-completeness

**Statement.** `Spec ⇒ □(Terminated ⇒ XORComplete)`.

**Strategy.** This is essentially propositional. `Terminated` says
`verdict ∈ {"MUST_DO", "NOT_MUST_DO"}`. `XORComplete` says exactly one
of those two equalities holds. Since `"MUST_DO"` and `"NOT_MUST_DO"`
are syntactically distinct strings, the verdict equals exactly one of
them — that is the XOR.

The proof in the module establishes this by quantifying over `Verdict`
(three values), discarding `"UNKNOWN"` via `Terminated`, and observing
that the remaining two are mutually exclusive. T1 is invoked only to
establish that `verdict ∈ Verdict` in every reachable state, so that
the universal quantifier covers the actual verdict value.

**Iteration risk.** Negligible. If TLAPS needs anything extra, it's
typically a `BY DEF Verdict` to make the three string values visible.

## 9. T3 — Termination (the liveness obligation)

**Statement.** `Spec ⇒ ◇Terminated`.

**Strategy.** Weak fairness on `Next` plus the chain having finite
length. We formalize this as a leads-to chain on the family

    P(k) ≡ Terminated ∨ AttemptedCount ≥ k

with `AttemptedCount` defined as `Cardinality({s ∈ Step : attempted[s]})`.

The chain is: `P(0) ⇝ P(1) ⇝ … ⇝ P(9)`, plus `Init ⇒ P(0)` and `P(9)
⇒ Terminated` (under TypeOK). Composed:

    Spec ⇒ P(0) ⇝ P(9) ⇒ Terminated, hence Spec ⇒ ◇Terminated.

Each link `P(k) ⇝ P(k+1)` is one application of the WF1 inference rule:

    WF1.  ASSUME (P /\ [Next]_v) => (P' \/ Q'),
                 (P /\ <<Next /\ A>>_v) => Q',
                 P => ENABLED <<A>>_v,
                 Spec includes WF_v(A)
          PROVE  Spec => (P ~> Q)

with `P ≡ ¬Terminated ∧ AttemptedCount = k`, `Q ≡ P(k+1)`, and `A` the
witness action — for which `Next` itself suffices, because at any
non-terminated state with `AttemptedCount = k`, the (k+1)-th step in the
chain is `Ready` and therefore enables `Next`.

**Why the proof bodies are OMITTED.** The skeleton in
`Directory.1.3.0.tla.txt` states the nine `Step{k}_{k+1}` lemmas with
`PROOF OMITTED`. Discharging each link requires:

1. an explicit witness for "the (k+1)-th step in the chain" — i.e. a
   constant function `chain(k+1)` mapping {1, …, 9} to `Step`;
2. a small enabledness lemma showing that at `AttemptedCount = k`,
   `Ready(chain(k+1))` holds, hence `Next` is enabled;
3. an action-level lemma showing that any non-stutter `Next` increments
   `AttemptedCount` by exactly one or sets `Terminated`;
4. the WF1 instance assembled from (1)–(3).

The bookkeeping is mechanical but verbose — best-suited to interactive
iteration in the TLA Toolbox rather than to dense first-pass authoring.
The composition step in `THEOREM Termination` (`<1>1` chains the nine
links via PTL) is itself routine; it depends only on the link lemmas
having the form `Spec ⇒ (P(k) ⇝ P(k+1))`.

**Helper `P9ImpliesTerminated`** is also written with a thin proof body.
The argument: `AttemptedCount ≥ 9` plus `|Step| = 9` (which TLAPS gets
from `DEF Step`) plus subset-of-finite-is-finite forces every step to
have been attempted. The 9th attempted-step transition was either the
final success (verdict ⇝ `MUST_DO`) or some `Fail` (verdict ⇝
`NOT_MUST_DO`); either way `Terminated`. The cardinality bookkeeping is
the same shape as in `InitImpliesP0` and benefits from the same
`FiniteSetTheorems` lemmas if TLAPS needs them.

**Iteration risk.** High — but bounded. T3 is the only theorem with
`OMITTED` proofs and is the expected locus of the next round of work.
None of the omissions risk the safety proofs (T1, T2, T4, T5, T6),
which are independent.

## 10. What's OMITTED and how to discharge it

In `Directory.1.3.0.tla.txt`:

| Lemma                  | Status | Iteration recipe                                                 |
|------------------------|--------|------------------------------------------------------------------|
| `InitImpliesP0`        | thin   | Add `EXTENDS FiniteSetTheorems`; instantiate `FS_CardinalityType`. |
| `P9ImpliesTerminated`  | thin   | Same; plus a small lemma `Cardinality(Step) = 9`.                |
| `Step{k}_{k+1}` (×9)   | OMITTED | One WF1 application each, per the recipe in §9.                 |

Everything else carries a structured proof body that should be
TLAPS-checkable as written, modulo small `BY DEF` adjustments that the
Toolbox surfaces interactively.

## 11. Once these are discharged

Per `kaizen.1.3.0.md`, the next kaizen step opens the *Python
implementation* slot: `utilities.py` and `user/call.py` realize the nine
TLA actions as predicates with a one-to-one mapping (already tabulated
in `specifications.formal.1.3.0.md`, §7). The Python code becomes a
witness for the spec, and the spec becomes a contract for the code.

The transient weakening on `markdown_to_latex` is lifted in a later
kaizen step, after the directory-readiness contract is honored end to
end.
