#----------------------------------------------------------------------
# UI components for the trackBrowser appStep module
#----------------------------------------------------------------------

# module ui function
trackBrowserUI <- function(id, options) {

    # initialize namespace
    module <- 'trackBrowser'
    appStepDir <- getAppStepDir(module)
    ns <- NS(id)
    
    # override missing options to module defaults
    options <- setDefaultOptions(options, stepModuleInfo$trackBrowser)
    trackRankListId <- "trackRankListGroup"

    # return the UI contents
    standardSequentialTabItem(

        # page header text
        options$longLabel,
        options$leaderText,

        # page header links, uncomment as needed
        id = id,
        # documentation = TRUE,
        # terminal = TRUE,
        console = serverEnv$IS_DEVELOPER,
        code = serverEnv$IS_DEVELOPER,
        download = TRUE,
        settings = TRUE,

        # track browser styles
        tags$style(slurpFile(file.path(appStepDir, "trackBrowser.css"))),
        tags$script(slurpFile(file.path(appStepDir, "trackBrowser.js"))),

        #----------------------------------------------------------------------
        # top row of browser-level options and navigation
        #----------------------------------------------------------------------
        tags$div(

            # TODO: could genome and annotation to settings?
            tags$div(
                class = "trackBrowserInput ucscInput genomeInput",
                popupInputUI(ns('genome'), "Genome")
            ),
            tags$div(
                class = "trackBrowserInput ucscInput annotationInput",
                popupInputUI(ns('annotation'), "Annotation")
            ),
            tags$div(
                class = "trackBrowserInput",
                selectInput(ns('chromosome'), "Chromosome", choices = c()),
            ),
            tags$div(
                class = "trackBrowserInput",
                textInput(ns('start'), "Start", value = 1),
            ),
            tags$div(
                class = "trackBrowserInput",
                textInput(ns('end'), "End", value = 10000),
            ),
            tags$div(
                class = "trackBrowserInput",
                actionButton(ns('zoomOut'), "-"),
            ),
            tags$div(
                class = "trackBrowserInput",
                actionButton(ns('zoomIn'), "+"),
            ),
            tags$div(
                class = "trackBrowserInput",
                textInput(ns('zoomFactor'), "Zoom", value = 10, width = "41px"),
            ),
            tags$div(
                class = "trackBrowserInput",
                actionButton(ns('moveLeft'), "<<"),
            ),
            tags$div(
                class = "trackBrowserInput",
                actionButton(ns('nudgeLeft'), "<"),
            ),
            tags$div(
                class = "trackBrowserInput",
                actionButton(ns('nudgeRight'), ">"),
            ),
            tags$div(
                class = "trackBrowserInput",
                actionButton(ns('moveRight'), ">>"),
            ),
            tags$div(
                class = "trackBrowserInput",
                textInput(ns('jumpTo'), "Jump To", value = ""),
            ),
            tags$div(
                class = "trackBrowserInput",
                checkboxInput(ns('strict'), "Strict", value = FALSE),
            ),
        ),
        tags$div(
            style = "white-space: nowrap;",

            #----------------------------------------------------------------------
            # the vertical, sortable list of tracks
            #----------------------------------------------------------------------
            tags$div(
                style = "width: 243px;",
                class = "browserContentPanel addTrack",
                tags$div(
                    class = "browserTrack trackDeleteTarget",                    
                    rank_list( 
                        text = "drop track to delete", 
                        labels = NULL, 
                        input_id = ns("deleteRankList"), 
                        css_id = NULL, 
                        options = sortable_options(
                            group = ns(trackRankListId),
                            multiDrag = FALSE 
                        ), 
                        class = "default-sortable"
                    )   
                ),
                tags$div(
                    id = ns("trackList"),
                    class = "browserTrackList",
                    rank_list( 
                        text = "", 
                        labels = NULL, 
                        input_id = ns("trackRankList"), 
                        css_id = NULL, 
                        options = sortable_options(
                            group = ns(trackRankListId),
                            multiDrag = FALSE 
                        ), 
                        class = "default-sortable"
                    )                    
                ),
                uiOutput(ns("duplicateTrack")),
                selectInput(ns("addTrack"), NULL, choices = c())              
            ),

            #----------------------------------------------------------------------
            # the browser output image
            #----------------------------------------------------------------------
            tags$div(
                style = "display: inline-block;",
                tags$p(
                    id = ns("initMessage"),
                    style = "padding: 15px;",
                    tags$strong("Please wait 2 seconds for the browser to initialize.")
                ),
                mdiInteractivePlotUI(id = ns("image"))              
            )
        )
    )
}