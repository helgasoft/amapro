# ----------- General --------------

#' Introduction
#' 
#' Essential information, tips and tricks
#'
#' @includeRmd man/info.Rmd
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
#' @importFrom tcltk tk_messageBox
#'
#' @export
am.init <- function(..., width=NULL, height=NULL) {
  
  path <- system.file('js', package = 'amapro')
  ffull <- paste0(path, '/amap.js')
  if (!file.exists(ffull)) 
    stop("Missing AMap library file 'amap.js'. Installation invalid.", call.=FALSE)
  cont <- suppressWarnings(readLines(ffull))
  if (grepl('xxxxxxxxxxxxxx', cont[2], fixed=TRUE)) {
    key <- .prompt()
    if (is.null(key)) return()
    if (tolower(key)=='demo')
      key <- scan('https://raw.githubusercontent.com/helgasoft/amapro/master/inst/figures/demo.txt', what='character')
    cont[2] <- sub('xxxxxxxxxxxxxx', key, cont[2], fixed= TRUE)
    writeLines(cont, ffull)
    detach("package:amapro", unload= TRUE)
    library(amapro)
    msg <- 'Done - amapro is now ready.\n Repeat command or refresh map if needed.'
    tk_messageBox(type = c("ok"),
                  msg, caption = "AMap API key installation")
  }
  rm(cont)
  
  opts <- list(...)
  elementId <- if (is.null(opts$elementId)) NULL else opts$elementId
  # debug - to display JS objects info in browser console.
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
    #events = list(),
    #buttons = list()
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
#' @param id amapro id or a \code{amapro} widget from [am.init]
#' @param ctype A string for name of control, like 'Scale','ControlBar','ToolBar','HawkEye'.
#' @param ... A named list of parameters for the chosen control
#' @return A map widget to plot, or to save and expand with more features.
#' 
#' @details  Scale has no parameters, but ControlBar could have a \href{https://lbs.amap.com/api/jsapi-v2/documentation#control}{position}.\cr
#' Other controls are ToolBar and HawkEye.
#' @seealso  [am.init] code example
#' @examples
#' am.init() |> am.control("Scale")
#'
#' @export
am.control <- function(id, ctype=NULL, ...) {
  method <- "addControl"
  type <- ctype
  data <- list(...)
  #  type <- data[[1]]  # extract ctype from data
  #  data[[1]] <- NULL
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
#' @seealso  [am.init] code example
#'
#' @export
am.item <- function(id, itype, ...) {
  method <- "addItem"
  type <- itype
  data <- list(...)
  .callJS()
}


#' Run a command
#'
#' Execute a command on a target element
#'
#' @param id A map widget from [am.init] or a proxy from [am.proxy]
#' @param cmd A command name string, like 'setFitView'
#' @param target A target's name string, or 'map' for the map itself.
#' @param ... command attributes \cr
#' @return A map or a map proxy
#'
#' @details \emph{am.cmd} provides interaction with the map.\cr
#' Commands are sent to the map itself, or to objects inside or outside it.\cr
#' AMap-defined objects have predefined set of commands listed in the API.
#' Commands can modify an object (setZoom), but also get data from it (getCenter).\cr
#' amapro introduces three own commands - set, addTo, code, described in the [Introduction].
#' @seealso  [am.init] code example and [-- Introduction --]
#'
#' @export
am.cmd <- function(id, cmd=NULL, target=NULL, ...) {
  if (missing(id))
    stop('missing map or proxy', call. = FALSE)

  # add to map
  if ('amapro' %in% class(id)) {
    method <- "addCmd"
    cmd <- cmd
    if (is.null(target)) target <- 'map'
    target <- target
    data <- list(...)
    tmp = .callJS()
    return(tmp)
  }

  # run on proxy
  if (!'amaProxy' %in% class(id))
    stop('must pass amaProxy object', call.=FALSE)
  plist <- list(id = id$id,
                target = target,
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
#'
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
#' @param id Target map id from the Shiny UI
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
# needed by widget init
.preRender <- function(wt) {

  ff <- getOption('amapro.font')
  if (!is.null(ff))
    wt$x$opts$textStyle <- list(fontFamily = ff)
  wt
}

.callJS <- function() {
  # get the parameters from the function that have a value
  message <- Filter(function(x) !is.symbol(x), as.list(parent.frame(1)))
  session <- shiny::getDefaultReactiveDomain()

  # If an amapro widget was passed in, this is during a chain pipeline in the
  # initialization of the widget, so keep track of the desired function call
  # by adding it to a list of functions that should be performed when the widget
  # is ready
  if ('amapro' %in% class(message$id)) { #(methods::is(message$id, "amapro")) {
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
    stop("The `id` argument must be either an amapro htmlwidget or its ID.", call.= FALSE)
  }
}

.prompt <- function() {
  
  xvar <- tcltk::tclVar('demo')
  
  tt <- tcltk::tktoplevel()
  tcltk::tkwm.title(tt,"AMap library installation")
  key.entry <- tcltk::tkentry(tt, textvariable=xvar)
  
  reset <- function()
  {
    tcltk::tclvalue(xvar)<-""
  }
  
  reset.but <- tcltk::tkbutton(tt, text="Reset", command=reset)
  
  submit <- function() {
    key <- tcltk::tclvalue(xvar)
    e <- parent.env(environment())
    e$key <- key
    tcltk::tkdestroy(tt)
  }
  submit.but <- tcltk::tkbutton(tt, text="submit", command=submit)
  
  tcltk::tkgrid(tcltk::tklabel(tt,text="One-time installation of library AMap (amap.js)"),columnspan=2)
  tcltk::tkgrid(tcltk::tklabel(tt,text="Enter AMap key (or 'demo')"), key.entry, pady = 10, padx =10)
  tcltk::tkgrid(submit.but, reset.but)
  
  tcltk::tkwait.window(tt)
  
  if (!exists('key')) key <- NULL
  return(c(key))
}

