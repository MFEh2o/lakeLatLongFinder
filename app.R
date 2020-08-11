# This is a Shiny app to allow users to get lat/long for a specific lake on click
library(shiny) # load shiny
library(dplyr)
library(sp)
library(sf) # faster loading of shapefile
library(rgdal)
library(rgeos)
library(mapview)
library(leaflet)
source("appfuns.R")


# reading using read_sf instead of readOGR for faster loading
shape <- st_read("data/GLMS_shape_combined_latlong.shp") %>%
  st_transform(.,"+proj=longlat +datum=WGS84") %>%
  mutate(label = paste0("<b>long:</b> ", LONGITUDE, "<br/>", 
                        "<b>lat:</b> ", LATITUDE, "<br/>", 
                        "<b>GNIS ID:</b> ", GNIS_ID, "<br/>", 
                        "<b>GNIS name:</b> ", GNIS_NAME, "<br/>", 
                        "<b>Area (km2):</b> ", AREASQKM, "<br/>", 
                        "<b>Reach code:</b> ", REACHCODE, "<br/>"))

shape <- shape %>%
  mutate(UNDERC = case_when(LONGITUDE > -89.548857 & LONGITUDE < -89.464963 & LATITUDE > 46.206879 & LATITUDE < 46.266711 ~ TRUE,
                            TRUE ~ FALSE)) %>% # assign underc designation
  mutate(NHLD = case_when(LONGITUDE > -90.43000 & LONGITUDE < -88.93000 & LATITUDE > 45.60000 & LATITUDE < 46.33000 ~ TRUE,
                          TRUE ~ FALSE)) # assign nhld designation

# Building the user interface (UI)
ui <- fluidPage(
  titlePanel("MFE Lakes lat/long finder"),
  sidebarLayout(
    sidebarPanel(
      p1, p2, p3, # intro text-- located in appfuns.R
      
      # Let the user choose how they want to search
      selectInput("howsearch", "How would you like to search?", choices = c("View a subset of lakes" = "subset", "Search by lake name" = "search"), selected = "subset"),
      
      # Depending on their choice, show different options
      conditionalPanel(
        condition = "input.howsearch == 'subset'",
        #Select either UNDERC or NHLD
        radioButtons("subset", label = "Choose a subset of lakes to view:", 
                     choices = c("UNDERC lakes", "NHLD lakes"), selected = "UNDERC lakes"),
        actionButton("submitsubset", "Show results")
      ),
      conditionalPanel(
        condition = "input.howsearch == 'search'",
        
        # Search
        textInput("lakename", label = "Enter a lake name, or part of one:", 
                  placeholder = "Lake name (case insensitive)"),
        selectInput("searchwithin", "Search within:", choices = c("All lakes","UNDERC lakes", "NHLD lakes", "Great Lakes region", "Upper Mississippi River region")),
        actionButton("submitsearch", "Show results")
      )
    ),
    mainPanel(
      leafletOutput("map"),
      br(),
      credit # edit in appfuns.R
    )
  )
)

# Server function
server <- function(input, output, session) {
  # initial plot data
  plot_data <- reactive({shape %>% filter(UNDERC == T)})
  output$map <- renderLeaflet({
    leaflet(plot_data()) %>%
      addTiles() %>%
      addPolygons(popup = ~label, weight = 1, color = "red")
  })
  
  # If subsets are chosen, modify this data
  observeEvent(input$submitsubset, {
    if(input$subset == "NHLD lakes"){
      plot_data <- shape %>% filter(NHLD == T)
    }else{
      plot_data <- shape %>% filter(UNDERC == T)
    }
    
    # Make the plot
    output$map <- renderLeaflet({
      leaflet(plot_data) %>%
        addTiles() %>%
        addPolygons(popup = ~label, weight = 1, color = "red")
    })
  })
  
  observeEvent(input$submitsearch, { # when user clicks the submit button
    # Subset the data
    req(input$lakename) # user must have entered something in the search bar
    subdf <- shape %>%
      filter(grepl(tolower(input$lakename), tolower(GNIS_NAME))) # search for lowercase version of the person's input in a lowercase version of the GNIS_NAME column

    if(input$searchwithin == "UNDERC lakes"){
      subdf <- subdf %>%
        filter(UNDERC == T)
    }else if(input$searchwithin == "NHLD lakes"){
      subdf <- subdf %>%
        filter(NHLD == T)
    }else if(input$searchwithin == "Great Lakes region"){
      subdf <- subdf %>%
        filter(regionID == "GL")
    }else if(input$searchwithin == "Upper Mississippi River region"){
      subdf <- subdf %>%
        filter(regionID == "MS")
    }else{
      subdf <- subdf
    }
    
    # Make the map
    output$map <- renderLeaflet({
      validate(
        need(nrow(subdf) > 0, "Couldn't find that lake name in the selected region--check your spelling or try a different name")
      )
      # make the basic leaflet map with polygons
      leaflet(subdf) %>%
        addTiles() %>%
        addPolygons(popup = ~label, weight = 1, color = "red")
    })
    
    # If the user chooses to search by lake name, display markers on the lakes (since they can be small and hard to find). Also allow popup when user clicks the marker (not just the polygon itself).
    observeEvent(input$howsearch == "search", {
      leafletProxy("map", data = subdf) %>%
        addMarkers(lng = ~LONGITUDE, lat = ~LATITUDE, popup = ~label)
    })
    
  })
  
}

# A call to shinyApp runs the app
shinyApp(ui, server)