#   am.shiny.R
library(amapro); library(shiny); library(shinyjs)

# ------ data ------
# maps with worldwide coverage
tile1 <- 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/[z]/[y]/[x]'
tile2 <- 'https://{a,b,c}.tile.openstreetmap.org/[z]/[x]/[y].png'
# pulsed <- 'https://a.amap.com/Loca/static/static/orange.png'
labMark <- 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/IE_road_sign_W-101.svg/64px-IE_road_sign_W-101.svg.png'
pary <-  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Blason_paris_75.svg/436px-Blason_paris_75.svg.png'
bfish <- 'https://upload.wikimedia.org/wikipedia/commons/3/34/BlueFish3.png'
mark1 <- 'https://upload.wikimedia.org/wikipedia/commons/3/3c/Map_marker_icon_%E2%80%93_Nicolas_Mollet_%E2%80%93_Parking_Bicycle_%E2%80%93_Transportation_%E2%80%93_Default.png'    
mark2 <- 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Map_marker_icon_%E2%80%93_Nicolas_Mollet_%E2%80%93_Bike_rising_%E2%80%93_Sports_%E2%80%93_Default.png'
pin <- 'https://upload.wikimedia.org/wikipedia/commons/3/37/Icon_location.png'
ycar <- 'https://raw.githubusercontent.com/helgasoft/amapro/master/inst/figures/ycar.png'
geoJson3D <- 'https://raw.githubusercontent.com/helgasoft/amapro/master/inst/figures/paris3geo.json'

cntxtMenu <- paste("<div class='context-menu-content'><ul class='context_menu'>",
   "<li onclick='m$jmap.zoomOut()'>Zoom Out</li>",
   "<li onclick='m$jmap.zoomIn()'>Zoom In</li>",
   "<li onclick=\"window.navigator.clipboard.writeText('c('+contextMenuPositon.lng+','+contextMenuPositon.lat+'),');\">lng/lat copy</li>",
   "<li onclick='var marker= new AMap.Marker({ map:m$jmap, position:contextMenuPositon, icon:\"",pin,"\", offset:[-10, -28] });'>+marker</li></ul></div>")
pcenter <- c(2.296404,48.857024)  # Paris
hsr <- list(c(2.295470,48.854681),c(2.292999,48.856290),c(2.293539,48.856656),c(2.296094,48.855058),c(2.296413,48.854864), c(2.297666,48.855747))
tmp <- lapply(hsr, function(x) { paste0('[',x[1],',',x[2],']') })
hjs <- paste('[', paste(unlist(tmp), collapse=','), '];')
carAnim <- paste("var loopy=null, flag = false;  // track playback
  var lineArr=",hjs, 
  "window.m$carAnimation = function m$carAnimation() {
      aniMarker.moveAlong(lineArr, { duration: 3000 });
      lineArr= lineArr.reverse();
  };
  window.m$togglePlay = function () {
    if (flag) aniMarker.stopMove();
    else {
      if (!aniMarker.markerAnimation || aniMarker.markerAnimation.getClips().length==0) 
        m$carAnimation();
  	  else
    		aniMarker.resumeMove();
  	}
  	flag = !flag; }"
)
glnglat <- list(c(2.290412,48.863673),c(2.292779,48.862115),c(2.288930,48.859023),c(2.289799,48.860950),c(2.290633,48.861634),c(2.289015,48.861835),c(2.287414,48.860088),c(2.286171,48.860614),c(2.287397,48.862586))
gjson <- list(type= "FeatureCollection", features= list(
  list(type= "Feature", properties= list(id="44", name="Trocadero"), 
       geometry= list(type= "Polygon", coordinates= as.matrix(list(glnglat)))
  )))
plu <- list(c(2.295343,48.857707), c(2.3009,48.851123), c(2.305521,48.854276))
pfl <- list()
for(j in 1:length(plu)) {
  i <- j-1; if (i==0) i <- length(plu)
  pfl <- append(pfl, list(list(type= "Feature", geometry= list(type= "LineString", 
      coordinates= list( c(plu[[j]][1], plu[[j]][2]), c(plu[[i]][1], plu[[i]][2]))) )
  )) }
pfl <- list(type= "FeatureCollection", features= pfl)

# pfc <- list()  # for pulsating Loca.ScatterLayer
# for(i in 1:length(glnglat)) 
#   pfc <- append(pfc, list(list(type= "Feature", geometry= list(type= "Point", 
#                       coordinates= c(glnglat[[i]][1], glnglat[[i]][2]))) 
#   ))
# pfc <- list(type= "FeatureCollection", features= pfc)

flylist <- function(cen, rot, zum, pit) {
  # params = current center,rotation,zoom and pitch before flyover
  # flight is always to Trocadero and back
  speed <- 0.5
  list(
  list(center= list(value= c(2.287397,48.862586), control= list(cen, c(2.287397,48.862586)), timing= c(0, 0, 1, 1),duration=5000 / speed),
       pitch= list(value=80,control=list( c(0, pit), c(1, 80)),timing= c(0, 0, 1, 1), duration=5000 / speed),
       zoom= list(value=18,control= list(c(0, zum), c(1, 18)),timing= c(0, 0, 1, 1),duration=5000 / speed),
       rotation= list(value=rot+260,control= list(c(0, rot+20), c(1, rot+260)),timing= c(0, 0, 1, 1),  duration=6000 / speed)),
  list(center= list(value=cen,control= c(c(2.287397,48.862586), cen),timing= c(0, 0, 1, 1),duration=4000 / speed),
       pitch=list(value=pit, control= list(c(0, 80), c(1, pit)),timing= list(0, 0, 1, 1),duration=4000 / speed),
       zoom= list(value=zum, control= list(c(0, 18), c(1, zum)),timing= c(0, 0, 1, 1),duration=4000 / speed),
       rotation= list(value=rot+360,control= list(c(0, rot+260), c(1, rot+360)),timing= c(0, 0, 1, 1),duration=4000 / speed))
  )
}
CM.style <- " /* style for context menu */
ul {
  list-style-type: none;
  margin: 0;
  padding: 3px;
  overflow: hidden;
  background-color: #ddd; opacity: 0.7; }
li { color: #092b36; opacity: 0.9;}
li:hover {  background-color: #eee; }
label{ float:left; }
#btnFly {padding:4px;}"
getcmd <- HTML(paste('Run AMap',tags$a(href="https://lbs.amap.com/api/jsapi-v2/documentation#map", "get commands", target='_blank')))

# ------ UI ------
ui = fluidPage( 
  theme= bslib::bs_theme(bootswatch='solar'), # https://bootswatch.com/solar/
  useShinyjs(), 
  tags$head(
    tags$script(carAnim),
    tags$style(HTML(CM.style)) ),
  
  fluidRow(column(12, align= "center", 'amapro demo')),
  fluidRow(
    column(12, div(style= 'margin-bottom:15px;', 
                   am.output("plot", height='70vh')) )),
  fluidRow(
    column(1, checkboxInput('isIcon', 'Icon', value=FALSE)),
    column(1, checkboxInput("isMarks", "Marks", value=FALSE)),
    column(2, checkboxInput('isHeat', 'Heatmap', value=FALSE)),
    column(2, checkboxInput('isCar', 'Start/Stop Car', value=FALSE)),
    column(1, checkboxInput('isLoLay', 'Loca 3D', value=FALSE)),
    column(4, '+ ',actionButton('btnFly', '\U1F985 Flyover', title='\u2714 3D to enable, pan map to restart'))
  ),
  fluidRow(
    column(1, HTML("<b>Layers</b>")),
    column(1, checkboxInput('isTile', 'Base', value=FALSE)),
    column(2, checkboxInput('isWms', 'WMS', value=FALSE)),
    column(2, checkboxInput('isOver', 'Overay', value=FALSE))
  ),
  fluidRow(
    column(5, HTML("Use <b>mouse</b> to "), 
           #div( style="display: inline; padding-left:50px;"),
           actionButton("isCircles", "Draw"), " multiple circles, then ", 
           actionButton("isCstop", "Remove All")),
    column(6, div("\u25BA Right-click map for context menu"),
              div("\u25BA Hover above red polygon for tooltip") )),
  fluidRow(
    column(2, textInput('getsom',getcmd, value='getCenter', width='200px', placeholder='get command for map')),
    column(1, br(), actionButton("goLL", "Run")),
    column(2, br(), div( style="display: inline; padding-left:30px;"),
           actionButton("getit", "GetLayers") ),
    column(2, br(), actionButton("info", label=tags$img(src ="https://img.icons8.com/metro/2x/info.png", alt='Help', width= '30')) ) ),
  fluidRow( column(12, textOutput('out1')  ))
)

# ------ server ------
server = function(input, output, session){
  
  rv <- reactiveValues(isLoaded=FALSE, doneHito=FALSE, doneWMS=FALSE,
                       bbCaller=NULL)         # per CRAN requirements
  # doneHito <- doneWMS <- isLoaded <- FALSE  # easy way
  # bbCaller <- NULL
  observe({ toggleState("btnFly", input$isLoLay) })
  onclick("isCar", function() { runjs('m$togglePlay()') })
  observeEvent(input$mapLoaded, { rv$isLoaded <- input$mapLoaded; })
  
  output$plot <- am.render({
    am.init(
      loca= TRUE,
      viewMode= '3D', showBuildingBlock= FALSE,
      pitchEnable= TRUE,  # dragEnable= FALSE, rotateEnable= FALSE,
      center= pcenter, zoom= 16, pitch= 60, #skyColor= '#33216a', 
      on= list(
        #list(e='zoomend',    f="function() {
        #    console.log('Current zoom level:'+this.getZoom()+' Pitch '+this.getPitch()); }"),
        list(e='rightclick', f="function (e) { 
             contextMenu.open(m$jmap, e.lnglat); contextMenuPositon = e.lnglat; }"),
        list(e='complete',   f="function (e) {
             Shiny.setInputValue('mapLoaded', true, {priority:'event'});}")
      )
    ) |>
    am.control('ControlBar', position= 'RT') |> 
    am.control('ToolBar', liteStyle= FALSE) |>
    am.control('Scale') |>
    am.item('TileLayer', name='tileLay', tileUrl= tile1, zooms= c(3, 20) ) |>
    am.item('LabelMarker', name='labMark',
      position= pcenter +0.005,
      icon= list( image= labMark, anchor= 'bottom-center' ),
      text= list(content= 'Icon',
                 direction= 'right',
                 style=list( fontSize= 15, fillColor= 'magenta'))
    ) |>
    
    am.item('Text', name='gjText', 
            text='GeoJSON', position= glnglat[[1]], offset= c(5,10),
            style=list(color='yellow', `background-color`='transparent',
                       `font-size`='20px', `border-width`=0 ) ) |>
    am.item('GeoJSON', name= 'mygjson', geoJSON= gjson,
            getPolygon= "function(geojson, lnglats) {
      var area = AMap.GeometryUtil.ringArea(lnglats[0]); //console.log(area);
      return new AMap.Polygon({path: lnglats, fillOpacity: 0.3, strokeWeight:2,
                    strokeColor:'magenta', fillColor:'red', zIndex:25}); }",
        on= list(
          list(e='mousemove', f="function(e) {gjText.show(); gjText.setPosition(e.lnglat);}"),
          list(e='mouseout',  f="function(e) {gjText.hide(); }")
        ) 
    ) |>
    am.item('Polyline', name='passed',
            strokeColor= 'green', strokeWeight= 6, zIndex=22) |>
    # icons should be named and stay outside the map
    am.cmd('set', 'Icon', name='m$cari', image= ycar,
           size= c(30,66), imageSize= c(15,33) ) |>
    am.item('Marker', name= 'aniMarker', icon= 'm$cari',
        position= hsr[[1]], offset=c(-5,-5),
        on= list(list(e='moving',
                     f="function(e) { 
        passed.setPath(e.passedPath);
        m$jmap.setCenter(   e.target.getPosition());
        m$jmap.setRotation(-e.target.getOrientation()); }"))
    ) |>
    am.item('Polyline',        # car path blue line
            showDir= TRUE, zIndex= 12,  # 12 < 22 =passed on top
            strokeColor= '#28F', strokeWeight= 6,
            path= hsr 
    ) |>
    
    am.cmd('set', 'ContextMenu', name='contextMenu', 
           isCustom= TRUE, content= cntxtMenu) |> 
    am.cmd('set', 'VectorLayer', name='m$vector') |>
    am.cmd('addTo', 'map', 'm$vector') |>
    #am.cmd('setRotation', 'map', 45, TRUE) |>
      
    # am.cmd('set', 'Container') - Loca.Container is set by  am.init(loca=TRUE)
    # am.cmd('viewControl.addAnimates', 'm$loca', 'm$tmp') |>  # but m$loca not instantiated yet
    am.cmd('set', 'GeoJSONSource', name='m$geoPulse', data= pfl) |>
    am.cmd('set', 'GeoJSONSource', name='m$geo', url= geoJson3D) #|>
    # am.cmd('set', 'PolygonLayer', name='m$lpl', opacity=0, # hide it
    #        shininess= 10, hasSide= TRUE, cullface='back', depth= TRUE) |>
    # # use setSource before setStyle, otherwise "Cannot read property 'getDataset' of undefined"
    # am.cmd('setSource', 'm$lpl', 'm$geo') |>
    # am.cmd('setStyle', 'm$lpl', topColor='#555', sideColor= '#555', height= "function(index, feature) {
    #   heit = feature.properties.height ? feature.properties.height : 1;
    #   return heit;
    # }")
  })
  
  observeEvent(input$isMarks, {
    if (isolate(!rv$isLoaded)) return()
    p <- am.proxy("plot")
    
    if (input$isMarks) {
      centr <- pcenter + c(-.003, .0001)
      
      am.cmd(p, 'set', 'InfoWindow', name='m$iwin', 
             content= 'MassMarks(2 icons below), ImageLayer(seal),<br> CanvasLayer(pulsating circle), LinkLayer(3D lines)', # and this InfoWindow', 
             anchor= 'bottom-center')
      am.cmd(p, 'open', 'm$iwin', 'm$jmap', centr)
      
      am.cmd(p, 'set', 'ImageLayer', name='imLay',
             url= pary,
             bounds= list( c(2.303985,48.856950), c(2.298961,48.860065) ), opacity= 0.6,
             zooms= c(5, 20))
      
      # massMarks --------------------
      marks <- list(
        list( lnglat= centr+ c(.0009, -.0006), name= 'bike1', style= 0),
        #list( lnglat= centr + c(.0005, .00061),
        list( lnglat= centr+ c(-.0009, -.0006), name= 'bike2', style= 1)
      )
      
      am.cmd(p, 'set', 'MassMarks', name='m$mmarks', 
             data= marks, opacity= 0.9, cursor= 'pointer',
             style= list(
               list(url= mark1, anchor=c(3,3), size=c(32,37), zIndex= 23),
               list(url= mark2, anchor=c(3,3), size=c(32,37), zIndex= 23)
             )
      )
      am.cmd(p, 'setMap', 'm$mmarks', 'm$jmap')
      
      # canvasLayer ------------------------
      jcanvas <- "window.m$jcanvas = document.createElement('canvas');
        m$jcanvas.width = m$jcanvas.height = 200;
        var context = m$jcanvas.getContext('2d')
        context.fillStyle = 'rgb(0,100,255)';
        context.strokeStyle = 'white';
        context.globalAlpha = 1;
        context.lineWidth = 2;"
      jdraw <- "var radius = 0;
        var draw = function () {
          if (m$jcanvas==undefined) return;
          context = m$jcanvas.getContext('2d', {willReadFrequently: true});
          context.clearRect(0, 0, 200, 200)
          context.globalAlpha = (context.globalAlpha - 0.01 + 1) % 1;
          radius = (radius + 1) % 100;

          context.beginPath();
          context.arc(100, 100, radius, 0, 2 * Math.PI);
          context.fill();
          context.stroke();
          m$CanvasLayer.reFresh();

          AMap.Util.requestAnimFrame(draw);
        }; draw();"
      # execute jcanvas before and jdraw after adding layer to map
      am.cmd(p, 'code', jcanvas)
      am.cmd(p, 'set', 'CanvasLayer', name= 'm$CanvasLayer', 
             canvas= 'm$jcanvas',
             bounds= list( c(2.2992001,48.855460), c(2.2966114,48.856614)),
             zooms= c(3, 18)
      )
      
      # OverlayGroup does not support MassMarks which is more of a collection than a layer
      am.cmd(p, 'set', 'OverlayGroup', name='m$overl8', 'imLay', 'm$CanvasLayer')
      am.cmd(p, 'addTo', 'map', 'm$overl8')
      am.cmd(p, 'code', jdraw)
      
      am.cmd(p, 'set', 'LinkLayer', name='m$pll')
      am.cmd(p, 'setSource', 'm$pll', 'm$geoPulse')
      am.cmd(p, 'setStyle', 'm$pll', lineColors= c('yellow','yellow'))
      
      # am.cmd(p, 'set', 'PulseLinkLayer', name= 'm$puls')
      # am.cmd(p, 'setSource', 'm$puls', 'm$geoPulse')
      # am.cmd(p, 'setStyle', 'm$puls',
      #     unit= 'meter', #dash= c(40, 20, 40, 20),
      #     height= 150, #"function(index, item) { return item.distance / 2 }",
      #     lineWidth= c(14,9),
      #     speed= 21,
      #     #maxHeightScale= 0.3, # Arc top position ratio
      #     flowLength= 30,
      #     lineColors= c('blue','brown','yellow'),
      #     headColor= 'green', trailColor= 'red'
      # )
      # am.cmd(p, 'animate.start', 'm$loca')
      
      # # Loca.ScatterLayer animation works, but throws an error on remove & cant show 2nd time
      # am.cmd(p, 'set', 'GeoJSONSource', name='m$geoPulC', data= pfc)
      # am.cmd(p, 'set', 'ScatterLayer', name='m$sl')
      # am.cmd(p, 'setSource', 'm$sl', 'm$geoPulC')
      # # optional animation style
      # am.cmd(p, 'setStyle', 'm$sl', unit= 'meter', size= c(100, 100), borderWidth= 0,
      #        texture= pulsed, duration= 500, animate= TRUE
      # )
      # am.cmd(p, 'animate.start', 'm$loca')
      
    }
    else {   # remove all marks
      am.cmd(p, 'remove', 'map', 'm$overl8')
      am.cmd(p, 'clearOverlays', 'm$overl8')
      am.cmd(p, 'remove', 'map', 'm$mmarks')
      am.cmd(p, 'remove', 'm$pll')
      am.cmd(p, 'clear', 'm$mmarks')
      am.cmd(p, 'close', 'm$iwin')
      am.cmd(p, 'code', "m$jcanvas=null;")
      
      # am.cmd(p, 'animate.stop', 'm$loca')
      # am.cmd(p, 'remove', 'm$puls')
      # am.cmd(p, 'destroy', 'm$puls') 
    }
  })
  
  observeEvent(input$isOver, {
    p <- am.proxy("plot")
    if (isolate(!rv$isLoaded)) return()
    if (input$isOver) {
      rv$bbCaller <- 'overlay'
      am.cmd(p, 'getBounds', 'map', r='cbounds')
    } else
      am.cmd(p, 'remove', 'map', 'myOvrlay')
  })
  
  observeEvent(input$isCircles, {    # proxy append demo
    p <- am.proxy("plot")
    am.cmd(p, 'circle', 'MouseTool', strokeWeight= 5, strokeColor= 'magenta')
    rv$bbCaller <- 'circle'
    am.cmd(p, 'getBounds', 'map', r='cbounds')
  })
  observeEvent(input$cbounds, {
    p <- am.proxy("plot")
    bb <- input$cbounds
    if (!is.null(bb) && length(bb)==4) {
      # result of getBounds
      #    below: example of 'get*' with params included in command
      am.cmd(p, 'getFitZoomAndCenterByBounds(bounds= args.data.bounds)', 'map', 
             bounds= list(c(bb[1:2]), c(bb[3:4])), r='cbounds')
    } else {
      # result of getFitZoomAndCenter
      ctr <- c(bb[2], bb[3])   # bb[1] is zoom
      
      # execute callback commands after center is found
      if (isolate(rv$bbCaller) == 'circle') {
        am.cmd(p, 'set', 'Circle', name='m$circ1', center= ctr, radius= 100, fillOpacity=0.3)
        am.cmd(p, 'addTo', 'm$vector', 'm$circ1')
      } 
      else if (isolate(rv$bbCaller) == 'overlay') {
        cctr <- ctr -c(-0.002, 0.003)   # relative distance to center
        pbnd <- list(cctr +c(0.002511, -0.001468), cctr +c(0.000729, -0.000903))
        am.cmd(p, 'set', 'Circle', name='myCir1', center= cctr,
               radius= 40, fillColor= 'red', strokeColor= '#fff', strokeWeight= 2)
        am.cmd(p, 'set', 'Rectangle', name='myRec1', bounds = pbnd,
               strokeStyle= 'dashed', fillColor= 'blue', fillOpacity= 0.2)
        am.cmd(p, 'set', 'OverlayGroup', name='myOvrlay', 'myCir1', 'myRec1')
        am.cmd(p, 'addTo', 'map', 'myOvrlay')
      }
    }
  })
  
  observeEvent(input$isCstop, {
    p <- am.proxy("plot")
    am.cmd(p, 'close', 'MouseTool')
    am.cmd(p, 'clear', 'm$vector')
  })
  
  observeEvent(input$isIcon, {   # proxy update demo
    p <- am.proxy("plot")
    if (isolate(!rv$isLoaded)) return()
    if (input$isIcon)  
      am.cmd(p, 'setIcon', 'labMark', image= bfish, size= c(64, 64))
    else
      p |> am.cmd('setIcon', 'labMark', image= labMark)
  })
  
  observeEvent(input$isTile, {
    p <- am.proxy("plot")
    if (isolate(!rv$isLoaded)) return()
    if (input$isTile)
      am.cmd(p, 'setTileUrl', 'tileLay', tile2)
    else 
      am.cmd(p, 'setTileUrl', 'tileLay', tile1)
  })
  
  observeEvent(input$isHeat, {
    p <- am.proxy("plot")
    if (input$isHeat) {
      if (isolate(rv$doneHito)) {
        am.cmd(p, 'show', 'hito'); return()
      }
      rv$doneHito <- TRUE
      pnts <- list()
      for(i in 1:length(glnglat)) {
        pnts <- append(pnts, list(list(lng= glnglat[[i]][1], lat= glnglat[[i]][2],
                                       count= sample(1:100, 1)) ))
      }
      
      am.cmd(p, 'set', 'HeatMap', name= 'hito', 
             radius= 25, opacity= c(0 ,0.8),
             ddd= list( gridSize= 2), # AMap native is '3d' but R dislikes it, so 'ddd'
             pnts = pnts
      )
      am.cmd(p, 'show', 'hito');

    } else if (isolate(rv$doneHito))
      am.cmd(p, 'hide', 'hito')
  })
  
  observeEvent(input$isWms, {
    p <- am.proxy("plot")
    if (input$isWms) {
      rv$doneWMS <- TRUE
      am.cmd(p, 'set', 'WMTS', name='myWMS',
        blend= FALSE, tileSize= 256,
        url= 'https://wxs.ign.fr/an7nvfzojv5wa96dsga5nk8w/geoportail/wmts',
        params= list(layer= 'CADASTRALPARCELS.PARCELLAIRE_EXPRESS', style= 'PCI vecteur', tilematrixset= 'PM', Version= '1.0.0')
      )
    } else if (isolate(rv$doneWMS))
      am.cmd(p, 'remove', 'map', 'myWMS')
  })
  
  observeEvent(input$getit, {
    am.proxy("plot") |>
      am.cmd('getLayers', 'map',
             f='function(ww) { tt= ww.map(x => { return x.CLASS_NAME;}); return tt; }',
             r='result1')
  })
  
  observeEvent(input$goLL, {
    p <- am.proxy("plot")
    if (startsWith(input$getsom, 'get'))   # like getZoom, getPitch, getRotation, getBounds
      am.cmd(p, input$getsom, 'map', r='result1')
  })
  
  observeEvent(input$result1, {
    output$out1 <- renderPrint({ input$result1 }) 
  })
  
  observeEvent(input$isLoLay, {
    if (isolate(!rv$isLoaded)) return()
    p <- am.proxy("plot")
    if (input$isLoLay) {
    #  am.cmd(p, 'setOpacity', 'm$lpl', 1)   # was ok w old loca.js
      am.cmd(p, 'set', 'PolygonLayer', name='m$lpl') #, #opacity=0, # hide it
      #       shininess= 10, hasSide= TRUE, cullface='back', depth= TRUE)
      # use setSource before setStyle, otherwise "Cannot read property 'getDataset' of undefined"
      am.cmd(p, 'setSource', 'm$lpl', 'm$geo')
      am.cmd(p, 'setStyle', 'm$lpl', topColor='#555', sideColor= '#555', height= "function(index, feature) {
        heit = feature.properties.height ? feature.properties.height : 1;
        return heit;
      }")
      
    } else {
    #  am.cmd(p, 'setOpacity', 'm$lpl', 0)
      am.cmd(p, 'remove', 'm$lpl')
    }
  })
  
  observeEvent(input$btnFly, {
    if (isolate(!rv$isLoaded)) return()
    p <- am.proxy("plot")
    am.cmd(p, 'getRotation', 'map', r='gRot')
    am.cmd(p, 'getZoom', 'map', r='gZum')
    am.cmd(p, 'getPitch', 'map', r='gPit')
    am.cmd(p, 'getCenter', 'map', r='gCen')
  })
  observeEvent(input$gCen, {
    # start flyover here, when all 4 params are taken
    p <- am.proxy("plot")
    #am.cmd(p, 'setRotation', 'map', 0, TRUE)  # reset, =360 after flyover 
    am.cmd(p, 'var', 'm$tmp', flylist(input$gCen, input$gRot, input$gZum, input$gPit))
    am.cmd(p, 'viewControl.addAnimates', 'm$loca', 'm$tmp')
    am.cmd(p, 'animate.start', 'm$loca')
  })
  
  observeEvent(input$info, {
    showModal(modalDialog(
      title = "amapro - interactive 2D/3D maps", easyClose= TRUE, size= 'l',
      tags$div("This demo presents some features of the library. Map center is in Paris, France.",
       "Most items are located around the Eiffel tower, but Overlay and Flyover are ",tags$em('relative')," to current view.",
       br(), strong('\u2714\uFE0F Replace icon'),": replaces the yellow sign icon with a fish",
       br(), strong('\u2714 Marks'),": pops-up InfoWindow and other markers + yellow Loca 3D LinkLayer lines",
       br(), strong('\u2714 Heatmap'),": a 3D heatmap uses same points as geoJson (red) polygon and displays there",
       br(), strong('\u2714 Start/Stop Car'),": flyover trace animation following a predefined path. When end-point reached, click twice to restart.",
       br(), strong('\u2714 Loca 3D'),": displays 3D buildings from a geoJson file (polygons+height)",
       br(), strong('\U1F985 Flyover'),": ",tags$em('Loca 3D')," must be checked. 3D flight from current view to red polygon(Trocadero) and back. Pan map to restart.",
       br(), strong('\u2714 Base'),": switch base tile layer between ArcGis and OpenStreet",
       br(), strong('\u2714 WMS'),": toggle layer of cadastral units by ",tags$a(href='https://www.ign.fr/', 'ign.fr'),". Buildings will display in orange, but may need pan or zoom in to activate.",
       br(), strong('\u2714 Overlay'),": a red circle and a blue polygon showing relative to map center",
       br(), strong('\u25A2 Draw'),": hit button \u25BA a central blue circle appears \u25BA click and drag to draw circles on map",
       br(), strong('\u25A2 Remove All'),": delete all drawn circles",
       br(), strong('\u25A2 Run'),": AMap simple ",tags$em('get')," commands like getCenter, getZoom. Or ",strong('\u25A2 getLayers')," for a list result.",       br(), strong('Context Menu'),": by right-clicking on map. ",tags$em('+marker')," will add a marker at clicked position, ",tags$em('lng/lat copy')," will copy map point's coordinates into clipboard.",
       br(), "R/Shiny ",tags$em('source code')," is on ",tags$a(href='https://github.com/helgasoft/amapro', 'Github'),". Hope you enjoy it \u2B50" )
   ))
  })
  
}   # end server

shinyApp(ui = ui, server = server, options= list(launch.browser= TRUE))
