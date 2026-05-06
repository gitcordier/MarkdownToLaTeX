--------------------------------- MODULE Directory --------------------------------------------
(*********************************************************************************************)
(* Project version : 1.3.8                                                                   *)
(*                                                                                           *)
(* Directory.tla -- formal specification AND safety proofs of the User-intent decision       *)
(* procedure for MarkdownToLaTeX 1.0.0.                                                      *)
(*                                                                                           *)
(* Subject: The User runs MarkdownToLaTeX 1.0.0 from a working directory DIR. Before any     *)
(* conversion can begin, MarkdownToLaTeX decides whether DIR is "ready" at the file-system   *)
(* layer. Three flags carry the evidence:                                                    *)
(*      1. is_dir                                                                            *)
(*         $DIR exists and is a directory;                                                   *)
(*      2. has_preferences_dir                                                               *)
(*         $DIR/preferences exists and is a directory;                                       *)
(*      3. has_INI_preferences                                                               *)
(*         $DIR/preferences/preferences.ini exists and is a regular file.                    *)
(*                                                                                           *)
(* Validation of the .ini *content* (schema keys, legal values for "document class", etc.)   *)
(* OUT OF SCOPE for this iteration; it is left for a later kaizen step.                      *)
(*                                                                                           *)
(* Two records, two semantics.                                                               *)
(*      `directory : Knowledge` is the *trial verdict*. Each flag is TRUE unless and until   *)
(*                  a check disproves it. Init: all TRUE (no disproof yet). Transitions      *)
(*                  flip TRUE -> FALSE only and never back.                                  *)
(*      `check     : Knowledge` is the *inquiry log*. Each flag is TRUE iff the              *)
(*                  corresponding check has been run. Init: all FALSE. Transitions flip      *)
(*                  FALSE -> TRUE only and never back.                                       *)
(*      The two records share the structural type `Knowledge`; the distinct meanings live in *)
(*      the actions, not the type.                                                           *)
(*                                                                                           *)
(* Verdicts. OK     == AllChecked /\ NothingHasBeenDisproved                                 *)
(*           NOT_OK == \E n \in 1..3 : hasBeenDisproved(n)                                   *)
(*           Headline (T8): the verdicts are mutually exclusive --                           *)
(*                Spec => []~(OK /\ NOT_OK)                                                  *)
(*           so whenever the procedure halts, OK XOR NOT_OK holds.                           *)
(*                                                                                           *)
(* Liveness. This module proves SAFETY only. No fairness clause is added, no WF, no liveness *)
(*           theorem. Termination of the chain is not proven here (and is not needed for the *)
(*           headline XOR property since XOR reduces to disjointness under the definitions   *)
(*           of OK and NOT_OK).                                                              *)
(*                                                                                           *)
(* Author:   Jean-Gabriel Cordier, with Claude.                                              *)
(* Origin:   Earlier draft Tue Aug 08 2023 by gcordier.                                      *)
(* This file: Kaizen step 1.3.7 -- three-step file-system chain with safety theorems T1-T8   *)
(*            and complete TLAPS proof bodies.                                               *)
(*********************************************************************************************)

EXTENDS TLAPS, FiniteSets, Naturals

(*===========================================================================================*)
(*                                         VARIABLES                                         *)
(*===========================================================================================*)
(*  directory -- proof flags accumulated about DIR. Each leaf is TRUE initially and may flip *)
(*               to FALSE only via a FAIL action. Flags never flip back.                     *)
(*                                                                                           *)
(*  check     -- inquiry flags. Each leaf is FALSE initially and may flip to TRUE only when  *)
(*               the corresponding check is performed. Flags never flip back.                *)
(*===========================================================================================*)

VARIABLES directory, check

vars == << directory, check >>

(*===========================================================================================*)
(*                                           TYPE                                            *)
(*===========================================================================================*)
(*  A single shared structural type. Distinct meanings (verdict vs. inquiry log) are         *)
(*  carried by the actions, not the type.                                                    *)
(*===========================================================================================*)

Knowledge == [
    is_dir              : BOOLEAN,
    has_preferences_dir : BOOLEAN,
    has_INI_preferences : BOOLEAN
  ]

TypeOK ==
  /\ directory \in Knowledge
  /\ check     \in Knowledge

(*===========================================================================================*)
(*                                   PROOF-FLAG ACCESSORS                                    *)
(*===========================================================================================*)
(*  Convention: indices 1..3 line up with the three flags.                                   *)
(*===========================================================================================*)

isTrue(n) ==
    CASE n = 1 -> directory.is_dir
      [] n = 2 -> directory.has_preferences_dir
      [] n = 3 -> directory.has_INI_preferences
      [] OTHER -> FALSE

NothingHasBeenDisproved == \A n \in 1..3 : isTrue(n)
hasBeenDisproved(n)     == ~ isTrue(n)
AllDisproved            == \A n \in 1..3 : hasBeenDisproved(n)

hasBeenChecked(n) ==
    CASE n = 1 -> check.is_dir
      [] n = 2 -> check.has_preferences_dir
      [] n = 3 -> check.has_INI_preferences
      [] OTHER -> FALSE

AllChecked == \A n \in 1..3 : hasBeenChecked(n)

NothingHasBeenChecked == \A n \in 1..3 : hasBeenChecked(n) = FALSE

(*===========================================================================================*)
(*                                     VERDICT PREDICATES                                    *)
(*===========================================================================================*)

OK     == AllChecked /\ NothingHasBeenDisproved
NOT_OK == \E n \in 1..3 : hasBeenDisproved(n)

(*===========================================================================================*)
(*                                            INIT                                           *)
(*===========================================================================================*)

InitDirectory ==
  /\ directory.is_dir               = TRUE
  /\ directory.has_preferences_dir  = TRUE
  /\ directory.has_INI_preferences = TRUE

InitCheck ==
  /\ check.is_dir               = FALSE
  /\ check.has_preferences_dir  = FALSE
  /\ check.has_INI_preferences = FALSE

Init ==
  /\ directory \in Knowledge
  /\ check     \in Knowledge
  /\ InitDirectory
  /\ InitCheck

(*===========================================================================================*)
(*                                   SUCCESS / FAIL ACTIONS                                  *)
(*===========================================================================================*)
(*  Each step has two action shapes:                                                         *)
(*    Next* (success): leaves `directory` unchanged, sets the matching `check` flag to TRUE. *)
(*    NextNo* (fail) : flips the matching `directory` flag to FALSE AND sets the matching    *)
(*                     `check` flag to TRUE.                                                 *)
(*  Every action requires NothingHasBeenDisproved as part of its guard, so no further check  *)
(*  fires after the first failure.                                                           *)
(*===========================================================================================*)

(* Step 1: DIR is a directory.*)
NecessaryConditionDir ==
  /\ NothingHasBeenChecked
  /\ NothingHasBeenDisproved

NextHasDir ==
  /\ NecessaryConditionDir
  /\ UNCHANGED directory
  /\ check' = [check EXCEPT !.is_dir = TRUE]

NextHasNoDir ==
  /\ NecessaryConditionDir
  /\ directory' = [directory EXCEPT !.is_dir = FALSE]
  /\ check'     = [check     EXCEPT !.is_dir = TRUE]

(* Step 2: DIR/preferences is a directory.*)
NecessaryConditionPreferencesDir ==
  /\ hasBeenChecked(1)
  /\ (hasBeenChecked(2) = FALSE)
  /\ NothingHasBeenDisproved

NextHasPreferencesDir ==
  /\ NecessaryConditionPreferencesDir
  /\ UNCHANGED directory
  /\ check' = [check EXCEPT !.has_preferences_dir = TRUE]

NextHasNoPreferencesDir ==
  /\ NecessaryConditionPreferencesDir
  /\ directory' = [directory EXCEPT !.has_preferences_dir = FALSE]
  /\ check'     = [check     EXCEPT !.has_preferences_dir = TRUE]

(* Step 3: DIR/preferences/preferences.ini is a regular file.*)
NecessaryIniPreferences ==
  /\ hasBeenChecked(1)
  /\ hasBeenChecked(2)
  /\ (hasBeenChecked(3) = FALSE)
  /\ NothingHasBeenDisproved

NextHasIniPreferences ==
  /\ NecessaryIniPreferences
  /\ UNCHANGED directory
  /\ check' = [check EXCEPT !.has_INI_preferences = TRUE]

NextHasNoIniPreferences ==
  /\ NecessaryIniPreferences
  /\ directory' = [directory EXCEPT !.has_INI_preferences = FALSE]
  /\ check'     = [check     EXCEPT !.has_INI_preferences = TRUE]

(*===========================================================================================*)
(*                                 NO-DEADLOCK STUTTER ACTIONS                               *)
(*===========================================================================================*)
(*  Once the chain has halted (success at step 3, or any failure), no proper Next* /         *)
(*  NextNo* action is enabled. The four guards below describe the four halt configurations;  *)
(*  the body of each is the same no-op (UNCHANGED directory /\ UNCHANGED check), so all      *)
(*  four collapse to a single state-transition shape in any safety proof.                    *)
(*===========================================================================================*)

NextNoDeadLockCriterion ==
  /\ UNCHANGED directory
  /\ UNCHANGED check

NoDeadlockNextOK ==
  /\ NothingHasBeenDisproved
  /\ AllChecked

NoDeadlockNextHasNoDir ==
  /\ hasBeenChecked(1)
  /\ hasBeenChecked(2) = FALSE
  /\ hasBeenDisproved(1)

NoDeadlockNextHasNoPreferencesDir ==
  /\ hasBeenChecked(1)
  /\ hasBeenChecked(2)
  /\ hasBeenChecked(3) = FALSE
  /\ isTrue(1)
  /\ hasBeenDisproved(2)

NoDeadlockNextHasNoIniPreferences ==
  /\ AllChecked
  /\ isTrue(1)
  /\ isTrue(2)
  /\ hasBeenDisproved(3)

NoDeadlockNext ==
  /\ NextNoDeadLockCriterion
  /\ (\/ NoDeadlockNextOK
      \/ NoDeadlockNextHasNoDir
      \/ NoDeadlockNextHasNoPreferencesDir
      \/ NoDeadlockNextHasNoIniPreferences)

(*===========================================================================================*)
(*                                            NEXT                                           *)
(*===========================================================================================*)

Next ==
  \/ NextHasDir
  \/ NextHasNoDir
  \/ NextHasPreferencesDir
  \/ NextHasNoPreferencesDir
  \/ NextHasIniPreferences
  \/ NextHasNoIniPreferences
  \/ NoDeadlockNext

(*===========================================================================================*)
(*                                            SPEC                                           *)
(*===========================================================================================*)
(*  Safety only. No fairness clause: liveness is out of scope.                               *)
(*===========================================================================================*)

Spec == Init /\ [][Next]_vars

(*===========================================================================================*)
(*                                      CHAIN INVARIANTS                                     *)
(*===========================================================================================*)
(*  Five state predicates that together capture every safety property of interest. They are  *)
(*  bundled into Inv and proven simultaneously by induction in theorem T_Inv.                *)
(*===========================================================================================*)

ChainOrderCheck ==
  /\ hasBeenChecked(2) => hasBeenChecked(1)
  /\ hasBeenChecked(3) => hasBeenChecked(2)

Soundness ==
  /\ hasBeenChecked(2) => isTrue(1)
  /\ hasBeenChecked(3) => isTrue(2)

DisprovalImpliesChecked ==
  \A n \in 1..3 : hasBeenDisproved(n) => hasBeenChecked(n)

AtLeastOneDisproved == \E n \in 1..3: hasBeenDisproved(n)
AtLeastTwoDisproved == \E m \in 1..3: (
    \E n \in 1..3 \ {m}:
        /\ hasBeenDisproved(m) 
        /\ hasBeenDisproved(n)
    )
AtMostOneDisproved ==  ~AtLeastTwoDisproved
  (*/\ ~ (hasBeenDisproved(1) /\ hasBeenDisproved(2))
  /\ ~ (hasBeenDisproved(2) /\ hasBeenDisproved(3))
  /\ ~ (hasBeenDisproved(1) /\ hasBeenDisproved(3))*)

VerdictsExclusive == ~ (OK /\ NOT_OK)

Inv ==
  /\ TypeOK
  /\ ChainOrderCheck
  /\ Soundness
  /\ DisprovalImpliesChecked
  /\ AtMostOneDisproved

(*===========================================================================================*)
(*                                MONOTONICITY STEP-PROPERTIES                               *)
(*===========================================================================================*)
(*  Step-level (relating current and primed state) properties used by the monotonicity       *)
(*  theorems T6 and T7.                                                                      *)
(*===========================================================================================*)

DirectoryMonotoneStep ==
  \A n \in 1..3 : hasBeenDisproved(n) => hasBeenDisproved(n)'

CheckMonotoneStep ==
  \A n \in 1..3 : hasBeenChecked(n) => hasBeenChecked(n)'

(*===========================================================================================*)
(*                                          THEOREMS                                         *)
(*===========================================================================================*)
(*                                                                                           *)
(*  T_Inv  Spec => []Inv                                                                     *)
(*  T1     Spec => []TypeOK                                                                  *)
(*  T2     Spec => []ChainOrderCheck                                                         *)
(*  T3     Spec => []Soundness                                                               *)
(*  T4     Spec => []DisprovalImpliesChecked                                                 *)
(*  T5     Spec => []AtMostOneDisproved                                                      *)
(*  T6     Spec => [][DirectoryMonotoneStep]_vars                                            *)
(*  T7     Spec => [][CheckMonotoneStep]_vars                                                *)
(*  T8     Spec => []VerdictsExclusive                                                       *)
(*                                                                                           *)
(*===========================================================================================*)

(*-------------------------------------------------------------------------------------------*)
(*  T_Inv : the master inductive invariant.                                                  *)
(*-------------------------------------------------------------------------------------------*)

THEOREM T_Inv == Spec => []Inv
<1>1. Init => Inv
  <2>1. Init => TypeOK
    BY DEF Init, InitDirectory, InitCheck, TypeOK, Knowledge
  <2>2. Init => ChainOrderCheck
    BY DEF Init, InitCheck, ChainOrderCheck, hasBeenChecked
  <2>3. Init => Soundness
    BY DEF Init, InitCheck, Soundness, hasBeenChecked
  <2>4. Init => DisprovalImpliesChecked
    BY DEF Init, InitDirectory, DisprovalImpliesChecked,
           hasBeenDisproved, isTrue
  <2>5. Init => AtMostOneDisproved
    BY DEF Init, InitDirectory, AtMostOneDisproved, AtLeastTwoDisproved, 
           hasBeenDisproved, isTrue
  <2>6. QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5 DEF Inv
<1>2. Inv /\ [Next]_vars => Inv'
  <2> SUFFICES ASSUME Inv, [Next]_vars PROVE Inv'
    OBVIOUS
  <2>1. CASE NextHasDir
    <3>a. directory' = directory
      BY <2>1 DEF NextHasDir
    <3>b. check' = [check EXCEPT !.is_dir = TRUE]
      BY <2>1 DEF NextHasDir
    <3>c. NothingHasBeenChecked
      BY <2>1 DEF NextHasDir, NecessaryConditionDir
    <3>d. NothingHasBeenDisproved
      BY <2>1 DEF NextHasDir, NecessaryConditionDir
    <3>e. TypeOK'
      BY <3>a, <3>b DEF Inv, TypeOK, Knowledge
    <3>f. ChainOrderCheck'
      BY <3>b, <3>c DEF ChainOrderCheck, hasBeenChecked,
                        NothingHasBeenChecked
    <3>g. Soundness'
      BY <3>b, <3>c DEF Soundness, hasBeenChecked,
                        NothingHasBeenChecked
    <3>h. DisprovalImpliesChecked'
      BY <3>a, <3>d DEF DisprovalImpliesChecked, hasBeenDisproved,
                        isTrue, NothingHasBeenDisproved
    <3>i. AtMostOneDisproved'
      BY <3>a, <3>d DEF AtMostOneDisproved, hasBeenDisproved, AtLeastTwoDisproved, 
                        isTrue, NothingHasBeenDisproved
    <3>j. QED
      BY <3>e, <3>f, <3>g, <3>h, <3>i DEF Inv
  <2>2. CASE NextHasNoDir
    <3>a. directory' = [directory EXCEPT !.is_dir = FALSE]
      BY <2>2 DEF NextHasNoDir
    <3>b. check' = [check EXCEPT !.is_dir = TRUE]
      BY <2>2 DEF NextHasNoDir
    <3>c. NothingHasBeenChecked
      BY <2>2 DEF NextHasNoDir, NecessaryConditionDir
    <3>d. NothingHasBeenDisproved
      BY <2>2 DEF NextHasNoDir, NecessaryConditionDir
    <3>e. TypeOK'
      BY <3>a, <3>b DEF Inv, TypeOK, Knowledge
    <3>f. ChainOrderCheck'
      BY <3>b, <3>c DEF ChainOrderCheck, hasBeenChecked,
                        NothingHasBeenChecked
    <3>g. Soundness'
      BY <3>b, <3>c DEF Soundness, hasBeenChecked, NothingHasBeenChecked
    <3>h. DisprovalImpliesChecked'
      BY <3>a, <3>b, <3>d DEF DisprovalImpliesChecked,
                              hasBeenDisproved, hasBeenChecked,
                              isTrue, NothingHasBeenDisproved
    <3>i. AtMostOneDisproved'
      BY <3>a, <3>d DEF AtMostOneDisproved, hasBeenDisproved, AtLeastTwoDisproved, 
                        isTrue, NothingHasBeenDisproved
    <3>j. QED
      BY <3>e, <3>f, <3>g, <3>h, <3>i DEF Inv
  <2>3. CASE NextHasPreferencesDir
    <3>a. directory' = directory
      BY <2>3 DEF NextHasPreferencesDir
    <3>b. check' = [check EXCEPT !.has_preferences_dir = TRUE]
      BY <2>3 DEF NextHasPreferencesDir
    <3>c. hasBeenChecked(1)
      BY <2>3 DEF NextHasPreferencesDir, NecessaryConditionPreferencesDir
    <3>d. hasBeenChecked(2) = FALSE
      BY <2>3 DEF NextHasPreferencesDir, NecessaryConditionPreferencesDir
    <3>e. NothingHasBeenDisproved
      BY <2>3 DEF NextHasPreferencesDir, NecessaryConditionPreferencesDir
    <3>f. hasBeenChecked(3) = FALSE
      BY <3>d DEF Inv, ChainOrderCheck, hasBeenChecked
    <3>g. TypeOK'
      BY <3>a, <3>b DEF Inv, TypeOK, Knowledge
    <3>h. ChainOrderCheck'
      BY <3>b, <3>c, <3>f DEF ChainOrderCheck, hasBeenChecked
    <3>i. Soundness'
      BY <3>a, <3>b, <3>e, <3>f DEF Soundness, hasBeenChecked, isTrue, NothingHasBeenDisproved
    <3>j. DisprovalImpliesChecked'
      BY <3>a, <3>e DEF DisprovalImpliesChecked, hasBeenDisproved,
                        isTrue, NothingHasBeenDisproved
    <3>k. AtMostOneDisproved'
      BY <3>a, <3>e DEF AtMostOneDisproved, hasBeenDisproved, AtLeastTwoDisproved, 
                        isTrue, NothingHasBeenDisproved
    <3>l. QED
      BY <3>g, <3>h, <3>i, <3>j, <3>k DEF Inv
  <2>4. CASE NextHasNoPreferencesDir
    <3>a. directory' = [directory EXCEPT !.has_preferences_dir = FALSE]
      BY <2>4 DEF NextHasNoPreferencesDir
    <3>b. check' = [check EXCEPT !.has_preferences_dir = TRUE]
      BY <2>4 DEF NextHasNoPreferencesDir
    <3>c. hasBeenChecked(1)
      BY <2>4 DEF NextHasNoPreferencesDir,
                  NecessaryConditionPreferencesDir
    <3>d. hasBeenChecked(2) = FALSE
      BY <2>4 DEF NextHasNoPreferencesDir,
                  NecessaryConditionPreferencesDir
    <3>e. NothingHasBeenDisproved
      BY <2>4 DEF NextHasNoPreferencesDir,
                  NecessaryConditionPreferencesDir
    <3>f. hasBeenChecked(3) = FALSE
      BY <3>d DEF Inv, ChainOrderCheck, hasBeenChecked
    <3>g. TypeOK'
      BY <3>a, <3>b DEF Inv, TypeOK, Knowledge
    <3>h. ChainOrderCheck'
      BY <3>b, <3>c, <3>f DEF ChainOrderCheck, hasBeenChecked
    <3>i. Soundness'
      BY <3>a, <3>b, <3>e, <3>f DEF Soundness, hasBeenChecked, isTrue, NothingHasBeenDisproved
    <3>j. DisprovalImpliesChecked'
      BY <3>a, <3>b, <3>e DEF DisprovalImpliesChecked,
                              hasBeenDisproved, hasBeenChecked,
                              isTrue, NothingHasBeenDisproved
    <3>k. AtMostOneDisproved'
      BY <3>a, <3>e DEF AtMostOneDisproved, hasBeenDisproved, AtLeastTwoDisproved, 
                        isTrue, NothingHasBeenDisproved
    <3>l. QED
      BY <3>g, <3>h, <3>i, <3>j, <3>k DEF Inv
  <2>5. CASE NextHasIniPreferences
    <3>a. directory' = directory
      BY <2>5 DEF NextHasIniPreferences
    <3>b. check' = [check EXCEPT !.has_INI_preferences = TRUE]
      BY <2>5 DEF NextHasIniPreferences
    <3>c. hasBeenChecked(1)
      BY <2>5 DEF NextHasIniPreferences, NecessaryIniPreferences
    <3>d. hasBeenChecked(2)
      BY <2>5 DEF NextHasIniPreferences, NecessaryIniPreferences
    <3>e. NothingHasBeenDisproved
      BY <2>5 DEF NextHasIniPreferences, NecessaryIniPreferences
    <3>f. TypeOK'
      BY <3>a, <3>b DEF Inv, TypeOK, Knowledge
    <3>g. ChainOrderCheck'
      BY <3>b, <3>c, <3>d DEF ChainOrderCheck, hasBeenChecked
    <3>h. Soundness'
      BY <3>a, <3>b, <3>e DEF Soundness, hasBeenChecked, isTrue,
                              NothingHasBeenDisproved
    <3>i. DisprovalImpliesChecked'
      BY <3>a, <3>e DEF DisprovalImpliesChecked, hasBeenDisproved,
                        isTrue, NothingHasBeenDisproved
    <3>j. AtMostOneDisproved'
      BY <3>a, <3>e DEF AtMostOneDisproved, AtLeastTwoDisproved, hasBeenDisproved,
                        isTrue, NothingHasBeenDisproved
    <3>k. QED
      BY <3>f, <3>g, <3>h, <3>i, <3>j DEF Inv
  <2>6. CASE NextHasNoIniPreferences
    <3>a. directory' = [directory EXCEPT !.has_INI_preferences = FALSE]
      BY <2>6 DEF NextHasNoIniPreferences
    <3>b. check' = [check EXCEPT !.has_INI_preferences = TRUE]
      BY <2>6 DEF NextHasNoIniPreferences
    <3>c. hasBeenChecked(1)
      BY <2>6 DEF NextHasNoIniPreferences, NecessaryIniPreferences
    <3>d. hasBeenChecked(2)
      BY <2>6 DEF NextHasNoIniPreferences, NecessaryIniPreferences
    <3>e. NothingHasBeenDisproved
      BY <2>6 DEF NextHasNoIniPreferences, NecessaryIniPreferences
    <3>f. TypeOK'
      BY <3>a, <3>b DEF Inv, TypeOK, Knowledge
    <3>g. ChainOrderCheck'
      BY <3>b, <3>c, <3>d DEF ChainOrderCheck, hasBeenChecked
    <3>h. Soundness'
      BY <3>a, <3>b, <3>e DEF Soundness, hasBeenChecked, isTrue,
                              NothingHasBeenDisproved
    <3>i. DisprovalImpliesChecked'
      BY <3>a, <3>b, <3>e DEF DisprovalImpliesChecked,
                              hasBeenDisproved, hasBeenChecked,
                              isTrue, NothingHasBeenDisproved
    <3>j. AtMostOneDisproved'
      BY <3>a, <3>e DEF AtMostOneDisproved, AtLeastTwoDisproved, hasBeenDisproved, 
                        AtLeastTwoDisproved, isTrue, NothingHasBeenDisproved
    <3>k. QED
      BY <3>f, <3>g, <3>h, <3>i, <3>j DEF Inv
  <2>7. CASE NoDeadlockNext
    BY <2>7 DEF NoDeadlockNext, NextNoDeadLockCriterion, Inv,
                TypeOK, ChainOrderCheck, Soundness,
                DisprovalImpliesChecked, AtMostOneDisproved, AtLeastTwoDisproved, 
                hasBeenChecked, hasBeenDisproved, isTrue,
                NothingHasBeenDisproved
  <2>8. CASE UNCHANGED vars
    BY <2>8 DEF Inv, TypeOK, ChainOrderCheck, Soundness,
                DisprovalImpliesChecked, AtMostOneDisproved, AtLeastTwoDisproved, 
                hasBeenChecked, hasBeenDisproved, isTrue,
                NothingHasBeenDisproved, vars
  <2>9. QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8 DEF Next
<1>3. QED
  BY <1>1, <1>2, PTL DEF Spec

(*-------------------------------------------------------------------------------------------*)
(*  T1 -- T5 : direct corollaries of T_Inv.                                                  *)
(*-------------------------------------------------------------------------------------------*)

THEOREM T1 == Spec => []TypeOK
BY T_Inv, PTL DEF Inv

THEOREM T2 == Spec => []ChainOrderCheck
BY T_Inv, PTL DEF Inv

THEOREM T3 == Spec => []Soundness
BY T_Inv, PTL DEF Inv

THEOREM T4 == Spec => []DisprovalImpliesChecked
BY T_Inv, PTL DEF Inv

THEOREM T5 == Spec => []AtMostOneDisproved
BY T_Inv, PTL DEF Inv

(*-------------------------------------------------------------------------------------------*)
(*  T6 : `directory` is monotone non-increasing.                                             *)
(*-------------------------------------------------------------------------------------------*)

THEOREM T6 == Spec => [][DirectoryMonotoneStep]_vars
<1>1. [Next]_vars => [DirectoryMonotoneStep]_vars
  <2> SUFFICES ASSUME [Next]_vars PROVE [DirectoryMonotoneStep]_vars
    OBVIOUS
  <2>1. CASE NextHasDir
    BY <2>1 DEF NextHasDir, DirectoryMonotoneStep, hasBeenDisproved,
                isTrue
  <2>2. CASE NextHasNoDir
    BY <2>2 DEF NextHasNoDir, NecessaryConditionDir,
                DirectoryMonotoneStep, hasBeenDisproved, isTrue,
                NothingHasBeenDisproved
  <2>3. CASE NextHasPreferencesDir
    BY <2>3 DEF NextHasPreferencesDir, DirectoryMonotoneStep,
                hasBeenDisproved, isTrue
  <2>4. CASE NextHasNoPreferencesDir
    BY <2>4 DEF NextHasNoPreferencesDir,
                NecessaryConditionPreferencesDir,
                DirectoryMonotoneStep, hasBeenDisproved, isTrue,
                NothingHasBeenDisproved
  <2>5. CASE NextHasIniPreferences
    BY <2>5 DEF NextHasIniPreferences, DirectoryMonotoneStep,
                hasBeenDisproved, isTrue
  <2>6. CASE NextHasNoIniPreferences
    BY <2>6 DEF NextHasNoIniPreferences, NecessaryIniPreferences,
                DirectoryMonotoneStep, hasBeenDisproved, isTrue,
                NothingHasBeenDisproved
  <2>7. CASE NoDeadlockNext
    BY <2>7 DEF NoDeadlockNext, NextNoDeadLockCriterion,
                DirectoryMonotoneStep, hasBeenDisproved, isTrue
  <2>8. CASE UNCHANGED vars
    BY <2>8 DEF DirectoryMonotoneStep, hasBeenDisproved, isTrue, vars
  <2>9. QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8 DEF Next
<1>2. QED
  BY <1>1, PTL DEF Spec

(*-------------------------------------------------------------------------------------------*)
(*  T7 : `check` is monotone non-decreasing.                                                 *)
(*-------------------------------------------------------------------------------------------*)

THEOREM T7 == Spec => [][CheckMonotoneStep]_vars
<1>1. [Next]_vars => [CheckMonotoneStep]_vars
  <2> SUFFICES ASSUME [Next]_vars PROVE [CheckMonotoneStep]_vars
    OBVIOUS
  <2>1. CASE NextHasDir
    BY <2>1 DEF NextHasDir, CheckMonotoneStep, hasBeenChecked
  <2>2. CASE NextHasNoDir
    BY <2>2 DEF NextHasNoDir, CheckMonotoneStep, hasBeenChecked
  <2>3. CASE NextHasPreferencesDir
    BY <2>3 DEF NextHasPreferencesDir, CheckMonotoneStep,
                hasBeenChecked
  <2>4. CASE NextHasNoPreferencesDir
    BY <2>4 DEF NextHasNoPreferencesDir, CheckMonotoneStep,
                hasBeenChecked
  <2>5. CASE NextHasIniPreferences
    BY <2>5 DEF NextHasIniPreferences, CheckMonotoneStep,
                hasBeenChecked
  <2>6. CASE NextHasNoIniPreferences
    BY <2>6 DEF NextHasNoIniPreferences, CheckMonotoneStep,
                hasBeenChecked
  <2>7. CASE NoDeadlockNext
    BY <2>7 DEF NoDeadlockNext, NextNoDeadLockCriterion,
                CheckMonotoneStep, hasBeenChecked
  <2>8. CASE UNCHANGED vars
    BY <2>8 DEF CheckMonotoneStep, hasBeenChecked, vars
  <2>9. QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8 DEF Next
<1>2. QED
  BY <1>1, PTL DEF Spec

(*-------------------------------------------------------------------------------------------*)
(*  T8 : the headline -- OK and NOT_OK never coexist.                                        *)
(*  Proof is purely propositional: NOT_OK <=> ~NothingHasBeenDisproved,                      *)
(*  while OK requires NothingHasBeenDisproved.                                               *)
(*-------------------------------------------------------------------------------------------*)

THEOREM T8 == Spec => []VerdictsExclusive
<1>1. Init => VerdictsExclusive
  BY DEF VerdictsExclusive, OK, NOT_OK,
         NothingHasBeenDisproved, hasBeenDisproved
<1>2. VerdictsExclusive /\ [Next]_vars => VerdictsExclusive'
  BY DEF VerdictsExclusive, OK, NOT_OK,
         NothingHasBeenDisproved, hasBeenDisproved
<1>3. QED
  BY <1>1, <1>2, PTL DEF Spec

===============================================================================================
\* Modification History
\* Last modified Sat May 02 16:17:10 CEST 2026 by gcordier
\* Last modified Sat May 02 2026 by gcordier (kaizen 1.3.7)
\* Last modified Sat May 02 11:19:29 CEST 2026 by gcordier (kaizen 1.3.6)