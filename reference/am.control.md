# Add Control

Add a Control to a map.

## Usage

``` r
am.control(id, ctype = NULL, ...)
```

## Arguments

- id:

  `amapro` id or widget from
  [am.init](https://helgasoft.github.io/amapro/reference/am.init.md)

- ctype:

  A string for name of control, like 'Scale','ControlBar','ToolBar'.

- ...:

  A named list of parameters for the chosen control

## Value

A map widget to plot, or to save and expand with more features.

## Details

controls are ControlBar, ToolBar and Scale.  
[Parameters](https://a.amap.com/jsapi/static/doc/20210906/index.html?v=2#control)
could be position or offset.  

## See also

[am.init](https://helgasoft.github.io/amapro/reference/am.init.md) code
example

## Examples

``` r
if (interactive()) {
  am.init() |> am.control("Scale")
}
```
