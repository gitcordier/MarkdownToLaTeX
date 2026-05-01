----------------------------- MODULE Directory -----------------------------
(******************************************************************************
  Directory.tla — formal specification AND safety proofs of the User-intent
                  decision procedure for MarkdownToLaTeX 1.0.0.

  Subject.   The User runs MarkdownToLaTeX 1.0.0 from a working directory
             DIR. Before any conversion can begin, MarkdownToLaTeX decides
             whether DIR is "ready" at the file-system layer. Four flags
             carry the evidence:
                  has_dir              — DIR exists and is a directory;
                  has_preferences      — DIR contains a `preferences`
                                         entry;
                  is_preferences_dir   — that entry is itself a directory;
                  has_JSON_preferences — DIR/preferences contains a `.json`
                                         preferences file.
             Validation of the JSON *content* (schema keys, legal values
             for "document class", etc.) is OUT OF SCOPE for this
             iteration; it is left for a later kaizen step.

  Verdict.   The decision procedure produces a single boolean:
                  verdict = TRUE  — DIR is ready; conversion may proceed.
                  verdict = FALSE — readiness is not yet established.
             The failure path (a separate "NOT_MUST_DO" terminal verdict
             carried by earlier iterations) is OUT OF SCOPE for 1.3.5.
             With no failure action, the only terminal state has
             verdict = TRUE; intermediate states keep verdict = FALSE.

  Semantics. Proof-state, not Kripke. The variable `directory` does not
             describe the filesystem; it records the evidence we have
             accumulated about the filesystem. Every flag starts FALSE
             ("nothing proven yet") and may flip to TRUE only as the
             corresponding check succeeds. A flag never flips back.

  Author.    Jean-Gabriel Cordier, with Claude.
  Origin.    Earlier draft Tue Aug 08 2023 by gcordier.
  This file. Kaizen step 1.3.5 — the four-step file-system chain with
             safety theorems T1-T5 and TLAPS proof bodies. Liveness
             (and the failure path) remain out of scope.
 *****************************************************************************)

EXTENDS TLAPS, FiniteSets, Naturals

(*===========================================================================*)
(*                                VARIABLES                                  *)
(*===========================================================================*)
(*                                                                           *)
(*  directory — proof flags accumulated about DIR. Each leaf is FALSE        *)
(*              initially and may flip to TRUE only via a SUCCESS action.    *)
(*              Flags never flip back.                                       *)
(*                                                                           *)
(*  verdict   — FALSE while readiness has not been established;              *)
(*              TRUE once all four flags are proven.                         *)
(*                                                                           *)
(*===========================================================================*)

VARIABLES directory, verdict

vars == << directory, verdict >>

(*===========================================================================*)
(*                              TYPE INVARIANT                               *)
(*===========================================================================*)

Type == [
    has_dir              : BOOLEAN,
    has_preferences      : BOOLEAN,
    is_preferences_dir   : BOOLEAN,
    has_JSON_preferences : BOOLEAN
  ]

TypeOK ==
    /\ directory \in Type
    /\ verdict   \in BOOLEAN

(*===========================================================================*)
(*                          PROOF-FLAG ACCESSORS                             *)
(*===========================================================================*)
(*  Convention: steps 1..4 line up with the four flags in `directory`.       *)
(*  Proven(n) returns the boolean evidence flag for step n.                  *)
(*===========================================================================*)

Proven(n) ==
    CASE n = 1 -> directory.has_dir
      [] n = 2 -> directory.has_preferences
      [] n = 3 -> directory.is_preferences_dir
      [] n = 4 -> directory.has_JSON_preferences
      [] OTHER -> FALSE

AllProven     == \A n \in 1..4 : Proven(n)
NothingProven == \A n \in 1..4 : ~ Proven(n)

(*  ChainOrder — the linear chain ordering, expressed as a state predicate.  *)
(*  In any reachable state, a flag can be TRUE only if every earlier flag    *)
(*  is also TRUE.  Enforced by the action guards; restated here as a         *)
(*  stand-alone invariant for use in the proof of Soundness.                 *)

ChainOrder ==
    /\ Proven(2) => Proven(1)
    /\ Proven(3) => Proven(2)
    /\ Proven(4) => Proven(3)

(*===========================================================================*)
(*                                  INIT                                     *)
(*===========================================================================*)

InitDirectory ==
    /\ directory.has_dir              = FALSE
    /\ directory.has_preferences      = FALSE
    /\ directory.is_preferences_dir   = FALSE
    /\ directory.has_JSON_preferences = FALSE

Init ==
    /\ directory \in Type
    /\ InitDirectory
    /\ verdict = FALSE

(*===========================================================================*)
(*                              SUCCESS ACTIONS                              *)
(*===========================================================================*)
(*  Each action:                                                             *)
(*    (1) requires its predecessor (if any) is proven and itself is not;     *)
(*    (2) flips its proof flag from FALSE to TRUE in `directory`;            *)
(*    (3) leaves `verdict` unchanged unless this is the final step           *)
(*        (NextHasJsonPreferences), in which case `verdict := TRUE`.         *)
(*  No failure action is defined in this iteration.                          *)
(*===========================================================================*)

NextHasDir ==
    /\ ~ Proven(1)
    /\ directory' = [directory EXCEPT !.has_dir = TRUE]
    /\ UNCHANGED verdict

NextHasPreferences ==
    /\ Proven(1)
    /\ ~ Proven(2)
    /\ directory' = [directory EXCEPT !.has_preferences = TRUE]
    /\ UNCHANGED verdict

NextIsPreferencesDir ==
    /\ Proven(2)
    /\ ~ Proven(3)
    /\ directory' = [directory EXCEPT !.is_preferences_dir = TRUE]
    /\ UNCHANGED verdict

NextHasJsonPreferences ==
    /\ Proven(3)
    /\ ~ Proven(4)
    /\ directory' = [directory EXCEPT !.has_JSON_preferences = TRUE]
    /\ verdict'   = TRUE

(*===========================================================================*)
(*                                   NEXT                                    *)
(*===========================================================================*)

Next ==
    \/ NextHasDir
    \/ NextHasPreferences
    \/ NextIsPreferencesDir
    \/ NextHasJsonPreferences

(*===========================================================================*)
(*                                   SPEC                                    *)
(*===========================================================================*)
(*  Safety only.  No fairness clause: liveness (the procedure eventually     *)
(*  terminates) is left for a later kaizen step along with the failure       *)
(*  path.                                                                    *)
(*===========================================================================*)

Spec == Init /\ [][Next]_vars

(*===========================================================================*)
(*                               INVARIANTS                                  *)
(*===========================================================================*)

(*  I1 — Type-correctness. *)
Inv_TypeOK == TypeOK

(*  I2 — Verdict stability: once verdict = TRUE, verdict stays TRUE. *)
Inv_VerdictStable ==
    [][verdict = TRUE => verdict' = TRUE]_vars

(*  I3 — Chain ordering: a flag is TRUE only if every earlier flag is. *)
Inv_ChainOrder == ChainOrder

(*  I4 — Soundness (positive): verdict = TRUE iff every flag is TRUE. *)
Inv_Soundness_TRUE ==
    (verdict = TRUE) <=> AllProven

(*  I5 — Soundness (negative): the contrapositive form of I4. *)
Inv_Soundness_FALSE ==
    (verdict = FALSE) <=> ~ AllProven

(*===========================================================================*)
(*                                THEOREMS                                   *)
(*===========================================================================*)
(*  T1 — Type-correctness is preserved.                                      *)
(*  Standard inductive invariant.  Each EXCEPT update preserves the record   *)
(*  shape because the field being touched already had type BOOLEAN and is    *)
(*  set to TRUE.                                                             *)
(*===========================================================================*)

THEOREM TypeCorrectness == Spec => []TypeOK
<1>1. Init => TypeOK
  BY DEF Init, InitDirectory, TypeOK, Type
<1>2. TypeOK /\ [Next]_vars => TypeOK'
  <2> SUFFICES ASSUME TypeOK, [Next]_vars PROVE TypeOK'
    OBVIOUS
  <2> USE DEF TypeOK, Type
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars
  <2>2. CASE NextHasDir
    BY <2>2 DEF NextHasDir
  <2>3. CASE NextHasPreferences
    BY <2>3 DEF NextHasPreferences
  <2>4. CASE NextIsPreferencesDir
    BY <2>4 DEF NextIsPreferencesDir
  <2>5. CASE NextHasJsonPreferences
    BY <2>5 DEF NextHasJsonPreferences
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5 DEF Next, vars
<1> QED BY <1>1, <1>2, PTL DEF Spec

(*===========================================================================*)
(*  T2 — Verdict stability: once decided, verdict remains TRUE.              *)
(*  The only action that changes verdict is NextHasJsonPreferences, which    *)
(*  sets verdict' = TRUE.  All other actions leave verdict unchanged.        *)
(*===========================================================================*)

THEOREM VerdictStability == Spec => Inv_VerdictStable
<1>1. ASSUME [Next]_vars, verdict = TRUE
      PROVE  verdict' = TRUE
  <2>1. CASE UNCHANGED vars
    BY <1>1, <2>1 DEF vars
  <2>2. CASE NextHasDir
    BY <1>1, <2>2 DEF NextHasDir
  <2>3. CASE NextHasPreferences
    BY <1>1, <2>3 DEF NextHasPreferences
  <2>4. CASE NextIsPreferencesDir
    BY <1>1, <2>4 DEF NextIsPreferencesDir
  <2>5. CASE NextHasJsonPreferences
    BY <2>5 DEF NextHasJsonPreferences
  <2> QED
    BY <1>1, <2>1, <2>2, <2>3, <2>4, <2>5 DEF Next, vars
<1> QED
  BY <1>1, PTL DEF Spec, Inv_VerdictStable

(*===========================================================================*)
(*  T3 — Chain-ordering invariant.  A proof flag is TRUE only when every     *)
(*  earlier flag is TRUE.                                                    *)
(*  Init has every flag FALSE so the implications hold vacuously; each       *)
(*  action's guard demands the previous flag is TRUE before flipping the     *)
(*  next, preserving the chain.                                              *)
(*===========================================================================*)

THEOREM ChainOrderInvariant == Spec => []Inv_ChainOrder
<1>1. Init => Inv_ChainOrder
  BY DEF Init, InitDirectory, Inv_ChainOrder, ChainOrder, Proven
<1>2. TypeOK /\ Inv_ChainOrder /\ [Next]_vars => Inv_ChainOrder'
  <2> SUFFICES ASSUME TypeOK, Inv_ChainOrder, [Next]_vars
               PROVE  Inv_ChainOrder'
    OBVIOUS
  <2> USE DEF TypeOK, Type, Inv_ChainOrder, ChainOrder, Proven
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars 
  <2>2. CASE NextHasDir
    BY <2>2 DEF NextHasDir
  <2>3. CASE NextHasPreferences
    BY <2>3 DEF NextHasPreferences
  <2>4. CASE NextIsPreferencesDir
    BY <2>4 DEF NextIsPreferencesDir
  <2>5. CASE NextHasJsonPreferences
    BY <2>5 DEF NextHasJsonPreferences
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5 DEF Next, vars
<1> QED
  BY <1>1, <1>2, TypeCorrectness, PTL DEF Spec

(*===========================================================================*)
(*  T4 — Soundness (positive form).                                          *)
(*  Inductive, with ChainOrder as a side condition.  The only action that    *)
(*  changes verdict is NextHasJsonPreferences; its guard requires every      *)
(*  predecessor proven, so AllProven becomes TRUE simultaneously with        *)
(*  verdict := TRUE.  Other actions leave verdict at FALSE while AllProven   *)
(*  is held at FALSE by the missing-flag predecessor argument from           *)
(*  ChainOrder.                                                              *)
(*===========================================================================*)

THEOREM Soundness == Spec => []Inv_Soundness_TRUE
<1>1. Init => Inv_Soundness_TRUE
  BY DEF Init, InitDirectory, Inv_Soundness_TRUE, AllProven, Proven
<1>2. TypeOK /\ Inv_ChainOrder /\ Inv_Soundness_TRUE /\ [Next]_vars
        => Inv_Soundness_TRUE'
  <2> SUFFICES ASSUME TypeOK, Inv_ChainOrder, Inv_Soundness_TRUE,
                      [Next]_vars
               PROVE  Inv_Soundness_TRUE'
    OBVIOUS
  <2> USE DEF TypeOK, Type, Inv_ChainOrder, ChainOrder,
              Inv_Soundness_TRUE, AllProven, Proven
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars
  <2>2. CASE NextHasDir
    BY <2>2 DEF NextHasDir
  <2>3. CASE NextHasPreferences
    BY <2>3 DEF NextHasPreferences
  <2>4. CASE NextIsPreferencesDir
    BY <2>4 DEF NextIsPreferencesDir
  <2>5. CASE NextHasJsonPreferences
    BY <2>5 DEF NextHasJsonPreferences
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5 DEF Next, vars
<1> QED
  BY <1>1, <1>2, TypeCorrectness, ChainOrderInvariant, PTL DEF Spec

(*===========================================================================*)
(*  T5 — Soundness (negative form), corollary of T4.                         *)
(*  Since verdict ∈ BOOLEAN, "verdict = FALSE" is the negation of            *)
(*  "verdict = TRUE", and the biconditional flips to give                    *)
(*  verdict = FALSE iff ~ AllProven.                                         *)
(*===========================================================================*)

THEOREM SoundnessFalse == Spec => []Inv_Soundness_FALSE
<1>1. TypeOK /\ Inv_Soundness_TRUE => Inv_Soundness_FALSE
  BY DEF TypeOK, Inv_Soundness_TRUE, Inv_Soundness_FALSE
<1> QED
  BY TypeCorrectness, Soundness, <1>1, PTL

(*===========================================================================*)
(*                            END OF PROOFS                                  *)
(*===========================================================================*)

=============================================================================
\* Modification History
\* Last modified Fri May 01 17:24:28 CEST 2026 by gcordier
