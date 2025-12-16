# Map Initialization

First command to build a map

## Usage

``` r
am.init(..., width = NULL, height = NULL)
```

## Arguments

- ...:

  attributes of map, see
  [here](https://lbs.amap.com/api/jsapi-v2/documentation#map).  
  Additional attribute *loca*(boolean) is to add a Loca.Container to the
  map.

- width, height:

  A valid CSS unit (like `'100%'`)

## Value

A widget to plot, or to store and expand with more features

## Details

Command *am.init* creates a widget with
[`createWidget`](https://rdrr.io/pkg/htmlwidgets/man/createWidget.html),
then adds features to it.  
On first use, *am.init* prompts for AMap API key. There is a temporary
*demo* mode when key is unavailable.

## Examples

``` r
if (interactive()) {
  ctr <- c(22.430151, 37.073011)
  tu <- paste0('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/',
                   'MapServer/tile/[z]/[y]/[x]')
  am.init( center= ctr, zoom= 10, pitch= 60, viewMode= '3D') |>
  am.control(ctype= 'ControlBar', position= 'RT') |>
  am.item('TileLayer', tileUrl= tu) |>
  am.item('Marker', position= ctr,
      icon= 'https://upload.wikimedia.org/wikipedia/commons/9/9d/Ancient_Greek_helmet.png'
  ) |>
  am.cmd('set', 'InfoWindow', name='iwin', content='This is Sparta') |>
  am.cmd('open', 'iwin', 'm$jmap', ctr)   # m$jmap is the map name in JavaScript
}
```
