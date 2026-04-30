# Next Step

## Version

1.3.0

## Subject

MarkdownToLaTeX 1.0.0:

The obligations to be discharged by TLAPS / Isabelle; see Section *References*

Transient weakenings

For now markdown_to_latex(input) is the identity mapping.

## User intent and interactions with MarkdownToLaTeX 1.0.0.

### Introduction

The User works from a directory DIR.

Normal behavior (MUST_DO) : DIR contains a preferences.json file. Example: $DIR/preferences/preferences.json is the only legal path.

Abnormal behavior: NOT_MUST_DO.  NOT_MUST_DO truth value is NOT MUST_DO

Our current goal is to design a decision algorithm that computes MUST_DO XOR NOT_MUST_DO = TRUE.

To this end, it decides between MUST_DO and NOT_MUST_DO.

## Formal specification

See Section *References*

## Output

None. 

## References

Directory.tla.txt
specifications.formal.1.3.0.md
