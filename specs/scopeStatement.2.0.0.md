# MarkdownToLaTeX 1.0.0: scope statement

## Version

2.0.0

## Introduction

MarkdownToLaTeX is an application that translates markdown input (MARKDOWN): final output is a PDF (PDF) equivalent of I and intermediary output is a LaTeX (LATEX) equivalent of MARKDOWN.

PDF is made from LATEX with LuaLateX. LATEX is the main output to consider. Designing the parsing that turns MARKDOWN into LATEX is the core of the current project.

## Release: scope, limitations, byproducts

### License

MIT

### OS

Unix family.

### Global Limitations

Only Unix EOL ("\n"), Unix path naming (separator must be "/") and UTF-8 encoding are relevant.

### byproducts

A complete Sphinx documentation must be published on readthedocs.io .

## What MarkdownToLaTeX 1.0.0 must do, for someone who runs it

The User installs the package via `pip install markdowntolatex`, on Python >= 3.11, with no third-party runtime dependencies. They then convert documents along the chain

```
Markdown   →   LaTeX   →   PDF
```

through one of two surfaces.

### Surface 1 — Python API (programmatic use)

Three top-level functions, each consuming the previous stage of the chain:

- `markdown_to_latex(input)` — Markdown source (string or path) returns a LaTeX source string.
- `latex_to_pdf(input)` — LaTeX source returns a compiled PDF written to disk.
- `markdown_to_pdf(input)` — end-to-end pipeline of the two above.

### Surface 2 — Command-line binary

Invoked as `markdowntolatex <input.md> [options]`, the binary writes a `.tex` file or a `.pdf` file to disk, according to the requested pipeline. Options select the LaTeX engine, the user-preferences INNIfile, and the output path.

### Faithful Markdownn translation

The LaTeX output preserves the *structure* of the Markdown input — headings, paragraphs, ordered and unordered lists, emphasis, code blocks, inline and display math — but does not attempt to mimic any rendered HTML appearance. Math written in `$ … $` and `$$ … $$` passes through unchanged.

### Acceptance signal

The Mathsheet PDF was originally built with 0.0.2. The 1.0.0 rewrite must, at minimum, rebuild it (or its 1.0.0-era successor) end-to-end without manual post-editing.

### Assumptions and limitations

The User workspace is a given input. We do not expect it to change / to be under adversial attacks while MarkdownToLaTeX is being run.

## Features

1. **Default LaTeX engine**: MarkdownToLaTeX 1.0.0 will only deal with LuaLaTex. XelateX is deprecated.
2. **Markdown features in scope**: Structure (part, chapter, section, subsection, subsubsection, paragraph).
3. **CLI ergonomics**: filenames and options (from flags)
4. **files and directories**: the User uses a fixed work directory, say DIR. All inputs and outputs are in DIR.
5. **Inputs sorting**: DIR must contain a PROJECT file that enlists all Markdown inputs and specifies the reading order.
6. **output configuration, LaTeX settings**: Provided by a INI file that MUST be named preferences.ini . Path MUST be $DIR/preferences/preferences.ini
7. **Preferences schema.** What keys does `preferences.ini` accept, and what are the defaults: see preferences file section below

## Preferences file

A preferences.ini MUST have the same keys than the default preferences.ini, see below:

preferences.ini

    {
            "author": "Alan Berliner",
            "email": "noreply@example.com",
            "name": "An Example Document",
            "document class":{
                "class": "article",
                "size": "10pt",
                "paper": "a4paper"
            },
            "main font": {
                "name": "CMU Serif",
                "alias": "CMU"
            }
        }
