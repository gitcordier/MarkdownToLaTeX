----------------------------- MODULE Directory ------------------------------------------------
(**********************************************************************************************
  Directory.tla -- formal specification AND safety proofs of the User-
                   intent decision procedure for MarkdownToLaTeX 1.0.0.
  This file. Kaizen step 2.0.2 -- two-step file-system chain with
             lemmas TYPE, PATH, CONVERSEOF_PATH; theorems INV and
             OK_OR_NOT_OK; all with complete TLAPS proof bodies.
 *********************************************************************************************)

EXTENDS TLAPS, FiniteSets, Naturals

(*===========================================================================================*)
(*                                VARIABLES                                                  *)
(*===========================================================================================*)
(*                                                                                           *)
(*  directory -- knowledge record for the two DIR checks. Each field starts as               *)
(*               "is assumed false" and advances to "is proven true" or                      *)
(*               "is proven false" via a single action. Fields never regress.                *)
(*                                                                                           *)
(*===========================================================================================*)

VARIABLES directory

(*===========================================================================================*)
(*                                  TYPE                                                     *)
(*===========================================================================================*)

TruthValues == {
  "is assumed false", 
  "is proven false", 
  "is proven true"
}

Knowledge == [
  has_preferences_file: TruthValues,
  has_preferences_subdir: TruthValues
]

TypeOK == directory \in Knowledge

(*===========================================================================================*)
(*                          PROOF-FLAG ACCESSORS                                             *)
(*===========================================================================================*)

getValue(n) ==
  CASE n = 1 -> directory.has_preferences_file
    [] n = 2 -> directory.has_preferences_subdir
    [] OTHER -> "is assumed false"

isProved(n)       == 
  \/ /\ (n=1) 
     /\ directory.has_preferences_file = "is proven true"
  \/ /\ (n=2) 
     /\ directory.has_preferences_subdir = "is proven true"

isDisproved(n)    == getValue(n) = "is proven false"
isAssumedFalse(n) == getValue(n) = "is assumed false"

AllProved       == \A n \in {1, 2}: isProved(n)
AllDisproved    == \A n \in {1, 2}: isDisproved(n)
AllAssumedFalse == \A n \in {1, 2}: isAssumedFalse(n)
AllProvedOrDisproved == \A n \in {1, 2}: (isProved(n) \/ isDisproved(n))

(*===========================================================================================*)
(*                            VERDICT PREDICATES                                             *)
(*===========================================================================================*)

OK == 
  /\ TypeOK 
  /\ AllProved

NOT_OK == 
  /\ TypeOK 
  /\ \E n \in {1, 2}: (isDisproved(n) \/ isAssumedFalse(n))

(*===========================================================================================*)
(*                                  INIT                                                     *)
(*===========================================================================================*)

InitDirectory ==
  /\ directory \in Knowledge
  /\ directory = [ 
       has_preferences_file   |-> "is assumed false",
       has_preferences_subdir |-> "is assumed false"]

(*===========================================================================================*)
(*                          SUCCESS / FAIL ACTIONS                                           *)
(*===========================================================================================*)
(*  Each decision point has two action shapes:                                               *)
(*    Next*   (positive outcome): advances the relevant field(s) to "is proven true".        *)
(*    NextNo* (negative outcome): advances the relevant field  to "is proven false".         *)
(*  Guards are exact state-equality conditions; at most one proper action is enabled in any  *)
(*  reachable state.                                                                         *)
(*===========================================================================================*)

(* Step 1: Does preferences/preferences.ini exist as a file?  
           NextFile proves both fields true at once: a file at that path implies 
           the preferences/ directory exists, resolving the subdir check immediately.*)
NextFile ==
  /\ directory = [
       has_preferences_file   |-> "is assumed false", 
       has_preferences_subdir |-> "is assumed false"]
  /\ directory' = [
       has_preferences_file   |-> "is proven true", 
       has_preferences_subdir |-> "is proven true"]


NextNoFile ==
  /\ directory = [
       has_preferences_file   |-> "is assumed false", 
       has_preferences_subdir |-> "is assumed false"]
  /\ directory' = [directory EXCEPT !.has_preferences_file = "is proven false"]

(* Step 2: if no preferences file: is preferences/ is a directory ? *)
NextNoFileHasDir ==
  /\ directory = [
       has_preferences_file   |-> "is proven false", 
       has_preferences_subdir |-> "is assumed false"]
  /\ directory' = [directory EXCEPT !.has_preferences_subdir = "is proven true"]

NextNoFileNoDir == 
  /\ directory = [
       has_preferences_file   |-> "is proven false", 
       has_preferences_subdir |-> "is assumed false"]
  /\ directory' = [directory EXCEPT !.has_preferences_subdir = "is proven false"]


(*===========================================================================================*)
(*                          NO-DEADLOCK STUTTER ACTIONS                                      *)
(*===========================================================================================*)
(*  Once the chain has halted (success at step 1 or 2, or any failure), no                   *)
(*  proper Next* / NextNo* action is enabled.  The three guards below                        *)
(*  describe the three terminal configurations; the body of each is the same                 *)
(*  no-op (UNCHANGED directory), so all three collapse to a single state-                    *)
(*  transition shape in any safety proof.                                                    *)
(*===========================================================================================*)
NextNoDeadlockHasFile ==
  /\ AllProved
  /\ UNCHANGED directory

NextNoDeadlockNoFileHasDir == 
  /\ isDisproved(1) 
  /\ isProved(2)
  /\ UNCHANGED directory

NextNoDeadlockNoFileNoDir == 
  /\ AllDisproved
  /\ UNCHANGED directory


(*===========================================================================================*)
(*                                   NEXT                                                    *)
(*===========================================================================================*)

NextDirectory ==
  \/ NextFile
  \/ NextNoFile
  \/ NextNoFileHasDir
  \/ NextNoFileNoDir
  \/ NextNoDeadlockHasFile
  \/ NextNoDeadlockNoFileHasDir
  \/ NextNoDeadlockNoFileNoDir

(*===========================================================================================*)
(*                                   SPEC                                                    *)
(*===========================================================================================*)
(*  Safety only.  No fairness clause: liveness is out of scope.                              *)
(*===========================================================================================*)

Spec == InitDirectory /\ [][NextDirectory]_directory

(*===========================================================================================*)
(*                              CHAIN INVARIANTS                                             *)
(*===========================================================================================*)
(*  State predicates capturing the safety properties of the two-step chain.                  *)
(*  FileImpliesSubdirectory and NoSubdirectoryImpliesNoFile are bundled into                 *)
(*  Inv (with TypeOK) and machine-checked by THEOREM INV via lemmas TYPE,                    *)
(*  PATH, and CONVERSEOF_PATH.  VerdictsExclusive follows from TypeOK alone.                 *)
(*===========================================================================================*)
FileImpliesSubdirectory == 
  isProved(1) => isProved(2)

NoSubdirectoryImpliesNoFile == 
  isDisproved(2) => isDisproved(1)

VerdictsExclusive == 
  /\ TypeOK
  /\ ~ (OK /\ NOT_OK)

Inv ==
  /\ TypeOK
  /\ FileImpliesSubdirectory 
  /\ NoSubdirectoryImpliesNoFile
  

LEMMA TYPE == Spec => []TypeOK
<1> USE DEF TypeOK, Knowledge, TruthValues, 
    InitDirectory, NextDirectory,
    AllAssumedFalse, AllProved, AllDisproved, 
    isAssumedFalse, isProved, isDisproved, getValue
<1>1. InitDirectory => TypeOK OBVIOUS
<1>2. TypeOK /\ [NextDirectory]_directory => TypeOK'
  <2>1 CASE NextFile   BY <2>1 DEF NextFile
  <2>2 CASE NextNoFile BY <2>2 DEF NextNoFile
  <2>3 CASE NextNoFileHasDir BY <2>3 DEF NextNoFileHasDir
  <2>4 CASE NextNoFileNoDir  BY <2>4 DEF NextNoFileNoDir
  <2>5 CASE NextNoDeadlockHasFile      BY <2>5 DEF NextNoDeadlockHasFile
  <2>6 CASE NextNoDeadlockNoFileHasDir BY <2>6 DEF NextNoDeadlockNoFileHasDir
  <2>7 CASE NextNoDeadlockNoFileNoDir  BY <2>7 DEF NextNoDeadlockNoFileNoDir
  <2> QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7 
<1> QED BY <1>1, <1>2, PTL DEF Spec

LEMMA PATH == Spec => []FileImpliesSubdirectory
<1> USE DEF Spec, FileImpliesSubdirectory, 
    InitDirectory, NextDirectory,
    TypeOK, Knowledge, TruthValues, 
    AllAssumedFalse, AllProved, AllDisproved, 
    isAssumedFalse, isProved, isDisproved, getValue
<1>1. InitDirectory => FileImpliesSubdirectory
  <2>1 InitDirectory => directory.has_preferences_file # "is proven true" OBVIOUS
  <2> QED BY <2>1
<1>2. FileImpliesSubdirectory /\ [NextDirectory]_directory => FileImpliesSubdirectory'
  <2>1 CASE NextFile   BY <2>1 DEF NextFile
  <2>2 CASE NextNoFile BY <2>2 DEF NextNoFile
  <2>3 CASE NextNoFileHasDir BY <2>3 DEF NextNoFileHasDir
  <2>4 CASE NextNoFileNoDir  BY <2>4 DEF NextNoFileNoDir
  <2>5 CASE NextNoDeadlockHasFile      BY <2>5 DEF NextNoDeadlockHasFile
  <2>6 CASE NextNoDeadlockNoFileHasDir BY <2>6 DEF NextNoDeadlockNoFileHasDir
  <2>7 CASE NextNoDeadlockNoFileNoDir  BY <2>7 DEF NextNoDeadlockNoFileNoDir
  <2> QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7
<1> QED BY <1>1, <1>2, PTL DEF Spec

LEMMA CONVERSEOF_PATH == Spec => []NoSubdirectoryImpliesNoFile
<1> USE DEF Spec, NoSubdirectoryImpliesNoFile, 
    InitDirectory, NextDirectory, 
    TypeOK, Knowledge, TruthValues,
    AllAssumedFalse, AllProved, AllDisproved,
    isAssumedFalse, isProved, isDisproved, getValue
<1>1. InitDirectory => NoSubdirectoryImpliesNoFile 
  <2>1 InitDirectory => directory.has_preferences_subdir # "is proven false" OBVIOUS
  <2> QED BY <2>1
<1>2. NoSubdirectoryImpliesNoFile /\ [NextDirectory]_directory => NoSubdirectoryImpliesNoFile'
  <2>1 CASE NextFile   BY  <2>1 DEF NextFile
  <2>2 CASE NextNoFile BY  <2>2 DEF NextNoFile
  <2>3 CASE NextNoFileHasDir BY  <2>3 DEF NextNoFileHasDir
  <2>4 CASE NextNoFileNoDir  BY  <2>4 DEF NextNoFileNoDir
  <2>5 CASE NextNoDeadlockHasFile      BY  <2>5 DEF NextNoDeadlockHasFile
  <2>6 CASE NextNoDeadlockNoFileHasDir BY  <2>6 DEF NextNoDeadlockNoFileHasDir
  <2>7 CASE NextNoDeadlockNoFileNoDir  BY  <2>7 DEF NextNoDeadlockNoFileNoDir
  <2> QED BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7
<1> QED BY <1>1, <1>2, PTL DEF Spec

THEOREM INV == Spec => []Inv BY TYPE, PATH, CONVERSEOF_PATH, PTL DEF Inv

THEOREM OK_OR_NOT_OK == Spec => [](OK \/ NOT_OK)
<1> USE DEF OK, NOT_OK, TypeOK, Knowledge, TruthValues,
    AllProved, AllAssumedFalse, AllDisproved,
    isProved, isDisproved, isAssumedFalse, getValue
<1>1. TypeOK => (OK \/ NOT_OK)
  <2>1 ASSUME TypeOK, AllProved  PROVE OK BY <2>1
  <2>2 ASSUME TypeOK, ~AllProved PROVE NOT_OK
    <3>1 ~isProved(1) \/ ~isProved(2) BY <2>2 DEF AllProved
    <3>2. CASE ~isProved(1)
      <4>1 directory.has_preferences_file \in TruthValues BY <2>2 
      <4>2 isDisproved(1) \/ isAssumedFalse(1) BY <3>2, <4>1
      <4> QED BY <2>2, <4>2 DEF NOT_OK
    <3>3 CASE ~isProved(2)
      <4>1. directory.has_preferences_subdir \in TruthValues BY <2>2
      <4>2. isDisproved(2) \/ isAssumedFalse(2) BY <3>3, <4>1
      <4> QED BY <2>2, <4>2
    <3> QED BY <3>1, <3>2, <3>3
  <2> QED BY <2>1, <2>2
<1> QED BY TYPE, <1>1, PTL DEF Spec


===============================================================================================
\* Modification History
\* Last modified Fri May 22 by gcordier (kaizen 2.0.2)
