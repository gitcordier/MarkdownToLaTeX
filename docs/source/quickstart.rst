Quick start
===========

Working directory layout
--------------------------

MarkdownToLaTeX reads all inputs from a single working directory ``DIR``.
The required layout is:

.. code-block:: text

   DIR/
   ├── preferences/
   │   └── preferences.json   ← required
   └── *.md                   ← your Markdown source files

Preferences file
----------------

``DIR/preferences/preferences.json`` configures the LaTeX output and must
contain the following keys at the top level:

.. code-block:: json

   {
       "author":   "Alan Berliner",
       "email":    "noreply@example.com",
       "name":     "An Example Document",
       "document class": {
           "class": "article",
           "size":  "10pt",
           "paper": "a4paper"
       },
       "main font": {
           "name":  "CMU Serif",
           "alias": "CMU"
       }
   }

.. note::

   JSON schema validation (required keys, legal values for
   ``"document class"``) is out of scope for version 1.0.0.

Working with Workspace
-----------------------

:class:`~markdowntolatex.workspace.Workspace` is the entry point for any
operation that touches ``DIR``. Construct it once, then call
:meth:`~markdowntolatex.workspace.Workspace.load_preferences`:

.. code-block:: python

   from pathlib import Path
   from markdowntolatex.workspace import Workspace

   ws = Workspace(Path("/my/project"))
   ws.load_preferences()                 # populates ws.pref_dict
   print(ws.pref_dict["author"])

Default working directory
~~~~~~~~~~~~~~~~~~~~~~~~~

Omitting ``path`` defaults to :func:`pathlib.Path.cwd`:

.. code-block:: python

   ws = Workspace()       # uses os.getcwd()
   ws.load_preferences()

Repeated loading
~~~~~~~~~~~~~~~~

:meth:`~markdowntolatex.workspace.Workspace.load_preferences` uses ``|=``
to merge into :attr:`~markdowntolatex.workspace.Workspace.pref_dict`.
Calling it again after editing ``preferences.json`` on disk refreshes
only the keys that changed:

.. code-block:: python

   ws.load_preferences()   # initial load
   # ... edit preferences.json on disk ...
   ws.load_preferences()   # merges updated values

Handling readiness errors
--------------------------

If ``DIR`` is not ready, :meth:`load_preferences` raises
:exc:`~markdowntolatex.workspace.Workspace.Error`. A single ``except``
clause handles all three failure modes; inspect
:attr:`~markdowntolatex.workspace.Workspace.Error.step` for a precise
diagnostic:

.. code-block:: python

   from markdowntolatex.workspace import Workspace

   try:
       ws = Workspace(Path("/my/project"))
       ws.load_preferences()
   except Workspace.Error as e:
       match e.step:
           case Workspace.Check.IS_DIR:
               print(f"No such directory: {e.path}")
           case Workspace.Check.HAS_PREFERENCES_DIR:
               print(f"Missing preferences directory: {e.path}")
           case Workspace.Check.HAS_JSON_PREFERENCES:
               print(f"Missing preferences file: {e.path}")

The three possible values of :attr:`~Workspace.Error.step`:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - ``step``
     - Meaning
   * - :attr:`~Workspace.Check.IS_DIR`
     - ``DIR`` does not exist or is not a directory.
   * - :attr:`~Workspace.Check.HAS_PREFERENCES_DIR`
     - ``DIR/preferences`` does not exist or is not a directory.
   * - :attr:`~Workspace.Check.HAS_JSON_PREFERENCES`
     - ``DIR/preferences/preferences.json`` does not exist or is not a
       regular file.

Python API
----------

The three top-level conversion functions follow the chain:

.. code-block:: python

   from pathlib import Path
   from markdowntolatex import markdown_to_latex, latex_to_pdf, markdown_to_pdf

   DIR = Path("/my/project")

   latex_source = markdown_to_latex(DIR)   # Markdown → LaTeX string
   latex_to_pdf(latex_source)              # LaTeX → PDF on disk
   markdown_to_pdf(DIR)                    # end-to-end shortcut

Command-line interface
-----------------------

.. code-block:: bash

   markdowntolatex /my/project             # Markdown → PDF
   markdowntolatex /my/project --output tex   # Markdown → LaTeX only
