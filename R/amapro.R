# ----------- General --------------

#' Introduction
#' 
#' Essential information, tips and tricks
#'
#' @includeRmd vignettes/info.Rmd
#' 
#' @name -- Introduction --
NULL

#' Map Initialization
#'
#' First command to build a map
#'
#' @param ... attributes of map, see \href{https://lbs.amap.com/api/jsapi-v2/documentation#map}{here}.\cr
#'   Additional attribute _loca_(boolean) is to add a Loca.Container to the map.
#' @param width,height A valid CSS unit (like \code{'100\%'})
#' @return A widget to plot, or to store and expand with more features
#'
#' @details  Command \emph{am.init} creates a widget with \code{\link[htmlwidgets]{createWidget}}, then adds features to it.\cr
#'  On first use, \emph{am.init} prompts for AMap API key. There is a temporary \emph{demo} mode when key is unavailable.
#'
#' @examples
#' if (interactive()) {
#'   ctr <- c(22.430151, 37.073011)
#'   tu <- paste0('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/',
#'                    'MapServer/tile/[z]/[y]/[x]')
#'   am.init( center= ctr, zoom= 10, pitch= 60, viewMode= '3D') |>
#'   am.control(ctype= 'ControlBar', position= 'RT') |>
#'   am.item('TileLayer', tileUrl= tu) |>
#'   am.item('Marker', position= ctr,
#'       icon= 'https://upload.wikimedia.org/wikipedia/commons/9/9d/Ancient_Greek_helmet.png'
#'   ) |>
#'   am.cmd('set', 'InfoWindow', name='iwin', content='This is Sparta') |>
#'   am.cmd('open', 'iwin', 'm$jmap', ctr)   # m$jmap is the map name in JavaScript
#' }
#'
#' @importFrom htmlwidgets createWidget sizingPolicy getDependency JS
#' @export
am.init <- function(..., width=NULL, height=NULL) {
  
  path <- system.file('js', package = 'amapro')
  ffull <- paste0(path, '/amap.js')
  if (!file.exists(ffull)) 
    stop("Missing AMap library file 'amap.js'. Installation invalid.", call.=FALSE)
  cont <- suppressWarnings(readLines(ffull))
  if (grepl('xxxxxxxxxxxxxx', cont[2], fixed=TRUE)) {
    if (interactive()) {
      key <- .prompt()
      if (is.null(key)) return()
      if (tolower(key)=='demo') {
        key <- scan('https://raw.githubusercontent.com/helgasoft/amapro/master/inst/figures/demo.txt', what='character')
        key <- intToUtf8(rev(utf8ToInt(key)))
      }
      cont[2] <- sub('xxxxxxxxxxxxxx', key, cont[2], fixed= TRUE)
      writeLines(cont, ffull)
      detach("package:amapro", unload= TRUE)
      library(amapro)
      msg <- 'Done - amapro is now ready.\n Repeat command or restart Shiny app.'
      tcltk::tk_messageBox(type = c("ok"),
                    msg, caption = "AMap API key installation")
    }
  }
  rm(cont)
  
  opts <- list(...)
  elementId <- if (is.null(opts$elementId)) NULL else opts$elementId
  # debug - to display JS objects info in browser console and map mesh
  debug <- if (is.null(opts$debug)) FALSE else opts$debug
  loca <- if (is.null(opts$loca)) FALSE else opts$loca
  deps <- NULL

  # forward widget options using x
  x <- list(
    draw = TRUE,
    opts = opts,
    width = width,
    height = height,
    debug = debug,
    loca = loca
  )

  # create widget
  wt <- htmlwidgets::createWidget(
    name = 'amapro',
    x,
    width = width,
    height = height,
    package = 'amapro',
    elementId = elementId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = '100%',
      knitr.figure = FALSE,
      browser.fill = TRUE, padding = 0
    ),
    dependencies = deps
  )

  return(wt)
}


#' Add Control
#'
#' Add a Control to a map.
#'
#' @param id \code{amapro} id or widget from [am.init]
#' @param ctype A string for name of control, like 'Scale','ControlBar','ToolBar'.
#' @param ... A named list of parameters for the chosen control
#' @return A map widget to plot, or to save and expand with more features.
#' 
#' @details  controls are ControlBar, ToolBar and Scale. \cr
#'    \href{https://a.amap.com/jsapi/static/doc/20210906/index.html?v=2#control}{Parameters} could be position or offset.\cr
#' @seealso  [am.init] code example
#' @examples
#' if (interactive()) {
#'   am.init() |> am.control("Scale")
#' }
#' @export
am.control <- function(id, ctype=NULL, ...) {
  method <- "addControl"
  data <- list(...)
  .callJS()
}


#' Add Item
#'
#' Add an item to a map
#'
#' @param id A valid widget from [am.init]
#' @param itype A string for item type name, like 'Marker'
#' @param ... attributes of item
#' @return A map widget to plot, or to save and expand with more features
#'
#' @details  To add an item like Marker, Text or Polyline to the map
#' @examples
#' if (interactive()) {
#'   am.init() |> am.item('Marker', position=c(116.6, 40))
#' }
#' @seealso  [am.init] code example
#'
#' @export
am.item <- function(id, itype, ...) {
  method <- "addItem"
  data <- list(...)
  .callJS()
}


#' Run a command
#'
#' Execute a command on a target element
#'
#' @param id A map widget from [am.init] or a proxy from [am.proxy]
#' @param cmd A command name string, like 'setFitView'
#' @param trgt A target's name string, or 'map' for the map itself.
#' @param ... command attributes \cr
#' @return A map or a map proxy
#'
#' @details \emph{am.cmd} provides interaction with the map.\cr
#' Commands are sent to the map itself, or to objects inside or outside it.\cr
#' AMap built-in objects have predefined set of commands listed in the API.
#' Commands can modify an object (setZoom), but also get data from it (getCenter).\cr
#' \emph{amapro} introduces its own commands like \emph{set}, \emph{addTo} or \emph{code}, described in the [Introduction].
#' 
#' @examples
#' if (interactive()) {
#'   am.init() |> 
#'   am.cmd('set', 'InfoWindow', position=c(116.6, 40), content='Beijing')
#' }
#' @seealso  [am.init] code example and [Introduction]
#'
#' @export
am.cmd <- function(id, cmd=NULL, trgt=NULL, ...) {
  if (missing(id))
    stop('missing map or proxy', call. = FALSE)

  # add to map
  if ('amapro' %in% class(id)) {
    method <- "addCmd"
    cmd <- cmd
    if (is.null(trgt)) trgt <- 'map'
    trgt <- trgt
    data <- list(...)
    tmp = .callJS()
    return(tmp)
  }

  # run on proxy
  if (!'amaProxy' %in% class(id))
    stop('must pass amaProxy object', call.=FALSE)
  plist <- list(id = id$id,
                trgt = trgt,
                cmd = cmd,
                data = list(...)
  )
  id$session$sendCustomMessage('amapro:doCmd', plist)
  return(id)
}


# ----------- Shiny --------------

#' Shiny: map UI
#'
#' Placeholder for a map in Shiny UI
#'
#' @param outputId Name of output UI element.
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \emph{'auto'}) or a number, which will be coerced to a
#'   string and have \emph{'px'} appended.
#' @return An output or render function that enables the use of the widget within Shiny applications. 
#' See \link[htmlwidgets]{shinyWidgetOutput}.
#'
#' @seealso Shiny demo in demo(am.shiny)
#'
#' @importFrom htmlwidgets shinyWidgetOutput
#' @export
am.output <- function(outputId, width = '100%', height = '400px') {
  htmlwidgets::shinyWidgetOutput(outputId, 'amapro', width, height, package='amapro')
}


#' Shiny: render a map
#'
#' This is the initial rendering of a map in the UI.
#'
#' @param wt An \code{amapro} widget to generate the chart.
#' @param env The environment in which to evaluate \code{expr}.
#' @return An output or render function that enables the use of the widget within Shiny applications.
#'
#' @seealso [am.proxy] for example, \code{\link[htmlwidgets]{shinyRenderWidget}} for return value.
#'
#' @importFrom htmlwidgets shinyRenderWidget
#' @export
am.render <- function(wt, env=parent.frame()) {
  wt <- substitute(wt)  # do not add ',env' in substitute command
  htmlwidgets::shinyRenderWidget(wt, am.output, env, quoted=TRUE)
}


#' Shiny: create a map proxy
#'
#' Create a proxy for an existing map in Shiny. It allows to
#' add, merge, delete elements to a map without reloading it.
#'
#' @param id Map id from the Shiny UI
#' @return A proxy object to update the map
#'
#' @examples
#' if (interactive()) {
#'   demo(am.shiny)
#' }
#' @export
am.proxy <- function(id) {
  if (requireNamespace("shiny", quietly = TRUE)) {
    sessi <- shiny::getDefaultReactiveDomain()
  } else
    return(invisible(NULL))
  proxy <- list(id = id, session = sessi)
  class(proxy) <- 'amaProxy'
  return(proxy)
}



# ------------ Utils ----

#' Map to JSON
#' 
#' Convert map elements to JSON string
#' 
#' @param wt An \code{amapro} widget as returned by [am.init]
#' @param json Boolean whether to return a JSON, or a \code{list}, default TRUE
#' @param ... Additional arguments to pass to \link[jsonlite]{toJSON}
#' @return A JSON string if \code{json} is \code{TRUE} and
#'  a \code{list} otherwise.
#'
#' @details Must be invoked or chained as last command.\cr
#'
#' @examples
#' if (interactive()) {
#'   am.init(viewMode= '3D', zoom= 10, pitch= 60) |>
#'     am.control(ctype= 'ControlBar', position= 'RT') |>
#'     am.inspect()
#' }
#' @export
am.inspect <- function(wt, json=TRUE, ...) {
  
  opts <- wt$x
  
  if (!isTRUE(json)) return(opts)
  params <- list(...)
  if ('pretty' %in% names(params)) 
    opts <- jsonlite::toJSON(opts, force=TRUE, auto_unbox=TRUE, 
                             null='null', ...)
  else
    opts <- jsonlite::toJSON(opts, force=TRUE, auto_unbox=TRUE, 
                             null='null', pretty=TRUE, ...)
  
  return(opts)
}

.callJS <- function() {
  # get the parameters from the function that have a value
  message <- Filter(function(x) !is.symbol(x), as.list(parent.frame(1)))
  session <- shiny::getDefaultReactiveDomain()

  # If an amapro widget was passed in, this is during a chain pipeline in the
  # initialization of the widget, so keep track of the desired function call
  # by adding it to a list of functions that should be performed when the widget
  # is ready
  if ('amapro' %in% class(message$id)) { 
    widget <- message$id
    message$id <- NULL
    widget$x$api <- c(widget$x$api, list(message))
    return(widget)
  }
  # If an ID was passed, the widget already exists
  else if (is.character(message$id)) {
    message$id <- session$ns(message$id)
    method <- paste0('amapro:', message$method)
    session$sendCustomMessage(method, message)
    return(message$id)
  } else {
    msg <- "The `id` argument must be either an amapro htmlwidget or its ID.\n
          Could be also invalid AMap API-key."
    stop(msg, call.= FALSE)
  }
}

.prompt <- function() {

  xvar <- tcltk::tclVar('demo')
  
  tt <- tcltk::tktoplevel(bg= 'goldenrod')
  tcltk::tkwm.title(tt, 'amapro')
  key.entry <- tcltk::tkentry(tt, textvariable= xvar)
  
  reset <- function() { tcltk::tclvalue(xvar)<-"" }
  reset.but <- tcltk::tkbutton(tt, text="Reset", command= reset)
  submit <- function() {
    key <- tcltk::tclvalue(xvar)
    e <- parent.env(environment())
    e$key <- key
    tcltk::tkdestroy(tt)
  }
  submit.but <- tcltk::tkbutton(tt, text="Submit", command= submit)
  
  tcltk::tkgrid(tcltk::tklabel(tt,text="One-time installation of library AMap", background='goldenrod'), columnspan=2)
  tcltk::tkgrid(tcltk::tklabel(tt,text="Enter AMap API key (or 'demo')", background='goldenrod'), key.entry, pady = 10, padx =10)
  tcltk::tkgrid(submit.but, reset.but)
  
  tcltk::tcl("wm", "attributes", tt, topmost= TRUE)
  tcltk::tkraise(tt)
  tcltk::tkwait.window(tt)
  
  if (!exists('key')) key <- NULL
  return(c(key))
}


# ---------------------------------------------- License -----
#   Original work Copyright 2022 Larry Helgason
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#'------------------------------------------------------------

  
