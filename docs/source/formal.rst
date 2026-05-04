Formal specification
====================

MarkdownToLaTeX 1.0.0 is developed under a Kaizen discipline. The
workspace-readiness procedure is formally specified in TLA⁺ and
machine-checked with TLAPS.

Deliverables at kaizen step 1.3.7
-----------------------------------

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - File
     - Role
   * - ``Directory.1.3.7.tla``
     - TLA⁺ module. Three-step file-system chain, safety theorems T1–T8,
       complete TLAPS proof bodies.
   * - ``specifications.formal.1.3.7.md``
     - Narrative: two-records semantics, theorem inventory, Python bridge.
   * - ``conformance.1.3.7.pdf``
     - TLA⁺ ↔ Python conformance table (compiled LuaLaTeX).
   * - ``figures.1.3.7.tex``
     - LuaLaTeX figures: state-transition diagram (F1), truth table (F2),
       theorem inventory (F3).

Headline property (T8)
-----------------------

.. math::

   \mathit{Spec} \Rightarrow \square\,\neg\,(\mathit{OK} \wedge \mathit{NOT\_OK})

``OK`` and ``NOT\_OK`` are mutually exclusive in every reachable state.
At every halt state exactly one holds — the chain either succeeds
completely or fails at the first step that does not pass.

Reachable state space
----------------------

Seven states, arranged as a depth-3 tree. The node labels show
``(directory, check)`` as triples ``(is_dir, has_pref_dir, has_json)``:

.. code-block:: text

                         s₀ Init  dir=(T,T,T)  chk=(F,F,F)
                        /                              \
          NextHasNoDir /                                \ NextHasDir
                      /                                  \
     s₂ NOT_OK ✗                              s₁  dir=(T,T,T) chk=(T,F,F)
   dir=(F,T,T) chk=(T,F,F)                  /                          \
                              NextHasNoPrefsDir                          NextHasPrefsDir
                                            /                              \
                           s₄ NOT_OK ✗                         s₃  dir=(T,T,T) chk=(T,T,F)
                        dir=(T,F,T) chk=(T,T,F)               /                        \
                                          NextHasNoJsonPrefs  /                          \ NextHasJsonPrefs
                                                             /                            \
                                              s₆ NOT_OK ✗                       s₅ OK ✓
                                           dir=(T,T,F) chk=(T,T,T)        dir=(T,T,T) chk=(T,T,T)

Safety theorems
----------------

.. list-table::
   :header-rows: 1
   :widths: 10 40 50

   * - ID
     - Statement
     - Role
   * - T_Inv
     - ``Spec ⇒ □ Inv``
     - Master inductive invariant (five conjuncts, eight cases).
   * - T1
     - ``Spec ⇒ □ TypeOK``
     - Type invariant is preserved.
   * - T2
     - ``Spec ⇒ □ ChainOrderCheck``
     - ``check`` flags respect step order.
   * - T3
     - ``Spec ⇒ □ Soundness``
     - A later check implies all earlier flags survived.
   * - T4
     - ``Spec ⇒ □ DisprovalImpliesChecked``
     - Any disproved flag was actually checked.
   * - T5
     - ``Spec ⇒ □ AtMostOneDisproved``
     - At most one flag is ``FALSE`` in ``directory``.
   * - T6
     - ``Spec ⇒ □[DirectoryMonotoneStep]_vars``
     - ``directory`` is monotone non-increasing.
   * - T7
     - ``Spec ⇒ □[CheckMonotoneStep]_vars``
     - ``check`` is monotone non-decreasing.
   * - T8
     - ``Spec ⇒ □ VerdictsExclusive``
     - ``OK`` and ``NOT_OK`` are disjoint (headline).

Scope and known limitations
----------------------------

* **JSON content validation** (required keys, legal value of
  ``"document class"``) is out of scope for 1.3.7 and will be the
  subject of the next kaizen step.
* **Liveness** (``Spec ⇒ <>(OK ∨ NOT_OK)``) is not proven. No fairness
  clause is present.
* **Atomicity**. The implementation makes one :func:`open` syscall.
  The file-system state between that call and the diagnostic chain on
  failure is unspecified. This is an accepted limitation under
  non-adversarial concurrent mutation.
