# Documentation with MkDocs

The developer documentation you are reading now is implemented using [MkDocs](https://www.mkdocs.org).  When building the Docker image using the `Dockerfile`, we use a multi-step build:

1. Copy the Markdown files and asset files to the builder container.
2. Compile the Markdown files into HTML with `mkdocs build`.
3. Copy the static files to the final image, which uses a tiny static webserver.

For local development, we can simply run MkDocs uncontainerized, using: `uv run mkdocs serve`.

## Project layout

```text
mkdocs.yml    # The configuration file.
docs/
    index.md  # The documentation homepage.
    ...       # Other markdown pages, images and other files.
```

!!! warning

    Only pages listed in the `nav` section of `mkdocs.yml` will be shown in the rendered output.

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
