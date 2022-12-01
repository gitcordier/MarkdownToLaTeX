# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html
import os
import sys
from pathlib import Path

folder_package = Path(__file__).resolve().parents[2]
folder_src = os.path.join(folder_package, 'src')
sys.path.append(folder_src)
# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'MarkdownToLaTeX'
copyright = '2022, gitcordier'
author = 'gitcordier'
release = '0.0.1'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = []

templates_path = ['_templates']
exclude_patterns = []



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary'
]
python_use_unqualified_type_names = True

# END 