# Add Item

Add an item to a map

## Usage

``` r
am.item(id, itype, ...)
```

## Arguments

- id:

  A valid widget from
  [am.init](https://helgasoft.github.io/amapro/reference/am.init.md)

- itype:

  A string for item type name, like 'Marker'

- ...:

  attributes of item

## Value

A map widget to plot, or to save and expand with more features

## Details

To add an item like Marker, Text or Polyline to the map

## See also

[am.init](https://helgasoft.github.io/amapro/reference/am.init.md) code
example

## Examples

``` r
if (interactive()) {
  am.init() |> am.item('Marker', position=c(116.6, 40))
}
```
