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

project   = "MarkdownToLaTeX"
copyright = "Jean-Gabriel Cordier"
author    = "Jean-Gabriel Cordier"
release   = "1.0.0"
version   = "1.0"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autodoc",       # Pull docstrings from source.
    'sphinx.ext.autosummary',
    "sphinx.ext.napoleon",      # Google-style docstring support.
    "sphinx.ext.viewcode",      # [source] links on API pages.
    "sphinx.ext.intersphinx",   # Cross-links to Python stdlib.
    "sphinx_copybutton"       # Copy-to-clipboard on code blocks.
]
python_use_unqualified_type_names = True

napoleon_google_docstring = True
napoleon_numpy_docstring  = False
napoleon_use_param        = True
napoleon_use_rtype        = True
napoleon_preprocess_types = True

autodoc_member_order    = "bysource"
autodoc_typehints       = "description"
autodoc_class_signature = "separated"

intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
}


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

#html_theme = 'sphinx_rtd_theme'
html_theme = "furo"

html_theme_options = {
    "sidebar_hide_name": False,
    "navigation_with_keys": True,
    "light_css_variables": {
        "color-brand-primary": "#1565C0",
        "color-brand-content": "#1565C0",
        "color-api-name":      "#2E7D32",
        "color-api-pre-name":  "#2E7D32",
    },
    "dark_css_variables": {
        "color-brand-primary": "#64B5F6",
        "color-brand-content": "#64B5F6",
        "color-api-name":      "#81C784",
        "color-api-pre-name":  "#81C784",
    },
}

html_title       = "MarkdownToLaTeX 1.0.0"
html_static_path = ["_static"]

templates_path   = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]


# END 