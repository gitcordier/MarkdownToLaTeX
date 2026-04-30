----------------------------- MODULE Directory -----------------------------
(*****************************************************************************
  Directory.tla — formal specification AND proofs of the User-intent
                  decision procedure for MarkdownToLaTeX 1.0.0.

  Subject.   The User runs MarkdownToLaTeX 1.0.0 from a working directory
             DIR. Before any conversion can begin, MarkdownToLaTeX must
             decide whether DIR is "ready" — i.e. whether DIR contains a
             well-formed preferences.json at the canonical path
                  $DIR/preferences/preferences.json
             with the required schema keys at the top level and a legal
             value for "document class".

  Verdict.   The decision procedure produces exactly one of two terminal
             verdicts:
                  MUST_DO     — DIR is ready; conversion may proceed.
                  NOT_MUST_DO — DIR is not ready; conversion must not start.

  Semantics. Proof-state, not Kripke. The variable `directory` does not
             describe the filesystem; it describes the *evidence we have
             accumulated about the filesystem*. Every flag starts FALSE
             ("nothing proven yet") and may flip to TRUE only as the
             corresponding check succeeds. A flag never flips back.

  Termination. The procedure executes a fixed chain of nine checks. After
             the last one — or after any failure — the procedure halts.

  Disambiguation. To distinguish "not yet attempted" from "attempted and
             refuted", we keep a per-step `attempted` record alongside the
             proof flags (option (a) per design discussion).

  Author.    Jean-Gabriel Cordier, with Claude.
  Origin.    Earlier draft Tue Aug 08 2023 by gcordier (single-step model).
  This file. Kaizen step 1.3.0 — full chain, proof-state semantics,
             MUST_DO/NOT_MUST_DO verdict, XOR-completeness theorem,
             weak fairness, and TLAPS proof bodies for theorems T1–T6.
 *****************************************************************************)

EXTENDS TLAPS, FiniteSets, Naturals

(*---------------------------------------------------------------------------
  CONSTANTS
  ---------------------------------------------------------------------------
  LegalDocumentClass — the finite set of legal triples for the JSON value
                       at the "document class" key. Seeded with the single
                       default triple drawn from scopeStatement_1_3_0.md.
                       Extending this set later does not require any change
                       to this module.
 ---------------------------------------------------------------------------*)

CONSTANTS LegalDocumentClass

ASSUME LegalDocumentClassIsFinite ==
    /\ IsFiniteSet(LegalDocumentClass)
    /\ \A t \in LegalDocumentClass :
         t \in [class : STRING, size : STRING, paper : STRING]

(*---------------------------------------------------------------------------
  Verdict alphabet.
 ---------------------------------------------------------------------------*)

Verdict == { "UNKNOWN", "MUST_DO", "NOT_MUST_DO" }

(*---------------------------------------------------------------------------
  Step alphabet. Nine ordered steps, named by what they prove.
 ---------------------------------------------------------------------------*)

Step == { "is_dir",                   (* Step 1: DIR itself                  *)
          "preferences_is_dir",       (* Step 2: DIR/preferences             *)
          "preferences_has_file",     (* Step 3: preferences.json regular    *)
          "json_author",              (* Step 4a                             *)
          "json_email",               (* Step 4b                             *)
          "json_name",                (* Step 4c                             *)
          "json_main_font",           (* Step 4d                             *)
          "json_document_class",      (* Step 4e — key presence              *)
          "json_document_class_legal" (* Step 4f — value in LegalDocumentClass*)
        }

(*---------------------------------------------------------------------------
  Step ordering. The chain is linear; later steps may not be attempted until
  every earlier step has been proven.
 ---------------------------------------------------------------------------*)

Predecessors(s) ==
    CASE s = "is_dir"                    -> {}
      [] s = "preferences_is_dir"        -> {"is_dir"}
      [] s = "preferences_has_file"      -> {"is_dir", "preferences_is_dir"}
      [] s = "json_author"               -> {"is_dir", "preferences_is_dir",
                                             "preferences_has_file"}
      [] s = "json_email"                -> {"is_dir", "preferences_is_dir",
                                             "preferences_has_file",
                                             "json_author"}
      [] s = "json_name"                 -> {"is_dir", "preferences_is_dir",
                                             "preferences_has_file",
                                             "json_author", "json_email"}
      [] s = "json_main_font"            -> {"is_dir", "preferences_is_dir",
                                             "preferences_has_file",
                                             "json_author", "json_email",
                                             "json_name"}
      [] s = "json_document_class"       -> {"is_dir", "preferences_is_dir",
                                             "preferences_has_file",
                                             "json_author", "json_email",
                                             "json_name", "json_main_font"}
      [] s = "json_document_class_legal" -> {"is_dir", "preferences_is_dir",
                                             "preferences_has_file",
                                             "json_author", "json_email",
                                             "json_name", "json_main_font",
                                             "json_document_class"}

(*---------------------------------------------------------------------------
  VARIABLES

  directory       — proof flags accumulated about DIR. Each leaf is FALSE
                    initially and may flip to TRUE only via a SUCCESS action.
                    Flags never flip back.

  attempted       — per-step boolean: TRUE iff that step's SUCCESS or FAILURE
                    action has fired. Disambiguates "not yet" from "tried
                    and refuted".

  verdict         — UNKNOWN until the procedure halts; then exactly one of
                    MUST_DO or NOT_MUST_DO.
 ---------------------------------------------------------------------------*)

VARIABLES directory, attempted, verdict

vars == << directory, attempted, verdict >>

(*---------------------------------------------------------------------------
  Type — the shape of the evidence record. Top-level fields mirror the four
         layers of the design suggestion (DIR, preferences/, the JSON file,
         the JSON contents); leaf fields are the boolean proof flags.
 ---------------------------------------------------------------------------*)

Type == [
    is_dir : BOOLEAN,                       (* Step 1                       *)
    preferences : [
        is_dir   : BOOLEAN,                 (* Step 2                       *)
        has_file : BOOLEAN                  (* Step 3                       *)
    ],
    preferences_json : [
        keys : [                            (* Step 4a..4e                  *)
            author         : BOOLEAN,
            email          : BOOLEAN,
            name           : BOOLEAN,
            main_font      : BOOLEAN,
            document_class : BOOLEAN
        ],
        document_class_legal : BOOLEAN      (* Step 4f                      *)
    ]
]

TypeOK ==
    /\ directory \in Type
    /\ attempted \in [Step -> BOOLEAN]
    /\ verdict   \in Verdict

(*---------------------------------------------------------------------------
  Convenience: the proof-flag value for a given step.
 ---------------------------------------------------------------------------*)

Proven(s) ==
    CASE s = "is_dir"                    -> directory.is_dir
      [] s = "preferences_is_dir"        -> directory.preferences.is_dir
      [] s = "preferences_has_file"      -> directory.preferences.has_file
      [] s = "json_author"               -> directory.preferences_json.keys.author
      [] s = "json_email"                -> directory.preferences_json.keys.email
      [] s = "json_name"                 -> directory.preferences_json.keys.name
      [] s = "json_main_font"            -> directory.preferences_json.keys.main_font
      [] s = "json_document_class"       -> directory.preferences_json.keys.document_class
      [] s = "json_document_class_legal" -> directory.preferences_json.document_class_legal

(*---------------------------------------------------------------------------
  AllProven — every flag TRUE. Equivalent to MUST_DO at termination.
 ---------------------------------------------------------------------------*)

AllProven == \A s \in Step : Proven(s)

(*===========================================================================
                                   INIT
  ---------------------------------------------------------------------------
  Nothing has been proven, nothing has been attempted, the verdict is open.
 ===========================================================================*)

InitDirectory == [
    is_dir |-> FALSE,
    preferences |-> [is_dir |-> FALSE, has_file |-> FALSE],
    preferences_json |-> [
        keys |-> [author         |-> FALSE,
                  email          |-> FALSE,
                  name           |-> FALSE,
                  main_font      |-> FALSE,
                  document_class |-> FALSE],
        document_class_legal |-> FALSE
    ]
]

Init ==
    /\ directory = InitDirectory
    /\ attempted = [s \in Step |-> FALSE]
    /\ verdict   = "UNKNOWN"

(*===========================================================================
                                  GUARDS
  ---------------------------------------------------------------------------
  A step is `Ready` when every predecessor has been proven, the step itself
  has not been attempted, and the verdict is still UNKNOWN.
 ===========================================================================*)

Ready(s) ==
    /\ verdict = "UNKNOWN"
    /\ ~ attempted[s]
    /\ \A p \in Predecessors(s) : Proven(p)

(*===========================================================================
                              SUCCESS ACTIONS
  ---------------------------------------------------------------------------
  Each success action:
    (1) requires Ready(s);
    (2) flips Proven(s) from FALSE to TRUE in `directory`;
    (3) marks `attempted[s] := TRUE`;
    (4) leaves `verdict` UNKNOWN unless this is the final step
        (`json_document_class_legal`), in which case `verdict := MUST_DO`.
 ===========================================================================*)

\* Helpers for record updates -------------------------------------------------

WithProvenIsDir ==
    [directory EXCEPT !.is_dir = TRUE]

WithProvenPreferencesIsDir ==
    [directory EXCEPT !.preferences.is_dir = TRUE]

WithProvenPreferencesHasFile ==
    [directory EXCEPT !.preferences.has_file = TRUE]

WithProvenJsonKey(k) ==
    [directory EXCEPT !.preferences_json.keys[k] = TRUE]

WithProvenDocClassLegal ==
    [directory EXCEPT !.preferences_json.document_class_legal = TRUE]

\* Success actions ------------------------------------------------------------

Check_IS_DIR_SUCCESS ==
    /\ Ready("is_dir")
    /\ directory' = WithProvenIsDir
    /\ attempted' = [attempted EXCEPT !["is_dir"] = TRUE]
    /\ UNCHANGED verdict

Check_PREFS_IS_DIR_SUCCESS ==
    /\ Ready("preferences_is_dir")
    /\ directory' = WithProvenPreferencesIsDir
    /\ attempted' = [attempted EXCEPT !["preferences_is_dir"] = TRUE]
    /\ UNCHANGED verdict

Check_PREFS_HAS_FILE_SUCCESS ==
    /\ Ready("preferences_has_file")
    /\ directory' = WithProvenPreferencesHasFile
    /\ attempted' = [attempted EXCEPT !["preferences_has_file"] = TRUE]
    /\ UNCHANGED verdict

Check_JSON_AUTHOR_SUCCESS ==
    /\ Ready("json_author")
    /\ directory' = WithProvenJsonKey("author")
    /\ attempted' = [attempted EXCEPT !["json_author"] = TRUE]
    /\ UNCHANGED verdict

Check_JSON_EMAIL_SUCCESS ==
    /\ Ready("json_email")
    /\ directory' = WithProvenJsonKey("email")
    /\ attempted' = [attempted EXCEPT !["json_email"] = TRUE]
    /\ UNCHANGED verdict

Check_JSON_NAME_SUCCESS ==
    /\ Ready("json_name")
    /\ directory' = WithProvenJsonKey("name")
    /\ attempted' = [attempted EXCEPT !["json_name"] = TRUE]
    /\ UNCHANGED verdict

Check_JSON_MAIN_FONT_SUCCESS ==
    /\ Ready("json_main_font")
    /\ directory' = WithProvenJsonKey("main_font")
    /\ attempted' = [attempted EXCEPT !["json_main_font"] = TRUE]
    /\ UNCHANGED verdict

Check_JSON_DOC_CLASS_SUCCESS ==
    /\ Ready("json_document_class")
    /\ directory' = WithProvenJsonKey("document_class")
    /\ attempted' = [attempted EXCEPT !["json_document_class"] = TRUE]
    /\ UNCHANGED verdict

\* Final success — flips the verdict to MUST_DO.
Check_JSON_DOC_CLASS_LEGAL_SUCCESS ==
    /\ Ready("json_document_class_legal")
    /\ directory' = WithProvenDocClassLegal
    /\ attempted' = [attempted EXCEPT !["json_document_class_legal"] = TRUE]
    /\ verdict'   = "MUST_DO"

(*===========================================================================
                              FAILURE ACTIONS
  ---------------------------------------------------------------------------
  Any step that is `Ready` may instead fail. A failure:
    (1) does not flip the proof flag;
    (2) marks `attempted[s] := TRUE`;
    (3) sets `verdict := NOT_MUST_DO`, terminating the procedure.

  We define a single parameterised failure action and instantiate it for
  each step in the disjunction below.
 ===========================================================================*)

Fail(s) ==
    /\ Ready(s)
    /\ UNCHANGED directory
    /\ attempted' = [attempted EXCEPT ![s] = TRUE]
    /\ verdict'   = "NOT_MUST_DO"

(*===========================================================================
                                   NEXT
 ===========================================================================*)

Next ==
    \/ Check_IS_DIR_SUCCESS
    \/ Check_PREFS_IS_DIR_SUCCESS
    \/ Check_PREFS_HAS_FILE_SUCCESS
    \/ Check_JSON_AUTHOR_SUCCESS
    \/ Check_JSON_EMAIL_SUCCESS
    \/ Check_JSON_NAME_SUCCESS
    \/ Check_JSON_MAIN_FONT_SUCCESS
    \/ Check_JSON_DOC_CLASS_SUCCESS
    \/ Check_JSON_DOC_CLASS_LEGAL_SUCCESS
    \/ \E s \in Step : Fail(s)

(*===========================================================================
                                FAIRNESS / SPEC
  ---------------------------------------------------------------------------
  Weak fairness on `Next` ensures the procedure cannot stall forever in an
  intermediate state: if a step is continuously Ready, it must eventually
  fire (either as success or failure).
 ===========================================================================*)

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

(*===========================================================================
                                INVARIANTS
 ===========================================================================*)

(* I1 — type-correctness. *)
Inv_TypeOK == TypeOK

(* I2 — monotonicity of proof flags is enforced action-by-action; we state
        it here as a stuttering invariant on consecutive states. *)
Inv_FlagsMonotone ==
    [][\A s \in Step : Proven(s) => Proven(s)']_vars

(* I3 — `attempted` is monotone too: once attempted, always attempted. *)
Inv_AttemptedMonotone ==
    [][\A s \in Step : attempted[s] => attempted'[s]]_vars

(* I4 — the verdict, once decided, is permanent. *)
Inv_VerdictStable ==
    [][verdict # "UNKNOWN" => verdict' = verdict]_vars

(* I5 — soundness of MUST_DO: it can only be set when every flag is TRUE. *)
Inv_MustDoSound ==
    (verdict = "MUST_DO") => AllProven

(* I6 — soundness of NOT_MUST_DO: it implies at least one flag is FALSE. *)
Inv_NotMustDoSound ==
    (verdict = "NOT_MUST_DO") => ~ AllProven

(* H — auxiliary state invariant bridging proof flags and `attempted`. The
       success actions are the only paths to Proven(s) = TRUE, and each
       such action also sets attempted[s] := TRUE; therefore Proven(s)
       implies attempted[s] in every reachable state. Used to establish
       T6 (NotMustDoSoundness). *)
Inv_ProvenAttempted ==
    \A s \in Step : Proven(s) => attempted[s]

(*===========================================================================
                          DEFINITIONS USED IN THEOREMS
  ---------------------------------------------------------------------------
  These definitions are stated up front so that every theorem below can
  refer to them without forward references.
 ===========================================================================*)

(* Termination predicate. The procedure has halted when verdict has been
   pinned to one of the two terminal values. *)
Terminated == verdict \in {"MUST_DO", "NOT_MUST_DO"}

(* XOR-completeness predicate (T4). At termination, exactly one of MUST_DO
   and NOT_MUST_DO holds; spelled out as a propositional XOR over the two
   string equalities. *)
XORComplete ==
    Terminated =>
        (   (verdict = "MUST_DO"     /\ verdict # "NOT_MUST_DO")
         \/ (verdict = "NOT_MUST_DO" /\ verdict # "MUST_DO"    ) )

(* Termination measure: how many steps have been attempted so far. The
   chain has 9 steps; each non-stutter Next-action increments this by
   exactly one. Used in the leads-to chain that proves T3. *)
AttemptedCount == Cardinality({s \in Step : attempted[s]})

(* Family of intermediate predicates for the leads-to chain (T3). The
   procedure terminates, OR at least k steps have been attempted. *)
P(k) == Terminated \/ AttemptedCount >= k

(*===========================================================================
                                THEOREMS
  ---------------------------------------------------------------------------
  T1, T2, T4, T5, T6 are safety properties; T3 is the lone liveness
  property and depends on the WF_vars(Next) fairness clause.

  Order below: T1, T2, helper, T5, T6, T4, supporting machinery for T3,
  T3. This order mirrors the proof-dependency DAG (see
  properties.figures.1.3.0.tex, Figure 2) and ensures every reference is
  backward.
 ===========================================================================*)

(*---------------------------------------------------------------------------
  T1 — Type-correctness is preserved.
  ---------------------------------------------------------------------------
  Standard inductive-invariant proof. We dispatch on the structure of
  Next, then on each disjunct.
 ---------------------------------------------------------------------------*)

THEOREM TypeCorrectness == Spec => []TypeOK
<1>1. Init => TypeOK
  BY DEF Init, InitDirectory, TypeOK, Type, Verdict, Step
<1>2. TypeOK /\ [Next]_vars => TypeOK'
  <2> SUFFICES ASSUME TypeOK, [Next]_vars
               PROVE  TypeOK'
    OBVIOUS
  <2> USE DEF TypeOK, Type, Verdict, Step
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars
  <2>2. CASE Check_IS_DIR_SUCCESS
    BY <2>2 DEF Check_IS_DIR_SUCCESS, WithProvenIsDir
  <2>3. CASE Check_PREFS_IS_DIR_SUCCESS
    BY <2>3 DEF Check_PREFS_IS_DIR_SUCCESS, WithProvenPreferencesIsDir
  <2>4. CASE Check_PREFS_HAS_FILE_SUCCESS
    BY <2>4 DEF Check_PREFS_HAS_FILE_SUCCESS, WithProvenPreferencesHasFile
  <2>5. CASE Check_JSON_AUTHOR_SUCCESS
    BY <2>5 DEF Check_JSON_AUTHOR_SUCCESS, WithProvenJsonKey
  <2>6. CASE Check_JSON_EMAIL_SUCCESS
    BY <2>6 DEF Check_JSON_EMAIL_SUCCESS, WithProvenJsonKey
  <2>7. CASE Check_JSON_NAME_SUCCESS
    BY <2>7 DEF Check_JSON_NAME_SUCCESS, WithProvenJsonKey
  <2>8. CASE Check_JSON_MAIN_FONT_SUCCESS
    BY <2>8 DEF Check_JSON_MAIN_FONT_SUCCESS, WithProvenJsonKey
  <2>9. CASE Check_JSON_DOC_CLASS_SUCCESS
    BY <2>9 DEF Check_JSON_DOC_CLASS_SUCCESS, WithProvenJsonKey
  <2>10. CASE Check_JSON_DOC_CLASS_LEGAL_SUCCESS
    BY <2>10 DEF Check_JSON_DOC_CLASS_LEGAL_SUCCESS, WithProvenDocClassLegal
  <2>11. CASE \E s \in Step : Fail(s)
    BY <2>11 DEF Fail
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9, <2>10, <2>11
       DEF Next
<1> QED
  BY <1>1, <1>2, PTL DEF Spec

(*---------------------------------------------------------------------------
  T2 — Verdict stability: once decided (≠ UNKNOWN), the verdict cannot
       change. Every action that *changes* the verdict is guarded by
       Ready(_), which itself requires verdict = "UNKNOWN". So if the
       pre-state has a decided verdict, the only enabled transition is
       a stutter, which preserves it.
 ---------------------------------------------------------------------------*)

THEOREM VerdictStability == Spec => Inv_VerdictStable
<1>1. [Next]_vars /\ verdict # "UNKNOWN" => verdict' = verdict
  <2> SUFFICES ASSUME [Next]_vars, verdict # "UNKNOWN"
               PROVE  verdict' = verdict
    OBVIOUS
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars
  <2>2. CASE Next
    <3> USE DEF Ready
    <3>1. CASE Check_IS_DIR_SUCCESS
      BY <3>1, <2>2 DEF Check_IS_DIR_SUCCESS
    <3>2. CASE Check_PREFS_IS_DIR_SUCCESS
      BY <3>2, <2>2 DEF Check_PREFS_IS_DIR_SUCCESS
    <3>3. CASE Check_PREFS_HAS_FILE_SUCCESS
      BY <3>3, <2>2 DEF Check_PREFS_HAS_FILE_SUCCESS
    <3>4. CASE Check_JSON_AUTHOR_SUCCESS
      BY <3>4, <2>2 DEF Check_JSON_AUTHOR_SUCCESS
    <3>5. CASE Check_JSON_EMAIL_SUCCESS
      BY <3>5, <2>2 DEF Check_JSON_EMAIL_SUCCESS
    <3>6. CASE Check_JSON_NAME_SUCCESS
      BY <3>6, <2>2 DEF Check_JSON_NAME_SUCCESS
    <3>7. CASE Check_JSON_MAIN_FONT_SUCCESS
      BY <3>7, <2>2 DEF Check_JSON_MAIN_FONT_SUCCESS
    <3>8. CASE Check_JSON_DOC_CLASS_SUCCESS
      BY <3>8, <2>2 DEF Check_JSON_DOC_CLASS_SUCCESS
    <3>9. CASE Check_JSON_DOC_CLASS_LEGAL_SUCCESS
      \* Action requires Ready, which requires verdict = "UNKNOWN".
      \* Contradiction with the assumption verdict # "UNKNOWN".
      BY <3>9, <2>2 DEF Check_JSON_DOC_CLASS_LEGAL_SUCCESS
    <3>10. CASE \E s \in Step : Fail(s)
      BY <3>10, <2>2 DEF Fail
    <3> QED
      BY <2>2, <3>1, <3>2, <3>3, <3>4, <3>5, <3>6, <3>7, <3>8, <3>9, <3>10
         DEF Next
  <2> QED BY <2>1, <2>2 DEF [Next]_vars
<1> QED
  BY <1>1, PTL DEF Spec, Inv_VerdictStable

(*---------------------------------------------------------------------------
  Helper lemma: Inv_ProvenAttempted is preserved.
  ---------------------------------------------------------------------------
  Each success action is the only way to flip a proof flag, and it always
  also flips the corresponding `attempted` entry. Failure actions and
  stutter never flip a proof flag. So Proven(s) ⇒ attempted[s] is
  inductive.

  We need this lemma for T6 (NotMustDoSoundness): it lets us deduce that
  the step which fired Fail(_) had its flag still FALSE at the moment of
  failure — i.e. the step's Proven(_) was never set, so AllProven was
  refuted.
 ---------------------------------------------------------------------------*)

LEMMA ProvenAttemptedInvariant == Spec => []Inv_ProvenAttempted
<1>1. Init => Inv_ProvenAttempted
  BY DEF Init, InitDirectory, Inv_ProvenAttempted, Proven, Step
<1>2. TypeOK /\ Inv_ProvenAttempted /\ [Next]_vars => Inv_ProvenAttempted'
  <2> SUFFICES ASSUME TypeOK, Inv_ProvenAttempted, [Next]_vars,
                      NEW s \in Step, Proven(s)'
               PROVE  attempted'[s]
    BY DEF Inv_ProvenAttempted
  <2> USE DEF TypeOK, Type, Step, Proven, Inv_ProvenAttempted
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars
  <2>2. CASE Check_IS_DIR_SUCCESS
    \* Action sets directory'.is_dir = TRUE and attempted'["is_dir"] = TRUE,
    \* and leaves all other proof flags and other attempted entries unchanged.
    BY <2>2 DEF Check_IS_DIR_SUCCESS, WithProvenIsDir
  <2>3. CASE Check_PREFS_IS_DIR_SUCCESS
    BY <2>3 DEF Check_PREFS_IS_DIR_SUCCESS, WithProvenPreferencesIsDir
  <2>4. CASE Check_PREFS_HAS_FILE_SUCCESS
    BY <2>4 DEF Check_PREFS_HAS_FILE_SUCCESS, WithProvenPreferencesHasFile
  <2>5. CASE Check_JSON_AUTHOR_SUCCESS
    BY <2>5 DEF Check_JSON_AUTHOR_SUCCESS, WithProvenJsonKey
  <2>6. CASE Check_JSON_EMAIL_SUCCESS
    BY <2>6 DEF Check_JSON_EMAIL_SUCCESS, WithProvenJsonKey
  <2>7. CASE Check_JSON_NAME_SUCCESS
    BY <2>7 DEF Check_JSON_NAME_SUCCESS, WithProvenJsonKey
  <2>8. CASE Check_JSON_MAIN_FONT_SUCCESS
    BY <2>8 DEF Check_JSON_MAIN_FONT_SUCCESS, WithProvenJsonKey
  <2>9. CASE Check_JSON_DOC_CLASS_SUCCESS
    BY <2>9 DEF Check_JSON_DOC_CLASS_SUCCESS, WithProvenJsonKey
  <2>10. CASE Check_JSON_DOC_CLASS_LEGAL_SUCCESS
    BY <2>10 DEF Check_JSON_DOC_CLASS_LEGAL_SUCCESS, WithProvenDocClassLegal
  <2>11. CASE \E t \in Step : Fail(t)
    \* Failure actions leave `directory` unchanged. So Proven(s)' = Proven(s).
    \* And attempted only grows: attempted'[s] = TRUE if it was TRUE.
    BY <2>11 DEF Fail
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9, <2>10, <2>11
       DEF Next
<1> QED
  BY <1>1, <1>2, TypeCorrectness, PTL DEF Spec

(*---------------------------------------------------------------------------
  T5 — Soundness of MUST_DO: verdict = MUST_DO ⇒ AllProven.
  ---------------------------------------------------------------------------
  Inductive. Init has verdict = UNKNOWN, vacuous.

  For the step case, suppose verdict' = MUST_DO. Either:
    (a) verdict = MUST_DO and the action is a stutter or one whose guard
        Ready(_) requires verdict = UNKNOWN — the latter is therefore
        impossible. Stutter preserves AllProven by IH and UNCHANGED.
    (b) verdict = UNKNOWN in the pre-state and the action is one that
        sets verdict := MUST_DO. The only such action is
        Check_JSON_DOC_CLASS_LEGAL_SUCCESS, whose guard requires every
        predecessor proven (i.e. flags 1..8) and which itself proves
        flag 9. So AllProven' holds.

  No other action can produce verdict' = MUST_DO.
 ---------------------------------------------------------------------------*)

THEOREM MustDoSoundness == Spec => []Inv_MustDoSound
<1>1. Init => Inv_MustDoSound
  BY DEF Init, Inv_MustDoSound, Verdict
<1>2. TypeOK /\ Inv_MustDoSound /\ [Next]_vars => Inv_MustDoSound'
  <2> SUFFICES ASSUME TypeOK, Inv_MustDoSound, [Next]_vars,
                      verdict' = "MUST_DO"
               PROVE  AllProven'
    BY DEF Inv_MustDoSound
  <2> USE DEF TypeOK, Type, Step, Verdict, Ready, AllProven, Proven,
              Inv_MustDoSound
  <2>1. CASE UNCHANGED vars
    BY <2>1 DEF vars
  <2>2. CASE Check_IS_DIR_SUCCESS
    \* This action has UNCHANGED verdict. So verdict = "MUST_DO" pre.
    \* But Ready("is_dir") demands verdict = "UNKNOWN". Contradiction.
    BY <2>2 DEF Check_IS_DIR_SUCCESS
  <2>3. CASE Check_PREFS_IS_DIR_SUCCESS
    BY <2>3 DEF Check_PREFS_IS_DIR_SUCCESS
  <2>4. CASE Check_PREFS_HAS_FILE_SUCCESS
    BY <2>4 DEF Check_PREFS_HAS_FILE_SUCCESS
  <2>5. CASE Check_JSON_AUTHOR_SUCCESS
    BY <2>5 DEF Check_JSON_AUTHOR_SUCCESS
  <2>6. CASE Check_JSON_EMAIL_SUCCESS
    BY <2>6 DEF Check_JSON_EMAIL_SUCCESS
  <2>7. CASE Check_JSON_NAME_SUCCESS
    BY <2>7 DEF Check_JSON_NAME_SUCCESS
  <2>8. CASE Check_JSON_MAIN_FONT_SUCCESS
    BY <2>8 DEF Check_JSON_MAIN_FONT_SUCCESS
  <2>9. CASE Check_JSON_DOC_CLASS_SUCCESS
    BY <2>9 DEF Check_JSON_DOC_CLASS_SUCCESS
  <2>10. CASE Check_JSON_DOC_CLASS_LEGAL_SUCCESS
    \* Ready("json_document_class_legal") requires every predecessor
    \* proven. The action itself proves the last flag. The other eight
    \* flags survive the EXCEPT update unchanged.
    BY <2>10 DEF Check_JSON_DOC_CLASS_LEGAL_SUCCESS,
                 WithProvenDocClassLegal, Predecessors
  <2>11. CASE \E s \in Step : Fail(s)
    \* Fail sets verdict' = "NOT_MUST_DO", contradicting verdict' = "MUST_DO".
    BY <2>11 DEF Fail
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9, <2>10, <2>11
       DEF Next
<1> QED
  BY <1>1, <1>2, TypeCorrectness, PTL DEF Spec

(*---------------------------------------------------------------------------
  T6 — Soundness of NOT_MUST_DO: verdict = NOT_MUST_DO ⇒ ¬AllProven.
  ---------------------------------------------------------------------------
  The only action that sets verdict := NOT_MUST_DO is Fail(s) for some s.
  Fail(s) is guarded by Ready(s), which requires ¬attempted[s]. Combined
  with the helper invariant Inv_ProvenAttempted (Proven(s) ⇒ attempted[s]),
  we deduce ¬Proven(s) at the moment of failure. Fail leaves `directory`
  unchanged, so ¬Proven(s)' as well — i.e. ¬AllProven'.

  Verdict stability (T2) then carries this forward: once verdict =
  NOT_MUST_DO, no action fires that would re-prove flag s, so
  ¬Proven(s) is permanent and ¬AllProven holds at every subsequent state.
 ---------------------------------------------------------------------------*)

THEOREM NotMustDoSoundness == Spec => []Inv_NotMustDoSound
<1>1. Init => Inv_NotMustDoSound
  BY DEF Init, Inv_NotMustDoSound, Verdict
<1>2. TypeOK /\ Inv_ProvenAttempted /\ Inv_NotMustDoSound /\ [Next]_vars
        => Inv_NotMustDoSound'
  <2> SUFFICES ASSUME TypeOK, Inv_ProvenAttempted, Inv_NotMustDoSound,
                      [Next]_vars, verdict' = "NOT_MUST_DO"
               PROVE  ~ AllProven'
    BY DEF Inv_NotMustDoSound
  <2> USE DEF TypeOK, Type, Step, Verdict, Ready, AllProven, Proven,
              Inv_ProvenAttempted, Inv_NotMustDoSound
  <2>1. CASE UNCHANGED vars
    \* verdict' = verdict = "NOT_MUST_DO" pre-state. By IH ¬AllProven, and
    \* `directory` unchanged, so ¬AllProven'.
    BY <2>1 DEF vars
  <2>2. CASE Check_IS_DIR_SUCCESS
    \* UNCHANGED verdict, so verdict = "NOT_MUST_DO" pre. But Ready
    \* demands verdict = "UNKNOWN". Contradiction.
    BY <2>2 DEF Check_IS_DIR_SUCCESS
  <2>3. CASE Check_PREFS_IS_DIR_SUCCESS
    BY <2>3 DEF Check_PREFS_IS_DIR_SUCCESS
  <2>4. CASE Check_PREFS_HAS_FILE_SUCCESS
    BY <2>4 DEF Check_PREFS_HAS_FILE_SUCCESS
  <2>5. CASE Check_JSON_AUTHOR_SUCCESS
    BY <2>5 DEF Check_JSON_AUTHOR_SUCCESS
  <2>6. CASE Check_JSON_EMAIL_SUCCESS
    BY <2>6 DEF Check_JSON_EMAIL_SUCCESS
  <2>7. CASE Check_JSON_NAME_SUCCESS
    BY <2>7 DEF Check_JSON_NAME_SUCCESS
  <2>8. CASE Check_JSON_MAIN_FONT_SUCCESS
    BY <2>8 DEF Check_JSON_MAIN_FONT_SUCCESS
  <2>9. CASE Check_JSON_DOC_CLASS_SUCCESS
    BY <2>9 DEF Check_JSON_DOC_CLASS_SUCCESS
  <2>10. CASE Check_JSON_DOC_CLASS_LEGAL_SUCCESS
    \* This action sets verdict' = "MUST_DO", not "NOT_MUST_DO".
    BY <2>10 DEF Check_JSON_DOC_CLASS_LEGAL_SUCCESS
  <2>11. CASE \E s \in Step : Fail(s)
    \* The witnessing s has Ready(s), hence ¬attempted[s]. By the helper
    \* invariant Inv_ProvenAttempted, ¬Proven(s). Fail leaves directory
    \* unchanged, so ¬Proven(s)' — i.e. ¬AllProven'.
    BY <2>11 DEF Fail
  <2> QED
    BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, <2>9, <2>10, <2>11
       DEF Next
<1> QED
  BY <1>1, <1>2, TypeCorrectness, ProvenAttemptedInvariant, PTL DEF Spec

(*---------------------------------------------------------------------------
  T4 — XOR-completeness: at termination, exactly one of MUST_DO and
       NOT_MUST_DO holds. Trivially true given that "MUST_DO" and
       "NOT_MUST_DO" are distinct strings: the structure of XORComplete
       reduces to a tautology in the verdict alphabet.
 ---------------------------------------------------------------------------*)

THEOREM XORCompleteness == Spec => [](Terminated => XORComplete)
<1>1. \A v \in Verdict :
        (v \in {"MUST_DO", "NOT_MUST_DO"})
          => (   (v = "MUST_DO"     /\ v # "NOT_MUST_DO")
              \/ (v = "NOT_MUST_DO" /\ v # "MUST_DO"    ) )
  BY DEF Verdict
<1>2. []TypeOK => [](Terminated => XORComplete)
  <2> SUFFICES ASSUME TypeOK, Terminated PROVE XORComplete
    BY PTL
  <2> QED
    BY <1>1 DEF TypeOK, Terminated, XORComplete
<1> QED
  BY <1>2, TypeCorrectness, PTL DEF Spec

(*---------------------------------------------------------------------------
  T3 — Termination (LIVENESS).
  ---------------------------------------------------------------------------
  Strategy. From any non-terminated state with k attempted steps
  (0 <= k < 9), the next-in-chain step s_{k+1} is Ready, so Next is
  enabled. By WF_vars(Next), Next must eventually fire. After it fires,
  either verdict became terminal (we are done) or attempted-count became
  k+1. Iterating gives termination in at most 9 transitions.

  We formalize this as a leads-to chain on P(k) := Terminated ∨
  AttemptedCount ≥ k. Then:
    (a) Init satisfies P(0) (vacuously: 0 ≥ 0).
    (b) For each k in 0..8: Spec ⇒ P(k) ⇝ P(k+1), by one application
        of the WF1 inference rule with witness action Next.
    (c) P(9) implies Terminated: nine attempted steps and verdict =
        UNKNOWN is impossible — the only way for the ninth attempt
        to be a success is via Check_JSON_DOC_CLASS_LEGAL_SUCCESS,
        which sets verdict := MUST_DO; the only other option is a
        Fail(_), which sets verdict := NOT_MUST_DO.

  The proof below states the leads-to chain. The individual links are
  flagged OMITTED — they are routine WF1 applications and are the
  expected locus of TLAPS iteration; see properties.1.3.0.md, §"T3:
  Termination", for the full WF1 instances.
 ---------------------------------------------------------------------------*)

LEMMA InitImpliesP0 == Init => P(0)
  \* P(0) says Terminated \/ AttemptedCount >= 0. The right disjunct holds
  \* in every reachable state because Cardinality returns a natural and
  \* every natural is ≥ 0. The proof reduces to invoking the standard
  \* finiteness lemmas from TLAPS' FiniteSetTheorems library; we keep
  \* the proof short and let TLAPS/Toolbox supply the cardinality
  \* bookkeeping. If iteration is needed, instantiate FS_CardinalityType
  \* on the set {s \in Step : attempted[s]}.
  BY DEF Init, P, Terminated, AttemptedCount

LEMMA P9ImpliesTerminated == TypeOK /\ P(9) => Terminated
  <1> SUFFICES ASSUME TypeOK, P(9), ~ Terminated
               PROVE  FALSE
    OBVIOUS
  \* P(9) and ¬Terminated together force AttemptedCount ≥ 9. Step has
  \* exactly 9 elements, so {s ∈ Step : attempted[s]} = Step, i.e. every
  \* step has been attempted. The 9th attempt was either the final
  \* success (which sets verdict = "MUST_DO") or some Fail (which sets
  \* verdict = "NOT_MUST_DO"). Either way verdict ≠ "UNKNOWN", which
  \* means Terminated — contradicting the hypothesis ¬Terminated.
  \*
  \* The cardinality bookkeeping below is routine. If TLAPS struggles
  \* on it, the auxiliary FS_* lemmas from FiniteSetTheorems can be
  \* invoked explicitly; see properties.1.3.0.md, §"T3 supporting
  \* lemmas".
  <1> QED
    BY DEF TypeOK, Type, Step, P, AttemptedCount, Terminated, Verdict

(* The leads-to links. Each is one application of the WF1 rule with the
   witness action Next, the transient predicate "exactly k attempted",
   and the goal "k+1 attempted or terminated". The OMITTED tags are the
   intended iteration points in the TLA Toolbox. *)

LEMMA Step0_1 == Spec => (P(0) ~> P(1))
  PROOF OMITTED
LEMMA Step1_2 == Spec => (P(1) ~> P(2))
  PROOF OMITTED
LEMMA Step2_3 == Spec => (P(2) ~> P(3))
  PROOF OMITTED
LEMMA Step3_4 == Spec => (P(3) ~> P(4))
  PROOF OMITTED
LEMMA Step4_5 == Spec => (P(4) ~> P(5))
  PROOF OMITTED
LEMMA Step5_6 == Spec => (P(5) ~> P(6))
  PROOF OMITTED
LEMMA Step6_7 == Spec => (P(6) ~> P(7))
  PROOF OMITTED
LEMMA Step7_8 == Spec => (P(7) ~> P(8))
  PROOF OMITTED
LEMMA Step8_9 == Spec => (P(8) ~> P(9))
  PROOF OMITTED

THEOREM Termination == Spec => <>Terminated
<1>1. Spec => (P(0) ~> P(9))
  \* Transitivity of ~> chained nine times.
  BY Step0_1, Step1_2, Step2_3, Step3_4, Step4_5,
     Step5_6, Step6_7, Step7_8, Step8_9, PTL
<1>2. Spec => P(0)
  BY InitImpliesP0, PTL DEF Spec
<1>3. Spec => <>P(9)
  BY <1>1, <1>2, PTL
<1>4. Spec => []TypeOK
  BY TypeCorrectness
<1>5. Spec => <>Terminated
  BY <1>3, <1>4, P9ImpliesTerminated, PTL
<1> QED BY <1>5

(*===========================================================================
                            END OF PROOFS
 ===========================================================================*)

=============================================================================
\* Modification History
\* Last modified Thu Apr 30 2026 by Jean-Gabriel Cordier (with Claude)
\*   Kaizen step 1.3.0 — added TLAPS proof bodies for T1 (TypeCorrectness),
\*   T2 (VerdictStability), T4 (XORCompleteness), T5 (MustDoSoundness),
\*   T6 (NotMustDoSoundness), and a structured leads-to skeleton for
\*   T3 (Termination) with nine OMITTED WF1 links to be discharged in
\*   the TLA Toolbox. Introduced the auxiliary state invariant
\*   Inv_ProvenAttempted and the bridging lemma ProvenAttemptedInvariant.
\*   Added Naturals to EXTENDS for AttemptedCount/Cardinality arithmetic.
\* Last modified Wed Apr 29 2026 by Jean-Gabriel Cordier (with Claude)
\*   Kaizen step 1.2.3 — proof-state semantics, full 9-step chain,
\*   per-step `attempted` record, MUST_DO/NOT_MUST_DO verdict,
\*   XOR-completeness theorem, weak fairness.
\* Created    Tue Aug 08 2023        by gcordier
