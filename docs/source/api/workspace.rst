``workspace`` — Workspace readiness
=====================================

.. automodule:: markdowntolatex.workspace
   :no-members:

The module implements the three-step file-system readiness chain of
``Directory.1.3.7.tla`` as a single stateful class.

----

.. autoclass:: markdowntolatex.workspace
   :members:
   :undoc-members:
   :special-members: __init__
   :show-inheritance:

----

Formal correspondence
---------------------

Every public member of :class:`Workspace` maps to a TLA⁺ construct in
``Directory.1.3.7.tla``:

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - TLA⁺ entity
     - Python construct
   * - ``directory : Knowledge``
     - implicit; encoded in control flow (raise on first failure)
   * - ``check : Knowledge``
     - implicit; encoded in program counter (which ``if`` branch runs)
   * - ``Init``
     - :meth:`Workspace.__init__` — ``pref_dict = {}``
   * - ``NecessaryConditionDir``
     - control reaches :meth:`load_preferences` with no prior failure
   * - ``NextHasDir`` / ``NextHasNoDir``
     - :func:`open` succeeds / ``self.path.is_dir()`` returns ``False``
   * - ``NextHasPreferencesDir`` / ``NextHasNoPreferencesDir``
     - fall-through to step 2 / ``self.pref_dir.is_dir()`` returns ``False``
   * - ``NextHasJsonPreferences`` / ``NextHasNoJsonPreferences``
     - :func:`open` returns a file / ``self.pref_file.is_file()`` returns ``False``
   * - ``OK``
     - :meth:`load_preferences` returns; :attr:`pref_dict` is populated
   * - ``NOT_OK``
     - :exc:`Workspace.Error` is raised with a witness :class:`~Workspace.Check`
   * - ``VerdictsExclusive`` (T8)
     - enforced by the Python runtime: ``return`` and ``raise`` are
       mutually exclusive
