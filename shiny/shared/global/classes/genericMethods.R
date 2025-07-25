#----------------------------------------------------------------------
# define generic functions, i.e., methods, available to S3 classes,
# if the class declares method.class <- function()
#----------------------------------------------------------------------
# new generic declarations take the form:
#     genericName <- function(x, ...) {
#         UseMethod("genericName", x)
#     }
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# helper methods for the browserInput S3 class
#----------------------------------------------------------------------
annotations <- function(x, ...) {
    UseMethod("annotations", x)
}
chromosomes <- function(x, ...) {
    UseMethod("chromosomes", x)
}
genomeFile <- function(x, ...) {
    UseMethod("genomeFile", x)
}
annotationFile <- function(x, ...) {
    UseMethod("annotationFile", x)
}
coordinates <- function(x, ...) {
    UseMethod("coordinates", x)
}

#----------------------------------------------------------------------
# helper methods for the browserTrack S3 class
#----------------------------------------------------------------------
delete <- function(x, ...) {
    UseMethod("delete", x)
} 
adjustWidth <- function(x, ...) {
    UseMethod("adjustWidth", x)
}
build <- function(x, ...) {
    UseMethod("build", x)
}
items <- function(x, ...) {
    UseMethod("items", x)
}
navigation <- function(x, ...) {
    UseMethod("navigation", x)
}
expand <- function(x, ...) {
    UseMethod("expand", x)
}
expand2 <- function(x, ...) { # i.e., expand from an expansion click
    UseMethod("expand2", x)
}
padding <- function(x, ...) {
    UseMethod("padding", x)
}
height <- function(x, ...) {
    UseMethod("height", x)
}
scaleUnit <- function(x, ...) {
    UseMethod("scaleUnit", x)
}
ylab <- function(x, ...) {
    UseMethod("ylab", x)
}
ylim <- function(x, ...) {
    UseMethod("ylim", x)
}
bty <- function(x, ...) {
    UseMethod("bty", x)
}
typ <- function(x, ...) {
    UseMethod("typ", x)
}
pch <- function(x, ...) {
    UseMethod("pch", x)
}
lwd <- function(x, ...) {
    UseMethod("lwd", x)
}
lty <- function(x, ...) {
    UseMethod("lty", x)
}
cex <- function(x, ...) {
    UseMethod("cex", x)
}
col <- function(x, ...) {
    UseMethod("col", x)
}
zeroLine <- function(x, ...) {
    UseMethod("zeroLine", x)
}
hLines <- function(x, ...) {
    UseMethod("hLines", x)
}
vLines <- function(x, ...) {
    UseMethod("vLines", x)
}
chromLines <- function(x, ...) {
    UseMethod("chromLines", x)
}
getItemsData <- function(x, ...) {
    UseMethod("getItemsData", x)
}
plotXY <- function(x, ...) {
    UseMethod("plotXY", x)
}
plotHeatMap <- function(x, ...) {
    UseMethod("plotHeatMap", x)
}
plotSpans <- function(x, ...) {
    UseMethod("plotSpans", x)
}
trackLegend <- function(x, ...) {
    UseMethod("trackLegend", x)
}
initTrackNav <- function(x, ...) {
    UseMethod("initTrackNav", x)
}
trackNavInput <- function(x, ...) {
    UseMethod("trackNavInput", x)
}
trackNavTable <- function(x, ...) {
    UseMethod("trackNavTable", x)
}
trackNavPlot <- function(x, ...) {
    UseMethod("trackNavPlot", x)
}
trackNavCanNavigate <- function(x, ...) {
    UseMethod("trackNavCanNavigate", x)
}
trackNavCanExpand <- function(x, ...) {
    UseMethod("trackNavCanExpand", x)
}
handleTrackNavTableClick <- function(x, ...) {
    UseMethod("handleTrackNavTableClick", x)
}
handleTrackNavPlotClick <- function(x, ...) {
    UseMethod("handleTrackNavPlotClick", x)
}
