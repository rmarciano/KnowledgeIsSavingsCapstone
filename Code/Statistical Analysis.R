library(dplyr)
library(readr)
library(eeptools)
library(ggpubr)
library(grid)
library(gridExtra)
library(lattice)
library(ggplot2)

payment <- read_csv("Capstone_Project_Tidy_Data.csv")

#Count number of states

payment_states <- unique(payment$Provider_State)
length(payment_states)
#Number of states is 51 because DC is counted as a state.  This means we have data for every state.

#We can check the number of procedures to make sure we have the total number we should, which is 100.

payment_DRG <- unique(payment$DRG_Code)
length(payment_DRG)

# First let's look at the overall means for the different payment variables

mean(payment$Average_Covered_Charges)
mean(payment$Average_Total_Payments)
mean(payment$Average_Medicare_Payments)
mean(payment$Average_Patient_Payments)

#We can also see how many Discharges are used to create this data

sum(payment$Total_Discharges)

#We can filter for each states average total charges to see how cost varies by state.

SumTotalPay <- payment %>% group_by(Provider_State) %>% summarize(MeanTotalPay = mean(Average_Total_Payments))

#This gives us some great information, but it will be much easier to read if we sort it by MeanTotPay

SumTotalPay_ordered <- SumTotalPay[order(SumTotalPay$MeanTotalPay) , ]

#Since 51 states (remember, DC is counted as a state) is a large number to look at in one graph, we're going to split our data into 3 equal size chunks.

SumTotalPay_ordered_split <- split(SumTotalPay_ordered, rep(1:3, each = 17))
SumTotalPay1 <- SumTotalPay_ordered_split$'1'
SumTotalPay2 <- SumTotalPay_ordered_split$'2'
SumTotalPay3 <- SumTotalPay_ordered_split$'3'

#Now let's look at how the states compare using graphs.

SumTotalPay1_plot <- ggplot(data = SumTotalPay1, aes(x = reorder(Provider_State, MeanTotalPay), y = MeanTotalPay)) + geom_point()
SumTotalPay2_plot <- ggplot(data = SumTotalPay2, aes(x = reorder(Provider_State, MeanTotalPay), y = MeanTotalPay)) + geom_point()
SumTotalPay3_plot <- ggplot(data = SumTotalPay3, aes(x = reorder(Provider_State, MeanTotalPay), y = MeanTotalPay)) + geom_point()


#These plots are all on a different scale, so let's change the y axes

SumTotalPay1_plot <- SumTotalPay1_plot + ylim(7500, 15000)
SumTotalPay2_plot <- SumTotalPay2_plot + ylim(7500, 15000)
SumTotalPay3_plot <- SumTotalPay3_plot + ylim(7500, 15000)

#Now that the scale is correct, let's fix the lables

SumTotalPay1_plot <- SumTotalPay1_plot + labs(x = "State")
SumTotalPay2_plot <- SumTotalPay2_plot + labs(x = "State")
SumTotalPay3_plot <- SumTotalPay3_plot + labs(x = "State")

#These graphs are great, but let's put them together for easier analysis

State_total_sum <- grid.arrange(SumTotalPay1_plot, SumTotalPay2_plot, SumTotalPay3_plot, nrow = 1)

#Now, this graph is looking at payments made by both Medicare and the patient.  Let's see if anything changes when we look at patient payment

SumPatientPay <- payment %>% group_by(Provider_State) %>% summarize(MeanPatientPay = mean(Average_Patient_Payments))
SumPatientPay_ordered <- SumPatientPay[order(SumPatientPay$MeanPatientPay) , ]
SumPatientPay_ordered_split <- split(SumPatientPay_ordered, rep(1:3, each = 17))
SumPatientPay1 <- SumPatientPay_ordered_split$'1'
SumPatientPay2 <- SumPatientPay_ordered_split$'2'
SumPatientPay3 <- SumPatientPay_ordered_split$'3'

SumPatientPay1_plot <- ggplot(data = SumPatientPay1, aes(x = reorder(Provider_State, MeanPatientPay), y = MeanPatientPay)) + geom_point()
SumPatientPay2_plot <- ggplot(data = SumPatientPay2, aes(x = reorder(Provider_State, MeanPatientPay), y = MeanPatientPay)) + geom_point()
SumPatientPay3_plot <- ggplot(data = SumPatientPay3, aes(x = reorder(Provider_State, MeanPatientPay), y = MeanPatientPay)) + geom_point()

SumPatientPay1_plot <- SumPatientPay1_plot + ylim(1000, 2000)
SumPatientPay2_plot <- SumPatientPay2_plot + ylim(1000, 2000)
SumPatientPay3_plot <- SumPatientPay3_plot + ylim(1000, 2000)

SumPatientPay1_plot <- SumPatientPay1_plot + labs(x = "State")
SumPatientPay2_plot <- SumPatientPay2_plot + labs(x = "State")
SumPatientPay3_plot <- SumPatientPay3_plot + labs(x = "State")

State_patient_sum <- grid.arrange(SumPatientPay1_plot, SumPatientPay2_plot, SumPatientPay3_plot, nrow = 1)

#Let's see how this all compares with the range of the Average Covered Charges (aka what the hospital actually bills)
Facility_charge_sum <- payment %>% group_by(Provider_State) %>% summarize(MeanFacilityCharge = mean(Average_Covered_Charges))
min(Facility_charge_sum$MeanFacilityCharge)
max(Facility_charge_sum$MeanFacilityCharge)

min(payment$Average_Covered_Charges)
max(payment$Average_Covered_Charges)

min(payment$Average_Total_Payments)
max(payment$Average_Total_Payments)

min(payment$Average_Patient_Payments)
max(payment$Average_Patient_Payments)


#Lastly we can look at how price varies by total discharge

ggplot(data = payment, aes(x = Average_Patient_Payments, y = Total_Discharges )) + geom_point()
