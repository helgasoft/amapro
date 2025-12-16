# Introduction

Essential information, tips and tricks

## Details

Welcoming JavaScript library AMap into the world of R. AMap is an
advanced mapping library made in China and widely used there. It
features 2D/3D animation, supports a multitude of layers and markers,
data import, flyover playback, etc.  
Library *amapro* let you control AMap from R and Shiny. It uses AMap’s
native commands/parameters wrapped in just a few commands.

## Translation

AMap’s documentation is in Chinese and most links here make reference to
it. If you happen *not* to know Chinese, it is convenient to set your
browser to
[auto-translate](https://www.howtogeek.com/407924/how-to-turn-translation-on-or-off-in-chrome/).
This will help a little or a lot depending on the website/page
structure. One can also copy/paste text to [Google
translate](https://translate.google.com?sl=auto&tl=en).

## Installation

Install **amapro** from Github with
`remotes::install_github("helgasoft/amapro")` CRAN version also
available but usually outdated.

Run with the following commands  
`library(amapro); am.init()`  
A pop-up dialog will ask for an **API key** (shows once, will not be
repeated).  
API key is obtained through
[registration](https://console.amap.com/dev/id/phone), expecting you to
provide a Chinese phone number for SMS verification.  
How to get an API key if you reside out of China?

- ask a friend from China to help, or hire a local
  [freelancer](https://www.truelancer.com/freelancers-in-china)

- search the web for a shared key

- use a temporary Chinese phone number from sites like *sms24.me*,
  *turtle-sms.xyz*, etc. However most are probably blacklisted as the
  registration page shows them as *‘already registered’*.

- select temporarily the ‘demo’ option, without guarantee to work in the
  long run

## Shiny Demo

Interactive, hands-on showcase of many library features. Activate with
the following command:  
`library(amapro); demo(am.shiny)`

## API links

*amapro* is based on version 2.0 of AMap (JSAPI v2.0). “API”
auto-translates as “Reference book” in web menus.

### AMap

The base library with optional plugins. Most important links are

- [Summary](https://lbs.amap.com/api/jsapi-v2/summary/)

- [Guide](https://lbs.amap.com/api/jsapi-v2/guide/abc/quickstart)

- [API](https://lbs.amap.com/api/javascript-api-v2/documentation)
  documentation, good auto-translation

- [Examples](https://lbs.amap.com/demo/list/jsapi-v2) - live demos

### LOCA

AMap extension with enhanced 3D features. In *amapro* it is invoked with
a parameter - `am.init(loca=TRUE, ...)`. The documentation
auto-translates well in the browser.

- [Intro](https://lbs.amap.com/api/loca-v2/intro)

- [API](https://a.amap.com/Loca/static/loca-v2/doc/html/index.html)
  documentation

- [Examples](https://lbs.amap.com/demo/loca-v2/demos/) - live demos

## Commands

Controlling map and elements is done by sending AMap commands to them.
Commands can be chained with the pipe operator \|\> or %\>% and are
executed sequentially in the order received.  
Example: `am.cmd('setAngle', 'carIcon', -90)`  
*amapro* uses native AMap commands and introduces these *additional*:

- **set** - create new element

  - with *name*: add new global JS object outside the map  
    `am.cmd('set', 'VectorLayer', name='e$layer1')`

  - without *name*: add new element to map  
    `am.cmd('set', 'e$marker1', position= c(116.478, 39.998))`

- **addTo** - append one existing JS object to another by name  
  `am.cmd('addTo', 'e$layer1', 'e$marker1')`

- **var** - set a JavaScript variable  
  `am.cmd('var', 'e$myOpacity', 0.8)`

- **code** - execute JavaScript code  
  `am.cmd('code', 'alert("I am JS");')`

AMap commands starting with ‘**get**’ return data from the map or
related objects. Put the data in a Shiny input variable by setting its
name in parameter **r**.  
Example: `am.cmd('getCenter', 'map', r='inShiny1')`  
Above command will update *input\$inShiny1* with the Lng/Lat coordinates
of the map center.

## Events

Events could be defined for map and elements. All types of instances use
**on/off methods** to bind and remove events.  
Events are set in attribute **on**(or **off**) as a list of lists. Each
event is a separate list with event name in **e**, a JS function **f**
and optionally a query **q**. Example:

    am.init(center= c(116.475, 39.997), zoom= 17,
            on= list(list(e= 'complete',
                          f= "function() {alert('loaded!');}")) )

on/off events without *name* are ignored, except for the map itself (as
above example).  
JavaScript function *Shiny.setInputValue()* can be used to send data
back to Shiny.

## Limitations

- only one map is created by *am.init* per session. It is a JS global
  called ‘m\$jmap’.

- AMap command
  [addTo](https://a.amap.com/jsapi/static/doc/index.html#controladdto)
  is overwritten by *amapro* and cannot be used.

- most **built-in** AMap tile layers (Satellite, Traffic, Roads) are
  limited to China only. However, with command *am.item(‘TileLayer’)*,
  one can use any [Leaflet
  provider](https://leaflet-extras.github.io/leaflet-providers/preview/)
  for worldwide coverage.

- AMap built-in [map
  layers](https://lbs.amap.com/api/jsapi-v2/guide/layers/official-layers)
  are [GCJ-02
  coded](https://en.wikipedia.org/wiki/Restrictions_on_geographic_data_in_China)
  and coordinates collected on them will display incorrectly in Leaflet
  or other WGS-84 based maps, and vice-versa. They need to be
  [converted](https://lbs.amap.com/api/jsapi-v2/guide/transform/convertfrom).
  Conversion is available through function
  [convertFrom](https://lbs.amap.com/api/jsapi-v2/documentation#convertfrom).

- the **supported AMap plugins** are: ControlBar, Scale, ToolBar,
  MoveAnimation, MouseTool, HeatMap, GeoJSON, ElasticMarker.

- AMap ecosystem is vast, **unsupported** features and plugins include:
  ‘BesizerCurve’, ‘MarkerCluster’, ‘HawkEye’,
  [IndoorMap](https://lbs.amap.com/demo/javascript-api/example/indoormap/indoormap/),
  [CustomLayer](https://lbs.amap.com/demo/javascript-api/example/selflayer/cus-svg),
  ‘GLCustomLayer’, ‘DistrictLayer’, ‘LayerGroup’, all editors like
  ‘PolygonEditor’,‘Webservice’, ‘Search(AMap.Autocomplete,
  AMap.PlaceSearch)’, ‘Geocoding(AMap.Geocoder)’, Route planning, other
  services(weather, districts, etc.), positioning, utilities.

- most **Loca** elements are supported, but not all have been tested.
  Latest *AmbientLight*, *DirectionalLight* and *PointLight* objects are
  not supported, but parameters *ambLight*, *dirLight* and *pointLight*
  accomplish the same.

- Loca events are not supported yet.

## Tips

- all named objects created in JS are [global
  variables](https://developer.mozilla.org/en-US/docs/Glossary/Global_object)
  (*window.name*). Good practice is to use a name prefix (m\$) to avoid
  overwriting accidentally external variables.

- API attributes could be set to a JS function instead of a value.
  Function is defined as a string starting with word “function”.

- usually WMS/WMTS tiles come from external servers and may present a
  CORS problem - browser refusal to load. One can install a small
  [extension in
  Chrome](https://chrome.google.com/webstore/detail/allow-cors-access-control/lhobafahddgcelffkeicbaginigeejlf)
  or
  [Firefox](https://addons.mozilla.org/en-US/firefox/addon/access-control-allow-origin/)
  to fix this problem manually inside the browser.

- AMap has several predefined [Map
  styles](https://lbs.amap.com/api/jsapi-v2/guide/map/map-style/). Could
  be set in map options with *mapStyle*.

- *amapro* silent errors are collected in the browser Console. Press key
  **F12** to open the dev.environment, then open tab “Console” to view
  them.

- *am.init* has a *debug* (boolean) parameter, results are displayed in
  the browser Console

- Chrome/Firefox extensions may interfere with map presentation (like
  ‘uBlock’)
