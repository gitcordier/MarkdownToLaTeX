# Next Step

## Version

2.0.0

## Subject

MarkdownToLaTeX 1.0.0, formal specifications.

## Tasks

Users provides file preferences.ini. This file is parsed as a dictionary user_preference_.

The set (P) of user_preference_ keys MUST be a subset of LUALATEX

LUALATEX is recorded as specifications.functional.latex.keys.2.0.0.txt.

LUALATEX is the disjoint union of the subset LUALATEX_OPTIONS with the subset LUALATEX_CORE.

LUALATEX_CORE MUST be a subset of P.

P is accepted iff these two MUST contraints are satisfied.

The formal specification of these environment (LUALATEX and subsets) and behaviors (P) must be independent of the very content of LUALATEX. If LUALATEX changes, then the  above logic is not altered.

## Transient weakenings

For now markdown_to_latex(input) is the identity mapping.

## User intent and interactions with MarkdownToLaTeX 1.0.0.

### Introduction

We assume that the file preferences.ini already exists and is located at preferences/preferences.ini .

## Formal specification

See Section *References*

## Outputs

1. Preferences.2.0.0.tla,
2. specifications.formal.2.0.0.md: formal specifications, endorses Preferences.2.0.0.tla,

see Section Tasks.

## References

specifications.functional.latex.keys.2.0.0.txt
