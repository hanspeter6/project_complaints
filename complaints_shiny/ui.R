#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

shinyUI(navbarPage("COMPLAINTS ANALYSIS",
                   inverse = TRUE,
                   tabPanel("Sentiment Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            
                                            selectInput(inputId = "product",
                                                        label = "Select Product:",
                                                        choices = c("All", "Mortgage", "Credit card", "Debt collection", "Credit reporting", "Bank account or service"),
                                                        selected = "All"),
                                            
                                            dateRangeInput(inputId = "dates",
                                                           label = "Date Range:",
                                                           start =  "2015-03-19",
                                                           end = "2016-04-20",
                                                           min = "2015-03-19",
                                                           max = "2016-04-20"),
                                            
                                            radioButtons(inputId = "compensation",
                                                         label = "Compensation Paid:",
                                                         choices = c("All", "Yes", "No"),
                                                         selected = "All",
                                                         inline = TRUE),
                                            
                                            submitButton("Submit")),
                                    
                                    
                                    mainPanel(
                                            plotOutput("histPlot")
                                    ))),
                   
                   tabPanel("Topic Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            width = 2,
                                            radioButtons(inputId = "k",
                                                         label = "Number of Topics:",
                                                         choices = c(2,3,4,5),
                                                         selected = 2,
                                                         inline = FALSE),
                                            submitButton("Submit")),
                                    mainPanel(
                                            plotOutput("topicPlot")
                                    ))),
                   
                   tabPanel("Sample Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            
                                            radioButtons(inputId = "radbut",
                                                         label = "Select Sampling",
                                                         choices = c("ID", "Random", "Own"),
                                                         inline = TRUE),
                                            
                                            textInput(inputId = "text",
                                                      label = "Copy Own Sample Here:"),
                                            
                                            numericInput(inputId = "idno",
                                                         label = "ID number from 1 to 20 000)",
                                                         min = 1,
                                                         max = 20000,
                                                         value = 5),

                                            submitButton("Submit")),
                                            
                                     mainPanel(
                                            verbatimTextOutput("myText"),
                                            tableOutput("myTable"),
                                            h5("Total Sentiment Score:"),
                                            textOutput("sentiment"),
                                            h5("Percentile:"),
                                            textOutput("percentile")
                                    )))
))

