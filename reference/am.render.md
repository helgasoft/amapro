# Shiny: render a map

This is the initial rendering of a map in the UI.

## Usage

``` r
am.render(wt, env = parent.frame())
```

## Arguments

- wt:

  An `amapro` widget to generate the chart.

- env:

  The environment in which to evaluate `expr`.

## Value

An output or render function that enables the use of the widget within
Shiny applications.

## See also

[am.proxy](https://helgasoft.github.io/amapro/reference/am.proxy.md) for
example,
[`shinyRenderWidget`](https://rdrr.io/pkg/htmlwidgets/man/htmlwidgets-shiny.html)
for return value.
