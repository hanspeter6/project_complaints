#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:as
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)

shinyUI(navbarPage("COMPLAINTS ANALYSIS",
                   inverse = TRUE,
                   tabPanel("Sentiment Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            
                                            h4("Documentation"),
                                            h6("This section reflects relative sentiments
                                               of complaints related to various products etc..."),
                                            h4("How it works"),
                                            h6("A user can select any or all the products shown in the
                                               drop down menu selection below. A change in the graphic will only reflect
                                               on clicking the 'Submit' button below. One can select a date range as well
                                               as indicating whether you want to consider only those complaints that led
                                               to complensation"),
                                            
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
                                                         choices = c("Yes & No", "Yes", "No"),
                                                         selected = "Yes & No",
                                                         inline = TRUE),
                                            
                                            radioButtons(inputId = "period",
                                                         label = "Period: ",
                                                         choices = c("Day", "Month"),
                                                         inline = TRUE),
                                            
                                            submitButton("Submit")),
                                    
                                    
                                    mainPanel(
                                            plotlyOutput("histPlot"),
                                            plotlyOutput("linePlot")
                                    ))),
                   
                   tabPanel("Topic Analysis",
                            sidebarLayout(
                                    
                                    sidebarPanel(
                                            width = 3,
                                            
                                            h4("Documentation"),
                                            h6("blah blah"),
                                            h4(" How it works"),
                                            h6("blah, blah"),
                                          
                                            radioButtons(inputId = "k",
                                                         label = "Number of Topics:",
                                                         choices = c(2,3,4,5),
                                                         selected = 2,
                                                         inline = TRUE),
                                            
                                            h3("try tester"),
                                            
                                            uiOutput("allPairs"),
                                            
                                            submitButton("Apply Changes")
                                            
                                            ),
                                            
                                                
                                    mainPanel(
                                            
                                            plotOutput("topicPlot"),
                                            verbatimTextOutput("prod"),
                                            verbatimTextOutput("dateRangeText"),
                                            verbatimTextOutput("comp"),
                                            plotOutput("biPlot")
                                    ))),
                   
                   tabPanel("Sample Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            
                                            h4("INPUTS"),

                                            
                                            radioButtons(inputId = "radbut",
                                                         label = "Sampling Method",
                                                         choices = c("Random", "ID", "Own"),
                                                         inline = TRUE),
                                            
                                            textInput(inputId = "text",
                                                      label = "Copy Own Sample Here:"),
                                            
                                            numericInput(inputId = "idno",
                                                         label = "ID number from 1 to 20 000)",
                                                         min = 1,
                                                         max = 20000,
                                                         value = 5),
                                            
                                            submitButton("Submit"),
                                            
                                            h4("SUMMARY RESULTS"),
                                            
                                            textOutput("sentiment"),
                                            
                                            textOutput("percentile"),
                                            
                                            h3("Topic Probabilities"),
                                            tableOutput("gammas")),
                                    
                                    mainPanel(
                                            verbatimTextOutput("myText"),
                                            tableOutput("myTable")
                                    )))
                            ))

