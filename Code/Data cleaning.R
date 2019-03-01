library(tidyverse)
library(dplyr)
library(tidyr)
library(skimr)
library(geojsonio)
library(sp)

#Read in original data set, add Average Patient Payment column, separate DRG Definition and DRG Code into two columns
payment <- read_csv("Medicare_Pricing.csv") %>% 
  mutate(payment, Average_Patient_Payments = payment$Average_Total_Payments - payment$Average_Medicare_Payments) %>%
  separate(payment, DRG_Definition, c("DRG_Code", "DRG_Definition"), sep = "-")

#Make sure there are no NA values
sum(is.na(payment))

#Look at a summary of the dataset
skim(payment)

#Write the tidied data set to a new .csv
write_csv(payment, "Capstone_Project_Tidy_Data.csv")

--
#Read in the data sets
zip_code_database <- read.csv("zip_code_database.csv", stringsAsFactors = FALSE)
payment <- read.csv("Capstone_Project_Tidy_Data.csv", stringsAsFactors = FALSE)
Patient_states <- read.csv("Average Patient Payments.csv", stringsAsFactors = FALSE)
counties <- geojson_read(x = "gz_2010_us_050_00_5m.json", what = "sp")
states <- geojson_read( x = "gz_2010_us_040_00_5m.json", what = "sp")
States_numbered <-  data.frame("NAME_STATE" = c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", 
                                                "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", 'KY', 
                                                "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", 
                                                "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", 
                                                "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", 
                                                "VT", "VA", "WA", "WV", "WI", "WY"), 
                               "STATE" = c("01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15", "16", "17", "18", "19", "20", "21", "22", "23", 
                                           "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "44", 
                                           "45", "46", "47", "48", "49", "50", "51", "53", "54", "55", "56"))

#Change the factors to characters
States_numbered$STATE <- as.character(States_numbered$STATE)
States_numbered$NAME_STATE <- as.character(States_numbered$NAME_STATE)

#Create dataframe from shapefile to get GEO ID codes
county_dataframe <- as.data.frame(counties)

#Change the dataframe from factors to characters
county_dataframe$STATE <- as.character(county_dataframe$STATE)
county_dataframe$NAME <- as.character(county_dataframe$NAME)

#The zip code database and county dataframe have some discrepancies the the county names.  Tidy the data so that the names match up
zip_code_database <- zip_code_database %>% 
  mutate(county = gsub(" County", "", county)) %>% 
  mutate(county = gsub(" city", "", county)) %>% 
  mutate(county = gsub(" City", "", county)) %>% 
  mutate(county = gsub(" Parish", "", county)) %>% 
  mutate(county = gsub(" Municipality", "", county)) %>% 
  mutate(county = gsub(" Census Area", "", county)) %>% 
  mutate(county = gsub(" Borough", "", county)) %>% 
  mutate(county = gsub(" and", "", county)) %>% 
  mutate(county = gsub("Lewis Clark", "Lewis and Clark", county)) %>% 
  mutate(county = gsub("Desoto", "DeSoto", county))
county_dataframe$NAME[482] <- "Carson"
county_dataframe$NAME[2809] <- "James"
county_dataframe$NAME[694] <- "Mcminn"


#Join the data
county_dataframe_join <- left_join(county_dataframe, States_numbered)
county_dataframe_join2 <- left_join(county_dataframe_join, zip_code_database, by = c("NAME" = "county", "NAME_STATE" = "state"))
county_dataframe_join3 <- left_join(payment, county_dataframe_join2, by = c("Provider_Zip" = "zip"))

#Calculate the average patient cost for each county
SumCountyPay <- county_dataframe_join3 %>% 
  group_by(NAME, NAME_STATE, GEO_ID) %>% 
  summarize(MeanCountyPay = mean(Average_Patient_Payments)) %>% 
  na.omit(SumCountyPay)

#Join the shape file and dataframe
counties@data <- data.frame(counties@data, SumCountyPay[match(counties@data$GEO_ID, SumCountyPay$GEO_ID), ])


#Calculate the average patient cost by DRG Code
county_paient_payment <- county_dataframe_join3 %>% 
  group_by(GEO_ID, NAME, DRG_Code, Provider_State) %>% 
  summarize(Mean_Patient_Payment = mean(Average_Patient_Payments))


#Create files with the new data
write.csv(county_paient_payment, "County Patient Payment.csv")
write.csv(county_dataframe_join3, "Payment Zip.csv")
geojson_write(counties, file = "County Merged")


