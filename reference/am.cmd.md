# Run a command

Execute a command on a target element

## Usage

``` r
am.cmd(id, cmd = NULL, trgt = NULL, ...)
```

## Arguments

- id:

  A map widget from
  [am.init](https://helgasoft.github.io/amapro/reference/am.init.md) or
  a proxy from
  [am.proxy](https://helgasoft.github.io/amapro/reference/am.proxy.md)

- cmd:

  AMap command name string, like 'setFitView', 'setMapStyle', etc.

- trgt:

  A target's name string, or 'map' for the map itself.

- ...:

  command attributes from AMap API.  
  For AMap commands starting with 'get' there are two *amapro*
  attributes 'f' and 'r'.  
  'f' is an optional JS function to manipulate the data received,  
  'r' is the name of the Shiny variable receiving the data

## Value

A map or a map proxy

## Details

*am.cmd* provides interaction with the map.  
Commands are sent to the map itself, or to objects inside or outside
it.  
AMap built-in objects have predefined set of commands listed in the API.
Commands can modify an object (setZoom), but also get data from it
(getCenter).  
*amapro* introduces its own commands like *set*, *addTo* or *code*,
described in the Introduction.

## See also

[am.init](https://helgasoft.github.io/amapro/reference/am.init.md) code
example and Introduction

## Examples

``` r
if (interactive()) {
  # 'position' and 'content' are InfoWindow parameters from AMap API
  am.init() |> 
  am.cmd('set', 'InfoWindow', position=c(116.6, 40), content='Beijing')
  
  am.proxy("plot") |>
    am.cmd('getLayers', 'map',
           f= 'function(yy) { return yy.map(x => { return x.CLASS_NAME;}); }',
           r= 'result1')
}
```
