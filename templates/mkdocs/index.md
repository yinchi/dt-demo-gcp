# Welcome to MkDocs

For full documentation visit [mkdocs.org](https://www.mkdocs.org).

This MkDocs template is based on <https://github.com/yinchi/yinchi.github.io>; refer to it for a fuller example of MkDocs usage.

## Commands

* `mkdocs new [dir-name]` - Create a new project.
* `mkdocs serve` - Start the live-reloading docs server.
* `mkdocs build` - Build the documentation site.
* `mkdocs -h` - Print help message and exit.

## Project layout

```text
mkdocs.yml    # The configuration file.
docs/
    index.md  # The documentation homepage.
    ...       # Other markdown pages, images and other files.
```

## Extensions demo

### Admonitions

!!! note

    The [`admonition` extension](https://squidfunk.github.io/mkdocs-material/reference/admonitions/) is installed.

### Definition Lists

The [`def_list` extension](https://python-markdown.github.io/extensions/definition_lists/) is installed. Example:

Apple
:   Pomaceous fruit of plants of the genus Malus in
    the family Rosaceae.

Orange
:   The fruit of an evergreen tree of the genus Citrus.

### Syntax highlighting

See the [Mkdocs documentation for code blocks](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/).  Example:

```py
print("Hello World!")
```

[Inline highlighting](https://facelessuser.github.io/pymdown-extensions/extensions/inlinehilite/) is also supported: `#!py3 import pandas as pd`

### MathJax

Example $\LaTeX$ formula:
$$
\int x\ \mathrm{d}x=\frac{1}{2}x^2
$$

Note that for display equations, you may need to put the double-dollar signs on their own lines for the extension to detect them properly.

### Other extensions

The following extensions are also installed:

* [Attribute Lists](https://python-markdown.github.io/extensions/attr_list/)
* [SmartSymbols](https://facelessuser.github.io/pymdown-extensions/extensions/smartsymbols/)
  * also, `smarty`
