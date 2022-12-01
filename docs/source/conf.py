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


# conf.py
from importlib import import_module
from docutils  import nodes
from sphinx    import addnodes
from inspect   import getsource
from docutils.parsers.rst import Directive

# https://stackoverflow.com/questions/62253903/human-readable-iterables-in-sphinx-documentation/62253904#62253904
#
class PrettyPrintIterable(Directive):
    required_arguments = 1

    def run(self):
        def _get_iter_source(src, varname):
            # 1. identifies target iterable by variable name, (cannot be spaced)
            # 2. determines iter source code start & end by tracking brackets
            # 3. returns source code between found start & end
            start = end = None
            open_brackets = closed_brackets = 0
            for i, line in enumerate(src):
                if line.startswith(varname):
                    if start is None:
                        start = i
                if start is not None:
                    open_brackets   += sum(line.count(b) for b in "([{")
                    closed_brackets += sum(line.count(b) for b in ")]}")

                if open_brackets > 0 and (open_brackets - closed_brackets == 0):
                    end = i + 1
                    break
            return '\n'.join(src[start:end])

        module_path, member_name = self.arguments[0].rsplit('.', 1)
        src = getsource(import_module(module_path)).split('\n')
        code = _get_iter_source(src, member_name)

        literal = nodes.literal_block(code, code)
        literal['language'] = 'python'

        return [addnodes.desc_name(text=member_name),
                addnodes.desc_content('', literal)]

def setup(app):
    app.add_directive('pprint', PrettyPrintIterable)