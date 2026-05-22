# Specifications

## Version

2.0.2

## Conventions

### Scope: global

#### Sourcecode

- encoding: UTF-8
- EOL: \n
- indentation: space

### Markdown

#### Sourcecode

- width: exactly 96 (last character for EOL)
- indentation: 4-space

### TLA

#### Sourcecode

- width: exactly 96 (last character for EOL)
- indentation: 2-space

### Python

#### Sourcecode

- width: exactly 96 (last character for EOL)
- indentation: 4-space
- aesthetic convention: loops, if-elif statements must be closed with "#". Files are ended by a "# END" line (EOL-terminated).
- Sphinx documentation: Text must be indended (4-space shift with respect to opening and closing """), so that VSCode wraps it. Here is an example of comment:

  """
  EOL and 4-space shift.
  For each line.
  """

### LaTex

#### Sourcecode

- width: excactly 128 (last character for EOL)
- indentation: 2-space

## Package Layout

```
src/markdowntolatex/
│
├── __init__.py              # re-exports the top-level public API
│
├── constants/               # ← promoted from constants.py
│   ├── __init__.py          # re-exports everything below
│   ├── automaton.py         # constants consumed by automatons
│   ├── codepoint.py         # UTF-8 codepoints
│   ├── latex.py             # constanst consumed by component LATEX
│   ├── user.py              # constanst consumed by component USER
│   ├── metadata.py          # NAME, VERSION, DESCRIPTION, …
│   └── patterns.py          # String patterns, e.g. PATTERN_NO_ASCII
│
├── latex/                   # Abstraction for the LaTeX master document.
│
├── markdown/                # Abstraction for the Markdown input(s).
│
├── package_data/
│   ├── __init__.py          # re-exports everything below
│   ├── bash/                # Bash commands, e.g. "lualatex *tex"
│   ├── input/               # Inputs
│       └─ latex/            # Consumed by component LATEX  
│
├── user/                    # Abstraction for the User's
│   ├── __init__.py
│   ├── cli.py               # Definition of the CLI
│   ├── choice.py            # abstraction for the User's choice.
│   └── call.py              # Parsing and export functions
│
└── utilities.py             # get_file (public), imports helpers.
```

## Bibliography

Markdown 0.* API: https://markdowntolatex.readthedocs.io/en/latest/
