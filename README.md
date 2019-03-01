# Knowledge Is Savings Capstone

Find the final application here: https://rmarciano.shinyapps.io/MedicarePatientPricing/

This project calculates average patient Medicare out of pocket costs for the top 100 inpatient DRG codes in the US, creating an interactive Shiny application that can be used to help determine affordable counties for Medicare patients.

Under the Code folder you can find all the code used for this project.  The first step was to clean the data and create the data sets needed.  This code can be found under Data Cleaning.R.

After cleaning the data I ran basic statistical analysis by state to see differences in Medicare costs versus patient costs.  This analysis can be found in Statistical Analysis.R.

The next step was to create a model to predict average patient out pocket.  I tried a linear regression first.  After finding that the data did not fit a linear model, I attempted to use CART.  The model still didn't perform very well, so I created a binary variable for patient out of pocket costs (under $1000 and over $1000) and used the CART model to predict the binary variable.  These predictive models can be found under Statistical Models.R.

Finally I created the interactive Shiny application.  The app can be viewed at the link above.  The code for the app can be found under app.R.

The Data folder houses all the datasets for this project.  Medicare Pricing.csv is the original dataset obtained from cms.gov.  Capstone_Project_Tidy_Data.csv is the dataset after intial cleaning.  County Merged.geojson is the shape file containing county polygon boundaries and average patient pricing by county to create the interactive map.  County Patient Payment.csv is a dataset of average patient costs by county and DRG code to create the graph in the second tab of the application. zip_code_database.csv is a dataset that contains a list of zip codes, counties, latitudes, and longitudes. Payment Zip.csv contains all information housed in Capstone_Project_Tidy_Data.csv joined with zip_code_database.csv.  gz_2010_us_040_00_5m.json and gz_2010_us_050_00_5m.json are the original shape files from the US census for county and state boundaries.

The final report for the project can be found under Knowledge_is_Savings_Final_Report.md and the accompany slide deck is under Knowledge is Savings Slide Deck.pptx.  Knowledge_is_Savings_Final_Report_files/figure-markdown_strict contains the images used for the final report.
