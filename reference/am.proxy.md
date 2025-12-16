# Shiny: create a map proxy

Create a proxy for an existing map in Shiny. It allows to add, merge,
delete elements to a map without reloading it.

## Usage

``` r
am.proxy(id)
```

## Arguments

- id:

  Map id from the Shiny UI

## Value

A proxy object to update the map

## Examples

``` r
if (interactive()) {
  demo(am.shiny)
}
```
