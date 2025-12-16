# Map to JSON

Convert map elements to JSON string

## Usage

``` r
am.inspect(wt, json = TRUE, ...)
```

## Arguments

- wt:

  An `amapro` widget as returned by
  [am.init](https://helgasoft.github.io/amapro/reference/am.init.md)

- json:

  Boolean whether to return a JSON, or a `list`, default TRUE

- ...:

  Additional arguments to pass to
  [toJSON](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)

## Value

A JSON string if `json` is `TRUE` and a `list` otherwise.

## Details

Must be invoked or chained as last command.  

## Examples

``` r
if (interactive()) {
  am.init(viewMode= '3D', zoom= 10, pitch= 60) |>
    am.control(ctype= 'ControlBar', position= 'RT') |>
    am.inspect()
}
```
