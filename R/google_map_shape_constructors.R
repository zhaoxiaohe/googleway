# # Map Object
# # Generates teh map object from the given arguemnts, for the given calling function
# mapObject <- function(map, data, legend, legend_options, palette, digits, update_map_view,
#                       layer_id, objArgs, colour_attributes){
#
#   callingFunc <- as.character(objArgs[[1]])
#
#   allCols <- shapeColumns(callingFunc)
#   requiredCols <- requiredColumns(callingFunc)
#   colourColumns <- shapeAttributes(colour_attributes)
#
#   shape <- createMapObject(data, allCols, objArgs)
#
#   pal <- createPalettes(shape, colourColumns)
#   colour_palettes <- createColourPalettes(data, pal, colourColumns, palette)
#   colours <- createColours(shape, colour_palettes)
#
#   if(length(colours) > 0){
#     shape <- replaceVariableColours(shape, colours)
#   }
#
#   ## LEGEND
#   if(any(vapply(legend, isTRUE, T))){
#     legend <- constructLegend(colour_palettes, legend)
#     if(!is.null(legend_options)){
#       legend <- addLegendOptions(legend, legend_options)
#     }
#   }
#
#   requiredDefaults <- setdiff(requiredCols, names(shape))
#   if(length(requiredDefaults) > 0){
#     shape <- addDefaults(shape, requiredDefaults, "circle")
#   }
#
#   shape <- jsonlite::toJSON(shape, digits = digits)
#
#   invoke_method(map, callingFunc, shape, update_map_view, layer_id, legend)
# }


# Create Map Object
#
# Creates the map object from the input data and arguments. If the arguments
# are columns of the \code{data}, the column is used. Otherwise, the value
# is assumed to be required for every row of \code{data} and is replicated
# for the whole data set
#
# @param data data passed into the map layer function
# @param cols all the columns required for the given map object
# @param objArgs the arguments passed into the map layer function
createMapObject <- function(data, cols, objArgs){

  dataNames <- names(data)

  argsIdx <- match(cols, names(objArgs)) ## those taht exist in 'cols'
  argsIdx <- argsIdx[!is.na(argsIdx)]

  argValues <- sapply(1:length(objArgs), function(x) objArgs[[x]])

  dataArgs <- which(argValues %in% names(data)) ## those where there is a column of data

  additionalValues <- setdiff(argsIdx, dataArgs)

  dataCols <- vapply(dataArgs, function(x) objArgs[[x]], "")
  dataNames <- names(objArgs)[dataArgs]

  df <- setNames(data[, dataCols, drop = F], dataNames)

  if(length(additionalValues) > 0){

    extraCols <- lapply(additionalValues, function(x){
      setNames(as.data.frame(rep(objArgs[[x]], nrow(df)), stringsAsFactors = F), names(objArgs)[x])
    })

    df <- cbind(df, do.call(cbind, extraCols))
  }
  return(df)
}

# Replace Variable Colours
#
# Replaces the columns in shape object with the colours they have been mapped to
#
# @param shape object to be plotted on map
# @param colours list of colours that will replace the data in shape
replaceVariableColours <- function(shape, colours){

  eachColour <- do.call(cbind, colours)
  colourNames <- colnames(eachColour)

  ## need to strip off attributes so rstudio and browsers can plot the colours
  ## (there is an issue with one or the other not recognisign an array ["#FF00FF"])
  shape[, c(unname(colourNames))] <- as.data.frame(eachColour, stringsAsFactors = F)
  return(shape)

}

# Add Defaults
#
# adds the default object parameters to a shape
#
# @param shape object to be plotted on a map
# @param requiredDefaults required columns of default data
# @param shapeType the type of shape
addDefaults <- function(shape, requiredDefaults, shapeType){

  n <- nrow(shape)
  defaults <- switch(shapeType,
                     "marker" = markerDefaults(n),
                     "circle" = circleDefaults(n),
                     "polygon" = polygonDefaults(n),
                     "polygonUpdate" = polygonUpdateDefaults(n),
                     "polyline" = polylineDefaults(n),
                     "polylineUpdate" = polylineUpdateDefaults(n),
                     "rectangle" = rectangleDefaults(n),
                     "heatmap" = heatmapDefaults(n),
                     "heatmapUpdate" = heatmapUpdateDefaults(n))

  shape <- cbind(shape, defaults[, requiredDefaults, drop = F])
  return(shape)
}

lineAttributes <- function(stroke_colour){
  c("stroke_colour" = stroke_colour)
}

shapeAttributes <- function(fill_colour, stroke_colour){

#  stroke_colour = colour_attributes[['stroke_colour']]
#  fill_colour = colour_attributes[['fill_colour']]

  c("stroke_colour" = stroke_colour,
    "fill_colour" = fill_colour)
}

# requiredColumns <- function(func){
#   print("calling func: ")
#   print(func)
#   switch(func,
#     "add_circles" = requiredCircleColumns(),
#     "add_rectangles" = requiredShapeColumns(),
#     "add_polylines" = requiredLineColumns(),
#     "add_polygons" = requiredShapeColumns()
#   )
# }

shapeColumns <- function(func){
  switch(func,
         "add_circles" = circleColumns(),
         "add_rectangles" = rectangleColumns(),
         "add_polylines" = polylineColumns(),
         "add_polygons" = polygonColumns()
         )
}

requiredLineColumns <- function(){
  c("geodesic","stroke_colour","stroke_weight","stroke_opacity","z_index")
}

requiredLineUpdateColumns <- function(){
  c("stroke_colour", "stroke_weight", "stroke_opacity")
}

requiredShapeColumns <- function(){
  c("stroke_colour", "stroke_weight", "stroke_opacity",
    "fill_opacity", "fill_colour", "z_index")
}

requiredShapeUpdateColumns <- function(){
  c("stroke_colour", "stroke_weight", "stroke_opacity",
    "fill_opacity", "fill_colour")
}

requiredCircleColumns <- function(){
  c(requiredShapeColumns(), "radius")
}

requiredMarkerColumns <- function(){
  c("opacity", "colour")
}

requiredHeatmapColumns <- function(){
  c('fill_colour')
}

requiredHeatmapUpdateColumns <- function(){
  c()
}

## MARKERS ---------------------------------------------------------------------
markerColumns <- function(){
  c('id', 'colour', 'lat', 'lng', 'title', 'draggable', 'opacity', 'label',
    'info_window', 'mouse_over', 'mouse_over_group', 'url')
}

df_markerColours <- function(){
  data.frame(colour = c('red', 'blue', 'green', 'lavender'),
             url = c("http://mt.googleapis.com/vt/icon/name=icons/spotlight/spotlight-poi.png&scale=1",
                     "https://mts.googleapis.com/vt/icon/name=icons/spotlight/spotlight-waypoint-blue.png&psize=16&font=fonts/Roboto-Regular.ttf&color=ff333333&ax=44&ay=48&scale=1",
                     "http://mt.google.com/vt/icon?psize=30&font=fonts/arialuni_t.ttf&color=ff304C13&name=icons/spotlight/spotlight-waypoint-a.png&ax=43&ay=48&text=%E2%80%A2",
                     "http://mt.google.com/vt/icon/name=icons/spotlight/spotlight-ad.png"))
}

markerDefaults <- function(n){
  data.frame("opacity" = rep(1, n),
             "colour" = rep("red", n),
             stringsAsFactors = F)
}

## polyline ---------------------------------------------------------------------
polylineColumns <- function(){
  c('polyline', 'id', 'lat', 'lng', 'editable', 'draggable', 'stroke_colour',
    'stroke_opacity', 'stroke_weight', 'mouse_over', 'mouse_over_group', 'info_window')
}

polylineUpdateColumns <- function(){
  c('id', 'stroke_colour', 'stroke_weight', 'stroke_opacity', 'info_window')
}

polylineDefaults <- function(n){
  data.frame(
    "geodesic" = rep(TRUE, n),
    "stroke_colour" = rep("#0000FF", n),
    "stroke_weight" = rep(2, n),
    "stroke_opacity" = rep(0.6, n),
    "z_index" = rep(3, n),
    stringsAsFactors = F
  )
}

polylineUpdateDefaults <- function(n){
  data.frame(
    "stroke_colour" = rep("#0000FF", n),
    "stroke_weight" = rep(2, n),
    "stroke_opacity" = rep(0.6, n),
    stringsAsFactors = F
  )
}

## polygon ---------------------------------------------------------------------
polygonColumns <- function(){
  c('polyline', 'id', 'lat', 'lng', 'pathId', 'editable', 'draggable', 'stroke_colour',
    'stroke_opacity', 'stroke_weight', 'fill_colour', 'fill_opacity',
    'mouse_over', 'mouse_over_group', 'info_window')
}

polygonUpdateColumns <- function(){
  c('id', 'stroke_colour', 'stroke_weight', 'stroke_opacity', 'fill_colour',
    'fill_opacity', 'info_window')
}

polygonDefaults <- function(n){
  data.frame("stroke_colour" = rep("#0000FF",n),
             "stroke_weight" = rep(1,n),
             "stroke_opacity" = rep(0.6,n),
             "fill_colour" = rep("#FF0000",n),
             "fill_opacity" = rep(0.35,n),
             "z_index" = rep(1,n),
             stringsAsFactors = FALSE)
}

polygonUpdateDefaults <- function(n){
  data.frame("stroke_colour" = rep("#0000FF",n),
             "stroke_weight" = rep(1,n),
             "stroke_opacity" = rep(0.6,n),
             "fill_colour" = rep("#FF0000",n),
             "fill_opacity" = rep(0.35,n),
             stringsAsFactors = FALSE)
}

## circle ---------------------------------------------------------------------
circleColumns <- function(){
  c('id', 'lat', 'lng', 'radius', 'draggable', 'stroke_colour',
    'stroke_opacity', 'stroke_weight', 'fill_colour', 'fill_opacity',
    'mouse_over', 'mouse_over_group', 'info_window')
}

circleDefaults <- function(n){
  data.frame("stroke_colour" = rep("#FF0000",n),
             "stroke_weight" = rep(1,n),
             "stroke_opacity" = rep(0.8,n),
             "radius" = rep(50,n),
             "fill_colour" = rep("#FF0000",n),
             "fill_opacity" = rep(0.35,n),
             "z_index" = rep(4,n),
             stringsAsFactors = FALSE)
}

## rectangle ---------------------------------------------------------------------
rectangleColumns <- function(){
  c("north", "east", "south", "west", 'id', 'lat', 'lng', "editable",
    'draggable', 'stroke_colour', 'stroke_opacity', 'stroke_weight',
    'fill_colour', 'fill_opacity', 'mouse_over', 'mouse_over_group',
    'info_window')
}

rectangleDefaults <- function(n){
  data.frame("stroke_colour" = rep("#FF0000", n),
             "stroke_weight" = rep(1, n),
             "stroke_opacity" = rep(0.8, n),
             "fill_colour" = rep("#FF0000", n),
             "fill_opacity" = rep(0.35, n),
             "z_index" = rep(2, n),
             stringsAsFactors = FALSE)
}

## heatmap ---------------------------------------------------------------------
heatmapColumns <- function(){
  c('lat', 'lng', 'fill_colour')
}

heatmapDefaults <- function(n){
  data.frame('fill_colour' = rep(1, n),
             stringsAsFactors = F)
}

heatmapUpdateDefaults <- function(n){
  data.frame('fill_colour' = rep(1, n),
             stringsAsFactors = F)
}


