#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

shinyUI(navbarPage("My Application",
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
                                            submitButton("Apply Changes", icon("refresh"))),
                                    mainPanel(
                                            plotOutput("histPlot")
                                    ))),
                   
                   tabPanel("Topic Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            numericInput(inputId = "k",
                                                         label = "Number of Topics:",
                                                         value = 2,
                                                         min = 2,
                                                         max = 5,
                                                         step = 1),
                                            submitButton("Apply Changes", icon("refresh"))),
                                    mainPanel(
                                            plotOutput("topicPlot")
                                    ))),
                   
                   tabPanel("Sample Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            textInput(inputId = "text",
                                                      label = "Write your Complaint here:",
                                                      width = 'auto'),
                                            submitButton("Apply Changes", icon("refresh"))),
                                    mainPanel(
                                            verbatimTextOutput("myText"),
                                            textOutput("sentiment")
                                    )))
))

