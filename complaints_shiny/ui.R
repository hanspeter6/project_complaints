#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Complaints"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
        helpText("Select a Product"),
        selectInput(inputId = "product",
                    label = "Select Product:",
                    choices = c("All", "Mortgage", "Credit card", "Debt collection", "Credit reporting", "Bank account or service"),
                    selected = "All"),
            
        helpText("Select a Date Range"),
        dateRangeInput(inputId = "dates",
                       label = "Date Range:",
                       start =  "2015-03-19",
                       end = "2016-04-20",
                       min = "2015-03-19",
                       max = "2016-04-20"),
        
        helpText("Select a Number of Topics"),
        numericInput(inputId = "k",
                     label = "Number of Topics:",
                     value = 2,
                     min = 2,
                     max = 5,
                     step = 1),
        
        helpText("Test a Sample Complaint Here"),    
        textInput(inputId = "text",
                  label = "Write your Complaint here:",
                  width = 'auto'),
        
        helpText("To Submit your Selections"),
        submitButton("Apply Changes", icon("refresh"))),
    
    # Show a plot of the generated distribution
    mainPanel(
            tabsetPanel(
                    tabPanel("Sentiment", plotOutput("histPlot")),
                    tabPanel("Topic", plotOutput("topicPlot")),
                    tabPanel("Sample",
                             verbatimTextOutput("myText"),
                             helpText("Sentiment Score $ Percentile"),
                             textOutput("sentiment"))
            )
    )

  )
))
