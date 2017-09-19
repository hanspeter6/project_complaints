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
library(shinythemes)

shinyUI(navbarPage("COMPLAINTS ANALYSIS",
                   theme = shinytheme("flatly"),
                   inverse = FALSE,
                   tabPanel("Sentiment Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            
                                            h4("Documentation"),
                                            helpText("This section reflects relative sentiments
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
                                                         choices = c("All", "Yes", "No"),
                                                         selected = "All",
                                                         inline = TRUE),
                                            
                                            radioButtons(inputId = "period",
                                                         label = "Period: ",
                                                         choices = c("Day", "Month"),
                                                         inline = TRUE),
                                            
                                            submitButton("Submit")),
                                    
                                    
                                    mainPanel(
                                            plotlyOutput("histPlot"),
                                            br(),
                                            br(),
                                            plotlyOutput("linePlot")
                                    ))),
                   
                   tabPanel("Topic Analysis",
                            sidebarLayout(
                                    
                                    sidebarPanel(
                                            width = 4,
                                            
                                            h4("DESCRIPTION"),
                                            
                                            helpText("In this section between two and five topics can be considered.
                                                     The algorithm that is applied to the dataset that
                                                     has been filtered in the 'Sentiment Analysis' section is the
                                                     Latent Deriche Allocation (LDA), which generates term topic probabilities (betas)
                                                     as well as document topic proportions (gammas)."),
                                            helpText("The first plot shows the top 15 terms per topic as per the term topic proportions (beta)"),
                                            helpText("The second plot reflects the log2 ratios of two topics that can be selected in the menu below.
                                                     For greater readablity, the ratios have been applied only to beta values > 0.007."),
                                            
                                            h6("_________________________________________________________"),
                                            
                                            h4("FILTERS IN PLACE"),
                                            
                                            textOutput("prod"),
                                            
                                            textOutput("dateRangeText"),
                                            
                                            textOutput("comp"),
                                            
                                            h6("_________________________________________________________"),
                                            
                                            h4("INPUT"),
                                            
                                            radioButtons(inputId = "k",
                                                         label = "Number of Topics:",
                                                         choices = c(2,3,4,5),
                                                         selected = 2,
                                                         inline = TRUE),
                                            
                                            uiOutput("allPairs"),
                                            
                                            submitButton("Apply Changes")
                                            
                                    ),
                                    
                                    
                                    mainPanel(
                                            
                                            plotOutput("topicPlot"),
                                            
                                            br(),
                                            
                                            br(),
                                            
                                            plotOutput("biPlot")
                                    ))),
                   
                   tabPanel("Sample Analysis",
                            sidebarLayout(
                                    sidebarPanel(
                                            
                                            h4("DESCRIPTION"),

                                            helpText("In this section you can explore particular
                                               complaints."),

                                            helpText("The complaint is reproduced and the sentiment
                                                     scores for particular words are reflected in a table on the right."),

                                            helpText("The total sentiment score as well as the percentile
                                                     with regard to filtered list of complaints are shown in the results below."),

                                            helpText("Finally, based on the number of topics selected, the complaint is considered
                                                     in terms of the relative allocation by topic"),

                                            helpText("First you need to indicate the source of the particular complaint to analyse.
                                                     You can select from the following options: "),


                                            helpText("a) a random complaint from the filtered subset of complaints;"),

                                            helpText("b) any complaint from the full set of complaints by their IDs;"),

                                            helpText("c) an entry of your own."),
                                            
                                            h6("_________________________________________________________"),
                                            
                                            h4("FILTERS IN PLACE"),
                                            
                                            textOutput("prod2"),
                                            
                                            textOutput("dateRangeText2"),
                                            
                                            textOutput("comp2"),

                                            textOutput("top"),
                                            
                                            h6("_________________________________________________________"),
                                            
                                            h4("INPUTS"),
                                            
                                            helpText("First indicate your Sampling Method before entering the additional
                                               data."),

                                            br(),

                                            helpText("Please note: For repeated random sampling, it is necessary to
                                               submit one of the two other alternatives before generating a
                                               new random selection"),

                                            br(),
                                            
                                            radioButtons(inputId = "radbut",
                                                         label = "Sampling Method: ",
                                                         choices = c("Random", "ID", "Own"),
                                                         inline = TRUE),
                                            
                                            br(),
                                            
                                            textInput(inputId = "text",
                                                      label = "Copy Own Sample Here:"),
                                            
                                            br(),
                                            
                                            numericInput(inputId = "idno",
                                                         label = "Select an ID number between 1 and 20,000)",
                                                         min = 1,
                                                         max = 20000,
                                                         value = 5),
                                            
                                            br(),
                                            
                                            submitButton("Submit"),
                                            
                                            h6("_________________________________________________________"),
                                            
                                            h4("RESULTS"),
                                            
                                            helpText("Total Sentiment Score: "),
                                            textOutput("sentiment"),
                                            
                                            br(),
                                            
                                            helpText("Percentile: "),
                                            textOutput("percentile"),
                                            
                                            br(),
                                            
                                            helpText("Topic Probabilities: "),
                                            
                                            tableOutput("gammas")),
                                    
                                    mainPanel(
                                            verbatimTextOutput("myText"),
                                            tableOutput("myTable")
                                    )))
))

