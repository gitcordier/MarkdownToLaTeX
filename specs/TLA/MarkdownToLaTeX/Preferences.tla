--------------------------------- MODULE Preferences ------------------------------------------
(*********************************************************************************************)
(* Formal specification of preference acceptance for MarkdownToLaTeX 1.0.0.                  *)
(*                                                                                           *)
(* Project version : 2.0.1                                                                   *)
(*                                                                                           *)
(* Subject         : states, actions, invariants, and TLAPS-checkable theorems for the       *)
(*                   validation of the User's preferences.ini.                               *)
(*                                                                                           *)
(* Parametricity (key design property):                                                      *)
(*   The module never enumerates LaTeX keys. The functional record at                        *)
(*   specifications.functional.latex.keys.2.0.0.txt is the single source of truth for the    *)
(*   *contents* of LUALATEX. This module is the single source of truth for the *logic*. The  *)
(*   two evolve independently: if the functional record changes, no edit to this module is   *)
(*   required.                                                                               *)
(*                                                                                           *)
(* Acceptance contract:                                                                      *)
(*   The two MUST constraints from nextStep.2.0.1.md are *baseline* (general) criteria. The  *)
(*   Validate action uses IF/THEN/ELSE -- not iff -- so the shape of the spec admits future  *)
(*   criteria to be conjoined into the criterion predicate without disturbing the            *)
(*   surrounding state machine.                                                              *)
(*********************************************************************************************)

EXTENDS TLAPS

CONSTANTS
  KEYS,
  LUALATEX,              (* Recognized lualatex keys; subset of KEYS.                        *)
  LUALATEX_CORE,         (* Mandatory keys; subset of LUALATEX.                              *)
  LUALATEX_OPTIONS       (* Optional keys; subset of LUALATEX.                               *)

(*********************************************************************************************)
(* The LUALATEX_CORE /= {} conjunct is a domain axiom: "mandatory" implies at least one      *)
(* mandatory key. It is also what makes ~criterion({}) hold, which is needed for the base    *)
(* case of AcceptanceConverseCorrect.                                                        *)
(*********************************************************************************************)
ASSUME LualatexShape ==
  /\ LUALATEX \subseteq KEYS
  /\ LUALATEX_CORE \cup LUALATEX_OPTIONS = LUALATEX
  /\ LUALATEX_CORE \cap LUALATEX_OPTIONS = {}
  /\ LUALATEX_CORE /= {}

VARIABLES
  state,            (* "init" | "accepted" | "rejected"                                      *)
  preferences_keys  (* Key set of the parsed user_preference_.                               *)

vars == << state, preferences_keys >>

States == { "init", "accepted", "rejected" }

(*********************************************************************************************)
(* Type invariant.                                                                           *)
(*********************************************************************************************)
TypeOK ==
  /\ state \in States
  /\ preferences_keys \subseteq KEYS

(*********************************************************************************************)
(* Baseline acceptance criterion. The two MUST constraints, parametric in LUALATEX and       *)
(* LUALATEX_CORE.                                                                            *)
(*                                                                                           *)
(* Open by design: extra conjuncts may be appended in future versions without altering the   *)
(* surrounding state machine.                                                                *)
(*********************************************************************************************)
AcceptanceCriterion(S) ==
  /\ LUALATEX_CORE \subseteq S
  /\ S \subseteq LUALATEX              


(*********************************************************************************************)
(* State machine.                                                                            *)
(*                                                                                           *)
(*   init  --Validate-->  accepted | rejected  --Done-->  (stutters)                         *)
(*                                                                                           *)
(* Note: Validate has InitPreferences as a precondition, so it can fire at most once.        *)
(* After Validate, state /= "init". Hence InitPreferences = FALSE and Validate disabled.     *)
(*********************************************************************************************)


InitPreferences ==
  /\ state = "init"
  /\ preferences_keys = {}

(* Decision: IF baseline holds THEN accept ELSE reject. *)
Validate ==
  /\ InitPreferences
  /\ \E p \in SUBSET KEYS : preferences_keys' = p
  /\ state' = IF AcceptanceCriterion(preferences_keys') THEN "accepted" ELSE "rejected"

(* Terminal stutter, so TLC sees no deadlock at the accept/reject states. *)
Done ==
  /\ state \in { "accepted", "rejected" }
  /\ UNCHANGED vars

NextPreferences == Validate \/ Done

Spec == InitPreferences /\ [][NextPreferences]_vars

(*********************************************************************************************)
(* Acceptance contract.                                                                      *)
(*                                                                                           *)
(*   Acceptance         : accepted => criterion holds.                                       *)
(*   AcceptanceConverse : not-accepted => criterion does not hold.                           *)
(*                                                                                           *)
(* Together they yield, at terminal states, the bi-implication:                              *)
(*   state = "accepted"  <=>  criterion(preferences_keys).                                   *)
(*********************************************************************************************)
Acceptance         == (state = "accepted")  => AcceptanceCriterion(preferences_keys)
AcceptanceConverse == (state /= "accepted") => ~AcceptanceCriterion(preferences_keys)

(*********************************************************************************************)
(* Theorems (TLAPS).                                                                         *)
(*                                                                                           *)
(* All proofs follow the canonical inductive-invariant pattern:                              *)
(*   InitPreferences => Inv,   Inv /\ [NextPreferences]_vars => Inv',   conclude by PTL.     *)
(*********************************************************************************************)

THEOREM TypeCorrect == Spec => []TypeOK
  <1> USE DEF TypeOK, States, vars
  <1>1. InitPreferences => TypeOK
    <2> QED BY DEF InitPreferences
  <1>2. TypeOK /\ [NextPreferences]_vars => TypeOK'
    <2>1. CASE Validate
      <3> QED BY DEF Validate
    <2>2. CASE Done
      <3> QED BY DEF Done
    <2> QED
      BY <2>1, <2>2 DEF NextPreferences
  <1> QED BY <1>1, <1>2, PTL DEF Spec

THEOREM isAcceptance == Spec => []Acceptance
  <1> USE DEF InitPreferences, Acceptance, AcceptanceCriterion, vars
  <1>1. InitPreferences => Acceptance OBVIOUS
  <1>2. Acceptance /\ [NextPreferences]_vars => Acceptance'
    <2>1. CASE Validate
      <3>   QED BY <2>1 DEF Validate
    <2>2. CASE Done
      <3>   QED BY <2>2 DEF Done
    <2> QED BY <2>1, <2>2 DEF NextPreferences
  <1> QED BY <1>1, <1>2, PTL DEF Spec

THEOREM isAcceptanceConverse == Spec => []AcceptanceConverse
  <1> USE DEF  InitPreferences, AcceptanceConverse, AcceptanceCriterion, vars
  <1>1. InitPreferences => AcceptanceConverse 
    <2>   QED BY LualatexShape 
  <1>2. AcceptanceConverse /\ [NextPreferences]_vars => AcceptanceConverse'
    <2>1. CASE Validate
      <3>   QED BY <2>1 DEF Validate
    <2>2. CASE Done
      <3>   QED BY <2>2 DEF Done
    <2> QED BY <2>1, <2>2 DEF NextPreferences
  <1> QED BY <1>1, <1>2, PTL DEF Spec

===============================================================================================
