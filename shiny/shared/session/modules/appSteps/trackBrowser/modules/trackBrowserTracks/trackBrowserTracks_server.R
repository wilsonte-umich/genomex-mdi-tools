# trackBrowser server module for selecting and ordering browser tracks
# there is always a single set of tracks selected at a time applied to all regions
trackBrowserTracksServer <- function(id, browser) {
    moduleServer(id, function(input, output, session) {
#----------------------------------------------------------------------
defaultTrackTypes <- c(
    "plot_title",
    "chromosome",
    "scale_bar",
    "coordinate_axis",
    "genes"
)
addTrackPrompt <- "-- add a new track --"
duplicateTrackPrompt <- "-- duplicate a track --"
duplicateTrackPromptId <- "0"
suite  <- 'genomex-mdi-tools'
module <- 'trackBrowser'

#----------------------------------------------------------------------
# manage browser track types available and in use
#----------------------------------------------------------------------
trackTypes <- list()          # key = trackType, value = settings template file path
trackSuiteNames <- list()     # key = trackType, value = host suite name if an external track
tracks <- reactiveVal(list()) # key = trackId,   value = browserTrackServer()
nullTrackOrder <- data.table(trackId = character(), order = integer())
trackOrder <- reactiveVal(nullTrackOrder)
orderedTrackIds <- reactive({ # the current track ids, in plotting order
    trackOrder <- trackOrder()
    if(nrow(trackOrder) > 0) trackOrder[order(order), trackId] else character()
})

#----------------------------------------------------------------------
# assemble the track types available to this app
parentAppTrackTypes <- character()
externalTrackSuites <- list()
addTrackType <- function(trackType, tracksFolder, checkSubDirs = FALSE, trackSuiteName = NULL){
    trackTypeFolder <- file.path(tracksFolder, trackType)
    settingsPath  <- file.path(trackTypeFolder, "settings.yml")
    trackFilePath <- file.path(trackTypeFolder, "track.R")
    if(file.exists(settingsPath) && file.exists(trackFilePath)) { # the request is itself a track folder
        trackTypes[[trackType]] <<- settingsPath
        if(!is.null(trackSuiteName)) trackSuiteNames[[trackType]] <<- trackSuiteName
    } else if (checkSubDirs) { # check if the request is a parent of multiple track folders in a family
        subDirs <- list.dirs(path = trackTypeFolder, full.names = FALSE, recursive = FALSE)
        for(subDir in subDirs) addTrackType(subDir, trackTypeFolder, trackSuiteName = trackSuiteName)
    }
}
addTrackTypes <- function(dir, classPath, isParentApp = FALSE){
    tracksFolder <- file.path(dir, classPath)
    trackTypes <- list.dirs(tracksFolder, full.names = FALSE, recursive = FALSE)
    if(isParentApp) parentAppTrackTypes <<- sort(trackTypes)
    sapply(trackTypes, addTrackType, tracksFolder)
}
classPath <- "classes/browserTracks"
globalClassPath <- file.path("shiny/shared/global", classPath) 
genomexDirs <- parseExternalSuiteDirs(suite)
addTrackTypes(genomexDirs$suiteDir, globalClassPath) # apps always offer global tracks from genomex-mdi-tools
addTrackTypes(app$DIRECTORY, classPath, isParentApp = TRUE) # apps always offer tracks they define themselves
if(!is.null(browser$options$tracks)) for(trackType in browser$options$tracks){ # apps can additionally offer global tracks declared in the app's config.yml that are...
    if(grepl("//", trackType)){ # ... defined in an external suite, if that suite is actually installed ...
        x <- strsplit(trackType, "//")[[1]]
        trackSuiteDirs <- parseExternalSuiteDirs(x[1])
        if(
            isTruthy(gitStatusData$dependencies[[x[1]]]$loaded) &&
            !is.null(trackSuiteDirs)
        ){
            externalTrackSuites[[x[1]]] <- trackSuiteDirs$suiteDir
            addTrackType(x[2], file.path(trackSuiteDirs$suiteDir, globalClassPath), checkSubDirs = TRUE, trackSuiteName = x[1]) # allow easy loading of families of shared tracks
        }
    } else { # ... or in the parent suite of the app
        addTrackType(trackType, file.path(gitStatusData$suite$dir, globalClassPath), checkSubDirs = TRUE)
    }
}
#----------------------------------------------------------------------
# initialize available track types
initTrackTypes <- function(){
    names <- names(trackTypes)
    firstTrackTypes <- c(defaultTrackTypes, parentAppTrackTypes)
    sortedTrackTypes <- c(firstTrackTypes, sort(names[!(names %in% firstTrackTypes)]))
    updateSelectInput(
        session, 
        "addTrack", 
        choices = c(
            addTrackPrompt,
            sortedTrackTypes
        ),
        selected = addTrackPrompt
    ) 
}

#----------------------------------------------------------------------
# add, delete and reorder tracks
#----------------------------------------------------------------------
# track identifiers
getTrackId <- function() paste(format(Sys.time(), "%Y_%m_%d_%H_%M"), sample.int(1e6, 1), sep = "_")
getTrackNames <- function(trackIds){
    tracks <- tracks()
    sapply(trackIds, function(trackId) getTrackDisplayName(tracks[[trackId]]$track))
}
#----------------------------------------------------------------------
# handle track addition from select input or bookmark
tracksAreInitialized <- FALSE
addTrack <- function(trackType, trackId = NULL, ns){
    if(is.null(trackId)) trackId <- getTrackId()
    cssId <- paste("track", trackId, sep = "_")
    track <- browserTrackServer(
        cssId = cssId,
        trackId = trackId,
        trackType = trackType,
        settingsFile = trackTypes[[trackType]], # includes any presets defined by the trackType
        presets = browser$options$presets[[trackType]], # add any presets defined by the calling app
        browserInput = input, 
        genome = browser$reference$genome,
        annotation = browser$reference$annotation,
        trackSuiteName = trackSuiteNames[[trackType]],
        # size = NULL,
        # cacheKey = NULL, # a reactive/reactiveVal that returns an id for the current settings state
        # fade = FALSE,
        title = paste("Track parameters (", trackType, ")"),
        # immediate = FALSE, # if TRUE, setting changes are transmitted in real time
        # resettable = TRUE  # if TRUE, a Reset All Setting link will be provided    
    )

    # append the new track at the bottom of the track list
    insertUI(
        paste0("#", session$ns("trackList"), " .rank-list"),
        where = "beforeEnd",
        multiple = FALSE,
        immediate = TRUE,
        browserTrackUI(ns(cssId), track) # unclear why different ns is required when addTrack is called from init vs. user action

    )
    trackOrder <- trackOrder()
    trackOrder <- rbind(
        trackOrder, 
        data.table(trackId = trackId, order = nrow(trackOrder) + 1)
    )
    trackOrder(trackOrder)
    tracks_ <- tracks()
    tracks_[[trackId]] <- track
    tracks(tracks_)
    trackId
}
observeEvent(input$addTrack, {
    trackType <- input$addTrack
    req(trackType)
    req(trackType != addTrackPrompt)
    updateSelectInput(session, "addTrack", selected = addTrackPrompt) # reset the prompt
    trackId <- addTrack(trackType, ns = session$ns)
    createTrackSettingsObserver(trackId)
}, ignoreInit = TRUE)
#----------------------------------------------------------------------
# handle track addition from duplication of an existing track
output$duplicateTrack <- renderUI({
    trackIds <- orderedTrackIds()
    req(trackIds)
    tracks <- tracks()
    names(trackIds) <- paste0(
        getTrackNames(trackIds), 
        " (",
        sapply(trackIds, function(x) tracks[[x]]$type),
        ")"
    )
    promptId <- duplicateTrackPromptId
    names(promptId) <- duplicateTrackPrompt
    selectInput(session$ns("duplicateTrackSelect"), NULL, choices = c(promptId, trackIds))
})
observeEvent(input$duplicateTrackSelect, {
    dupTrackId <- input$duplicateTrackSelect
    req(dupTrackId != duplicateTrackPromptId)
    updateSelectInput(session, "duplicateTrackSelect", selected = duplicateTrackPromptId) # reset the prompt
    dupTrack <- tracks()[[dupTrackId]]
    trackId <- addTrack(dupTrack$type, ns = session$ns)
    tracks()[[trackId]]$track$settings$replace(dupTrack$track$settings$all_())
    createTrackSettingsObserver(trackId)
}, ignoreInit = TRUE)
#----------------------------------------------------------------------
# handle track reordering and deletion
isRankListInit <- FALSE
observeEvent({
    input$trackRankList
    input$deleteRankList
}, {
    if(tracksAreInitialized) { if(isRankListInit) {

        # declare the new track order
        currentTrackIds <- trackOrder()[, trackId] 
        newTrackIds <- sapply(strsplit(input$trackRankList, '\\s+'), function(x) x[length(x)])
        nTracks <- length(newTrackIds)

        # abort if there would be zero tracks, catches an occasional load race condition
        if(nTracks > 0){ 
            trackOrder(data.table(trackId = newTrackIds, order = 1:nTracks))

            # delete tracks as needed
            tracks_ <- tracks()
            for(trackId in currentTrackIds) {
                if(!(trackId %in% newTrackIds)) {
                    tracks_[[trackId]] <- NULL
                    trackSettingsObservers[[trackId]] <<- NULL
                    if(!is.null(trackSettingsUndoId) && trackSettingsUndoId == trackId) trackSettingsUndoId <<- NULL
                }
            }
            tracks(tracks_)
            removeUI(".trackDeleteTarget .browserTrack")            
        }
    } else isRankListInit <<- TRUE}
}, ignoreInit = TRUE)

#----------------------------------------------------------------------
# handle track settings
#----------------------------------------------------------------------
# undo the last track settings change, intended for disaster recover, not a complete history tracking
trackSettingsObservers <- list()
trackSettingsUndoId <- NULL
createTrackSettingsObserver <- function(trackId){
    track <- tracks()[[trackId]]
    trackSettingsObservers[[trackId]] <<- observeEvent(track$track$settings$all_(), {
        trackSettingsUndoId <<- trackId
        app$browser$clearObjectExpansions()
    })
}
observeEvent(input$undoTrackSettings, {
    tracks <- tracks()
    req(trackSettingsUndoId, tracks[[trackSettingsUndoId]])
    tracks[[trackSettingsUndoId]]$track$settings$undo()
})

#----------------------------------------------------------------------
# initialization
#----------------------------------------------------------------------
initialize <- function(jobId, loadData, loadSequence){
    initTrackTypes()
    if(is.null(loadData$outcomes$trackOrder)){
        for(trackType in defaultTrackTypes) addTrack(trackType, ns = browser$session$ns)
    } else {
        trackIds <- loadData$outcomes$trackOrder[order(order), trackId]
        lapply(trackIds, function(trackId){
            track <- loadData$outcomes$tracks[[trackId]]         
            addTrack(track$type, trackId, ns = browser$session$ns)
            tracks()[[trackId]]$track$settings$replace(track$settings)
            createTrackSettingsObserver(trackId)
            if(!is.null(track$items)) tracks()[[trackId]]$track$settings$items(track$items)
        })
    }
    tracksAreInitialized <<- TRUE
    doNextLoadSequenceItem(loadData, loadSequence)
}

#----------------------------------------------------------------------
# module return value
list(
    tracks = tracks,
    orderedTrackIds = orderedTrackIds,
    trackOrder = trackOrder,
    bookmarkTracks = reactive({
        trackIds <- trackOrder()[, trackId]
        tracks <- tracks()
        x <- lapply(trackIds, function(trackId){
            track <- tracks[[trackId]]
            list( 
                type = track$type,
                settings = track$track$settings$all_(),
                items = if(is.null(track$track$settings$items)) NULL 
                        else track$track$settings$items()
            )
        })
        names(x) <- trackIds
        x
    }),
    getTrackNames = getTrackNames,
    initialize = initialize,
    externalTrackSuites = externalTrackSuites,
    getTrackIdsByType = function(trackType) sapply(tracks(), function(track) if(track$type == trackType) track$id else NULL) %>% unlist
)
#----------------------------------------------------------------------
})}
