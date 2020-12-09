# Load libraries
library(tidyverse)
library(RSQLite)
library(magrittr)

counties <- c("Elkhart IN", "LaPorte IN", "Marshall IN", "St. Joseph IN", "Berrien MI", "Cass MI", "Gogebic MI", "St. Joseph MI", "Van Buren MI", "Oneida WI", "Vilas WI")
states <- c("Iowa", "Illinois", "Indiana", "Michigan", "Minnesota", "Missouri", "New York", "Ohio", "Pennsylvania", "South Dakota", "Wisconsin")

# Functions and nonreactive code for the app
p1 <- p("Welcome to the MFE lakes lat/long finder. This tool is designed to help you find coordinates and other information about your study lakes. This will also help us improve the accuracy and consistency of the MFE database.")
p2 <- p("To use: Find your lake using the tools below. You can search for a lake by name, or explore by dragging/zooming the map. Click on a lake to see information about it, including lat/long coordinates of its centroid.")
p3 <- p(em("When you enter a new lake into the database, please use these centroid coordinates in the LAKES table."))

credit <- em("This app was created by Kaija Gahm in 2020. Shapefile data for the Great Lakes and Upper Mississippi River regions is sourced from NHDPlus, version 2, https://nhdplus.com/NHDPlus/NHDPlusV2_data.php (accessed 5 August 2020).", style = "font-size:10px;")

searchErrorMessage <- "Couldn't find that lake name in the selected region--please try a different region or search term."


