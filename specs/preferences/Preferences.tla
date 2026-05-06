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
(*   The two MUST constraints from nextStep.2.0.0.md are *baseline* (general) criteria. The  *)
(*   Validate action uses IF/THEN/ELSE -- not iff -- so the shape of the spec admits future  *)
(*   criteria to be conjoined into the criterion predicate without disturbing the            *)
(*   surrounding state machine.                                                              *)
(**********************************************************************************************)

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
  state,                 (* "init" | "accepted" | "rejected"                                 *)
  user_preferences_keys  (* Key set of the parsed user_preference_.                          *)

vars == << state, user_preferences_keys >>

States == { "init", "accepted", "rejected" }

(*********************************************************************************************)
(* Type invariant.                                                                            *)
(*********************************************************************************************)
TypeOK ==
  /\ state \in States
  /\ user_preferences_keys \subseteq KEYS

(*********************************************************************************************)
(* Baseline acceptance criterion. The two MUST constraints, parametric in LUALATEX and       *)
(* LUALATEX_CORE.                                                                            *)
(*                                                                                           *)
(* Open by design: extra conjuncts may be appended in future versions without altering the   *)
(* surrounding state machine.                                                                *)
(*********************************************************************************************)
criterion(S) ==
  /\ S \subseteq LUALATEX                          (* C1                                     *)
  /\ LUALATEX_CORE \subseteq S                     (* C2                                     *)

(*********************************************************************************************)
(* State machine.                                                                            *)
(*                                                                                           *)
(*   init  --Validate-->  accepted | rejected  --Done-->  (stutters)                         *)
(*                                                                                           *)
(* Note: Validate has Init as a precondition, so it can fire at most once. After Validate,   *)
(* state /= "init", so Init is false and Validate disabled.                                  *)
(*********************************************************************************************)

Init ==
  /\ state = "init"
  /\ user_preferences_keys = {}

(* Decision: IF baseline holds THEN accept ELSE reject. *)
Validate ==
  /\ Init
  /\ \E p \in SUBSET KEYS : user_preferences_keys' = p
  /\ state' = IF criterion(user_preferences_keys') THEN "accepted" ELSE "rejected"

(* Terminal stutter, so TLC sees no deadlock at the accept/reject states. *)
Done ==
  /\ state \in { "accepted", "rejected" }
  /\ UNCHANGED vars

Next == Validate \/ Done

Spec == Init /\ [][Next]_vars

(*********************************************************************************************)
(* Acceptance contract.                                                                      *)
(*                                                                                           *)
(*   Acceptance         : accepted => criterion holds.                                       *)
(*   AcceptanceConverse : not-accepted => criterion does not hold.                           *)
(*                                                                                           *)
(* Together they yield, at terminal states, the bi-implication:                              *)
(*   state = "accepted"  <=>  criterion(user_preferences_keys).                              *)
(*********************************************************************************************)
Acceptance         == (state = "accepted")  => criterion(user_preferences_keys)
AcceptanceConverse == (state /= "accepted") => ~criterion(user_preferences_keys)

(*********************************************************************************************)
(* Theorems (TLAPS).                                                                         *)
(*                                                                                           *)
(* All proofs follow the canonical inductive-invariant pattern:                              *)
(*   Init => Inv,   Inv /\ [Next]_vars => Inv',   conclude by PTL.                           *)
(*********************************************************************************************)

THEOREM TypeCorrect == Spec => []TypeOK
  <1>1. Init => TypeOK
    BY DEF Init, TypeOK, States
  <1>2. TypeOK /\ [Next]_vars => TypeOK'
    <2>1. TypeOK /\ Validate => TypeOK'
      BY DEF Validate, TypeOK, States
    <2>2. TypeOK /\ Done => TypeOK'
      BY DEF Done, TypeOK, vars
    <2>3. TypeOK /\ UNCHANGED vars => TypeOK'
      BY DEF TypeOK, vars
    <2> QED
      BY <2>1, <2>2, <2>3 DEF Next
  <1> QED
    BY <1>1, <1>2, PTL DEF Spec

THEOREM isAcceptance == Spec => []Acceptance
  (* Init *)
  <1>1. Init => Acceptance
    BY DEF Init, Acceptance
  (* Next *)
  <1>2. Acceptance /\ [Next]_vars => Acceptance'
    <2>1. Acceptance /\ Validate => Acceptance'
      BY DEF Validate, Acceptance, criterion
    <2>2. Acceptance /\ Done => Acceptance'
      BY DEF Done, Acceptance, vars
    <2>3. Acceptance /\ UNCHANGED vars => Acceptance'
      BY DEF Acceptance, vars
    <2> QED
      BY <2>1, <2>2, <2>3 DEF Next
  <1> QED
    BY <1>1, <1>2, PTL DEF Spec

THEOREM isAcceptanceConverse == Spec => []AcceptanceConverse
  (* Init *)
  <1>1. Init => AcceptanceConverse 
    BY LualatexShape DEF Init, AcceptanceConverse, criterion
  (* Next *)
  <1>2. AcceptanceConverse /\ [Next]_vars => AcceptanceConverse'
    <2>1. AcceptanceConverse /\ Validate => AcceptanceConverse' 
      BY DEF AcceptanceConverse, Validate
    <2>2. AcceptanceConverse /\ Done => AcceptanceConverse'
      BY DEF AcceptanceConverse, Done, vars
    <2>3. AcceptanceConverse /\ UNCHANGED vars => AcceptanceConverse'
      BY DEF AcceptanceConverse, vars
    <2> QED
      BY <2>1, <2>2, <2>3 DEF Next
  <1> QED
    BY <1>1, <1>2, PTL DEF Spec

===============================================================================================
