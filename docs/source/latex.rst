LaTeX
=====

.. autosummary::
   :toctree: generated

.. automodule:: markdowntolatex.latex
   :members:
   :undoc-members:

The LaTeX part. **Document** is an abstraction for a *document*. 
A **Document** is instantiated from a preferences file. 

**IF** **preferences** contains a single **JSON** file, **THEN** such file is the preferences file.

**ELIF** **preferences** contains more than one **JSON** file, **THEN** raise **FileNotFoundError**.

**ELIF** **preferences** contains no **JSON** file, **THEN** look for *user_preferences* input:

**IF** input is in **{None, ''}**, **THEN** use the default preferences.

   **ELIF** input is a valid path, **THEN** preferences are set.

   **ELSE** raise **FileNotFoundError**


.. automodule:: markdowntolatex.latex.document
   :members:
   :undoc-members:
