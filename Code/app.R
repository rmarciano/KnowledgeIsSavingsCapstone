require(shiny)
require(leaflet)
require(tidyverse)
require(dplyr)
require(scales)
require(geojsonio)
require(RColorBrewer)
require(sp)

county_patient_payment <- read.csv("County Patient Payment.csv")
county_merged <- geojson_read(x = "County Merged.geojson", what = "sp")
states <- geojson_read(x = "gz_2010_us_040_00_5m.json", what = "sp")
counties <- geojson_read(x = "gz_2010_us_050_00_5m.json", what = "sp")

county_merged <- county_merged[!is.na(county_merged@data$MeanCountyPay), ]

coul = brewer.pal(9, "YlOrRd")
coul = colorRampPalette(coul)(15)


ui <- fluidPage(
  navbarPage("Patient Medicare Costs",
             tabPanel("Average Patient Cost by County",
                      titlePanel("Average Medicare Patient Costs by County for the Top 100 Inpatient DRGs in US"),
                      br(),
                      fluidRow(column(8, h4("Hover over a county to see the Average Medicare Inpatient Out of Pocket")),
                               column(4, selectInput(inputId = "Top1", label = "Choose a state to see the top 10 cheapest counties:", choices = c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", 
                                                                                                              "GA", "HI", "ID", "IL", "IN", "IA", "KS", 'KY', "LA", 
                                                                                                              "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", 
                                                                                                              "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", 
                                                                                                              "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", 
                                                                                                              "VA", "WA", "WV", "WI", "WY")))),
                      fluidRow(column(8,leafletOutput("map2", height = 500)),
                               column(4, tableOutput("TopTable1")))),
             tabPanel("Average Patient Costs by County and DRG Code",
                      titlePanel("Average Medicare Patient Costs by DRG Code per County for the Top 100 Inpatient DRGS in US"),
                      fluidRow(column(12, offset = 8, selectInput(inputId = "Top2", label = "Choose a DRG Code to see the 10 cheapest counties for that code:", choices = c("039" = "39", "057" = "57", "064" = "64", 
                                                                                              "065" = "65", "066" = "66", "069" = "69", 
                                                                                              "074" = "74", "101", "149", "176", "177", 
                                                                                              "189", "178", "190", "191", "192", "193", 
                                                                                              "194", "195", "202", "203", "207", "208", 
                                                                                              "238", "243", "244", "246", "247", "249", 
                                                                                              "251", "252", "253", "254", "280", "281", 
                                                                                              "282", "286", "287", "291", "293", "300", 
                                                                                              "482", "491", "536", "552", "563", "602", 
                                                                                              "603", "638", "640", "641", "682", "683", 
                                                                                              "684", "689", "690", "698", "699", "811", 
                                                                                              "812", "853", "870", "871", "872", "885", 
                                                                                              "897", "917", "918", "948"))),
                      fluidRow(column(8, plotOutput("TopPlot", width = "100%", height = "600px")),
                               column(4, tableOutput("TopTable2")))
             ))))


server <- function(input, output) {
  
 
  data2 <- reactive({
    x2 <- county_merged
  })
  
  output$map2 <- renderLeaflet({
    county_merged <- data2()
    
    bins2 <- c(370, 810, 860, 900, 940, 980, 1020, 1070, 1140, 1200, 1310, 1460, 6680)
    pal2 <- colorBin(coul, domain = county_merged$MeanCountyPay, bins = bins2)
    
    C <- leaflet(county_merged) %>%
      setView(-96, 37.8, 4) %>%
      addTiles() %>%
      addPolygons(data = counties,
                  color = "black",
                  opacity = 0.2,
                  weight = 1,
                  fillColor = "#e7dfdf",
                  fillOpacity = 1) %>% 
      addPolygons(data = county_merged,
                  color = "black",
                  fillColor = ~pal2(MeanCountyPay),
                  weight = 1,
                  opacity = 0.2,
                  dashArray = "3",
                  fillOpacity = 0.7,
                  highlight = highlightOptions(
                    weight = 5,
                    color = "#666",
                    dashArray = "",
                    fillOpacity = 0.5,
                    bringToFront = TRUE),
                  label = paste0(county_merged$NAME, ": ", dollar(county_merged$MeanCountyPay)),
                  labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "15px",
                    direction = "auto")) %>%
      addPolylines(data = states,
                   color = "black",
                   opacity = 1,
                   weight = 1) %>%
      addLegend(pal = pal2, values = ~MeanCountyPay, opacity = 0.7, title = "Average Medicare patient cost by County: ",
                position = "bottomright")
    C
    
  })
  output$TopPlot <- renderPlot({
    Top_10 <- county_patient_payment
    Top_10 <- subset(Top_10, DRG_Code == input$Top2)
    Top_10 <- top_n(Top_10, n = -10, wt = Mean_Patient_Payment)
    ggplot(Top_10, (aes(reorder(NAME, Mean_Patient_Payment), y = Mean_Patient_Payment))) + 
      geom_point(col = "Red", size = 3) +
      labs(title = "10 Cheapest Counties by DRG Code") +
      xlab("Counties") +
      ylab("Patient Costs") +
      theme(axis.text.x = element_text(size = 14),
            axis.text.y = element_text(size = 14),
            axis.title = element_text(size = 18),
            plot.title = element_text(size =24))
    
  })
  output$TopTable2 <- renderTable({
    Top_10 <- county_patient_payment
    Top_10 <- subset(Top_10, select = c("NAME", "DRG_Code", "Provider_State", "Mean_Patient_Payment"))
    Top_10 <- subset(Top_10, DRG_Code == input$Top2)
    Top_10 <- top_n(Top_10, n = -10, wt = Mean_Patient_Payment)
    Top_10 <- Top_10[order(Top_10$Mean_Patient_Payment),]
    colnames(Top_10)[colnames(Top_10) == "NAME"] <- "County"
    colnames(Top_10)[colnames(Top_10) == "Provider_State"] <- "State"
    colnames(Top_10)[colnames(Top_10) == "Mean_Patient_Payment"] <- "Average Medicare Patient Cost"
    colnames(Top_10)[colnames(Top_10) == "DRG_Code"] <- "DRG Code"
    Top_10
    
  })
  output$TopTable1 <- renderTable({
    Top_10_state <- as.data.frame(county_merged)
    Top_10_state <- subset(Top_10_state, select = c("NAME", "NAME_STATE", "MeanCountyPay"))
    Top_10_state <- subset(Top_10_state, NAME_STATE == input$Top1)
    Top_10_state <- top_n(Top_10_state, n = -10, wt = MeanCountyPay)
    Top_10_state <- Top_10_state[order(Top_10_state$MeanCountyPay),]
    colnames(Top_10_state)[colnames(Top_10_state) == "NAME"] <- "County"
    colnames(Top_10_state)[colnames(Top_10_state) == "NAME_STATE"] <- "State"
    colnames(Top_10_state)[colnames(Top_10_state) == "MeanCountyPay"] <- "Average Medicare Cost"
    Top_10_state
  })
}


shinyApp(ui = ui, server = server)



