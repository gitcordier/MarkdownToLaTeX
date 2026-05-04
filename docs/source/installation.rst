Installation
============

Requirements
------------

* Python ≥ 3.14
* LuaLaTeX (TeX Live ≥ 2023)
* Unix family OS

No third-party Python runtime dependencies are required.

From PyPI
---------

.. code-block:: bash

   pip install markdowntolatex

Development install
-------------------

.. code-block:: bash

   git clone https://github.com/gitcordier/markdowntolatex
   cd markdowntolatex
   pip install -e ".[docs,dev]"

Build these docs locally
------------------------

.. code-block:: bash

   pip install -e ".[docs]"
   cd docs && make html
   open _build/html/index.html
