test_that("loca GeoJSON", {
  
  glnglat <- list(c(2.290412,48.863673),c(2.292779,48.862115),c(2.288930,48.859023),c(2.289799,48.860950),c(2.290633,48.861634),c(2.289015,48.861835),c(2.287414,48.860088),c(2.286171,48.860614),c(2.287397,48.862586))
  gjson <- list(type= "FeatureCollection", features= list(
    list(type= "Feature", properties= list(id="44", name="Trocadero"), 
         geometry= list(type= "Polygon", coordinates= as.matrix(list(glnglat)))
    )))
  tile2 <- 'https://{a,b,c}.tile.openstreetmap.org/[z]/[x]/[y].png'
  
  p <- am.init(
    loca= TRUE, viewMode= '3D', showBuildingBlock= FALSE,
    pitchEnable= TRUE,  # dragEnable= FALSE, rotateEnable= FALSE,
    center= c(2.290633,48.861634), zoom= 16, pitch= 60) |>
    am.control('ControlBar', position= 'RT') |> 
    am.item('TileLayer', name='tileLay', tileUrl= tile2, zooms= c(3, 20) ) |>
    am.item('GeoJSON', name= 'mygjson', geoJSON= gjson)
  
  expect_equal(p$x$opts$viewMode, '3D')
  expect_equal(p$x$api[[3]]$data$name, 'mygjson')
  expect_equal(p$x$api[[3]]$data$geoJSON$features[[1]]$geometry$type, 'Polygon')
})
