#'  most are working examples, could be displayed
#'
  
test_that("amap without loca", {
  p <- am.init(viewMode= '3D')
  expect_null(p$x$opts$loca)
  expect_equal(p$x$opts$viewMode, '3D')
})

test_that("amap GeoJSON", {
  
  glnglat <- list(c(2.290412,48.863673),c(2.292779,48.862115),c(2.288930,48.859023),c(2.289799,48.860950),c(2.290633,48.861634),c(2.289015,48.861835),c(2.287414,48.860088),c(2.286171,48.860614),c(2.287397,48.862586))
  gjson <- list(type= "FeatureCollection", features= list(
    list(type= "Feature", properties= list(id="44", name="Trocadero"), 
         geometry= list(type= "Polygon", coordinates= as.matrix(list(glnglat)))
    )))
  tile2 <- 'https://{a,b,c}.tile.openstreetmap.org/[z]/[x]/[y].png'
  
  if (interactive()) {
    p <- am.init( #center= c(2.303985,48.856950), zoom=6, loca=TRUE) |>
      loca= TRUE, viewMode= '3D',
      center= c(2.288930,48.859023), zoom= 16, pitch= 60) |>
      am.control('ControlBar', position= 'RT') |> 
      am.item('TileLayer', name='tileLay', tileUrl= tile2, zooms= c(3, 20) ) |>
      am.item('GeoJSON', name= 'mygjson', geoJSON= gjson) # |> am.inspect()

    expect_equal(p$x$opts$viewMode, '3D')
    expect_equal(p$x$api[[3]]$data$name, 'mygjson')
    expect_equal(p$x$api[[3]]$data$geoJSON$features[[1]]$geometry$type, 'Polygon')
  }
  else expect_equal(1,1)
})

test_that("loca GeoJSONSource scatter", {
  #' from https://lbs.amap.com/demo/loca-v2/demos/cat-scatter/sz-road
  if (interactive()) {
    p <-
    am.init(loca= TRUE, 
          viewMode= '3D', zoom= 11.7, pitch= 40,
          mapStyle= 'amap://styles/dark', showLabel= FALSE,
          center= c(113.9719963, 22.5807295) ) |>
    am.control('ControlBar', position= 'RT') |> 
    am.cmd('set', 'GeoJSONSource', name='m$geo',
           url='https://a.amap.com/Loca/static/loca-v2/demos/mock_data/sz_road_F.json') |>
    am.cmd('set', 'ScatterLayer', name='m$red', opacity=1, zIndex= 113,
           visible= TRUE, zooms= c(2, 22) ) |>
    am.cmd('setSource', 'm$red', 'm$geo') |>
    am.cmd('setStyle', 'm$red', unit= 'meter', borderWidth= 0,
           size= c(1000, 1000),
           texture= 'https://a.amap.com/Loca/static/loca-v2/demos/images/breath_red.png',
           duration= 1000,
           animate= TRUE) |> am.cmd('animate.start', 'm$loca')
    expect_equal(p$x$api[[6]]$method, 'addCmd')
    expect_true(p$x$opts$loca)
  }
  else expect_equal(1,1)
})

test_that("loca PolygonLayer with lights", {
  # https://lbs.amap.com/demo/loca-v2/demos/cat-polygon/hz-gn
  # https://lbs.amap.com/demo/loca-v2/demos/cat-view-control/lights
  
  tile4 <- 'https://{a,b,c,d}.basemaps.cartocdn.com/dark_all/[z]/[x]/[y].png'
  
  # https://writingjavascript.com/scaling-values-between-two-ranges
  jscala <- "window.scaler = class Scaler {
    constructor(inMin, inMax, outMin, outMax) {
      this.inMin = inMin;
      this.inMax = inMax;
      this.outMin = outMin;
      this.outMax = outMax;
    }
    scale(value) {
      const result = (value - this.inMin) * (this.outMax - this.outMin) / (this.inMax - this.inMin) + this.outMin;
      if (result < this.outMin) {
        return this.outMin;
      } else if (result > this.outMax) {
        return this.outMax;
      }
      return result;
    }
  }; 
  window.m$colors = ['#FFF8B4', '#D3F299', '#9FE084', '#5ACA70', '#00AF53', '#00873A', '#006B31', '#004835', '#003829'].reverse();
  "
  pageo <- jsonlite::read_json('https://opendata.paris.fr/explore/dataset/arrondissements/download/?format=geojson&lang=fr')
  for(i in 1:20) pageo$features[[i]]$properties$h <- i
  onEvents <- list(
    list(e= 'click', f="function() {
            m$poly.addAnimate({
              key: 'height', value: [0, 1], duration: 1000, easing: 'CubicInOut'
            }, function() { });  
          }"),
    list(e= 'mousemove', f="function(e) {
            var feat = m$poly.queryFeature(e.pixel.toArray());
            if (feat) {
              m$txt.show();
              var health = feat.properties.h;
              m$txt.setText(feat.properties.l_ar + '<br>' + feat.properties.l_aroff + '<br> value:' + health);
              m$txt.setPosition(e.lnglat);
              m$poly.setStyle({
  topColor: (i, f) => { if (f===feat) return [164, 241, 199, 0.5];
        m$sc= new scaler(1,20,0,8); return m$colors[Math.round(m$sc.scale(f.properties.h))]; },
  sideTopColor: (i, f) => { if (f===feat) return [164, 241, 199, 0.5];
        m$sc= new scaler(1,20,0,8); return m$colors[Math.round(m$sc.scale(f.properties.h))]; },
  sideBottomColor: (i, f) => { if (f===feat) return [164, 241, 199, 0.5];
        m$sc= new scaler(1,20,0,8); return m$colors[Math.round(m$sc.scale(f.properties.h))]; },
  height: (i, f) => { m$sc= new scaler(1,18,0,4000); return 4000-m$sc.scale(f.properties.h); }
              })
            } 
            else
              m$txt.hide();
          }")
  )
  
  if (interactive()) {
    p <- am.init(loca= TRUE,
          viewMode= '3D', pitch= 40, showLabel= TRUE, showBuildingBlock= FALSE,
          on= onEvents,
          mapStyle= 'amap://styles/dark', 
          zoom= 11, center= c(2.328007,48.86992) ) |>  #Paris
    am.control('ControlBar', position= 'RT') |> 
    am.item('TileLayer', name='tileLay', tileUrl= tile4, zooms= c(3, 20) ) |>
    am.item('GeoJSONSource', name= 'm$gjson', data=pageo) |>
    am.item('Text', name= 'm$txt', text= 'markup', anchor= 'center', 
            draggable= TRUE, cursor= 'pointer', angle= 0, visible= TRUE, offset= c(0, -40)
            ,style= list(padding= '5px 10px', `margin-bottom`= '1rem', `border-radius`= '.25rem',
                         `background-color`= 'rgba(0,0,0,0.5)', `border-width`= 0,
                         `box-shadow`= '0 2px 6px 0 rgba(255, 255, 255, .3)',
                         `text-align`= 'center', `font-size`= '16px', color= '#fff')
    ) |>
    am.cmd('set','PolygonLayer', name='m$poly', opacity=0.5) |> 
    am.cmd('setSource', 'm$poly', 'm$gjson') |>
    am.cmd('code', jscala) |>
    am.cmd('setStyle', 'm$poly',
           altitude= 0,
           topColor= "function(i, f) { m$sc= new scaler(1,20,0,8); return m$colors[Math.round(m$sc.scale(f.properties.h))]; }",
           sideTopColor= "function(i, f) { m$sc= new scaler(1,20,0,8); return m$colors[Math.round(m$sc.scale(f.properties.h))]; }",
           sideBottomColor= "function(i, f) { m$sc= new scaler(1,20,0,8); return m$colors[Math.round(m$sc.scale(f.properties.h))]; }",
           height= "function(i, f) { m$sc= new scaler(1,18,0,4000); return 4000-m$sc.scale(f.properties.h); }") |>
    am.cmd('set','ambLight', intensity= 0.9, color= '#fff') |>
    am.cmd('set','dirLight', intensity= 1, color= '#fff', position= c(1,-1, 0), target= c(0,0,0))
    # am.cmd('set','pointLight', color= 'rgb(100,100,100)',  position= c(2.328007,46.86992, 2000),
    #       intensity= 3, distance= 50000)
  
    expect_equal(p$x$api[[10]]$trgt, 'dirLight')
    expect_true(grepl('m$poly.queryFeature', p$x$opts$on[[2]]$f, fixed=TRUE))
  }
  else expect_equal(1,1)
})
