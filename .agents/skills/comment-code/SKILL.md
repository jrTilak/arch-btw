---
name: comment-code
description: Add meaningful explanatory comments when creating or editing code, scripts, and configuration files, or when asked to improve their readability through comments.
---

# Meaningful Code and Configuration Comments

Write code and configuration so a reader can understand their purpose, behavior,
and customization points without reconstructing the author's intent. Prefer
multiple useful comments across a file over a single vague introductory comment.
Comment new or modified work within the user's requested scope; do not turn an
ordinary change into an unrelated repository-wide commenting pass.

## What to explain

- Describe a file's role and when it is loaded or executed when that context is
  not apparent from the file itself.
- Introduce logical sections and explain functions or handlers with non-obvious
  responsibilities, inputs, outputs, or side effects.
- Explain why a decision exists: precedence, persistence, compatibility,
  ordering, performance, or an important constraint.
- Place comments near tricky branches, validation, quoting, error handling,
  external calls, and assumptions that a maintainer needs to preserve.
- In configuration, explain meaningful options, accepted values, units, defaults,
  and interactions with overrides or other settings where useful. Distinguish
  sample values from values actually enforced or applied.

Use short inline comments for local facts and several-line comments when a
workflow or rationale needs explanation. Do not impose a comment quota or
annotate every line: omit comments that merely repeat names or obvious syntax.
Avoid generic boilerplate, speculative claims, and explanations of abandoned
approaches. Prefer precise language grounded in the actual implementation.

## Space logical sections clearly

Separate logical sections with a blank line so their purpose and boundaries are
easy to scan. Keep an introductory comment directly above the code it explains,
with a blank line before the combined comment-and-code block. Within functions,
separate distinct steps such as reading, validating, applying, and reporting.

Use consistent indentation and spaces around operators according to the
language's conventions. Expand cramped multi-command lines and branches when
that improves readability. Keep closely related statements together; do not
insert blank lines between every statement or change whitespace inside strings,
templates, or syntax-sensitive configuration values.

## Preserve behavior and accuracy

Use the language's or format's supported comment syntax. Never insert comments
into strict JSON or other formats that prohibit them; keep explanations in
existing adjacent documentation when appropriate. Do not change formats or add
dependencies just to enable comments.

Preserve useful existing comments and update them alongside changed behavior.
Do not claim validation, idempotency, automatic reloads, or persistence unless
the implementation provides them. Keep comment text separate from strings,
templates, generated output, and parser-sensitive directives unless the comment
is intentionally part of that artifact.

After editing, check that comments match the behavior and that the affected code
or configuration remains syntactically valid using available relevant checks.
Report commenting changes without suggesting functional changes were made when
only documentation changed.
