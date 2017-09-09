# load required packages
library(shiny)
library(tidyverse)
library(tidytext)
library(stringr)
library(lubridate)
library(tm)
library(topicmodels)

# load the required objects now
complaints <- readRDS("complaints.rds")
complaints_sentiments <- readRDS("complaints_sentiments.rds")
complaints_dtm <- readRDS("complaints_dtm.rds")
top_terms_2 <- readRDS("top_terms_2.rds")
top_terms_3 <- readRDS("top_terms_3.rds")
top_terms_4 <- readRDS("top_terms_4.rds")
top_terms_5 <- readRDS("top_terms_5.rds")

# setting up my_sentiments object for later use
my_sentiments <- sentiments %>%
        filter(lexicon == "bing") %>%
        mutate(score = ifelse(sentiment == "positive", 1, -1)) %>%
        select(word, sentiment, score)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
        
        output$histPlot <- renderPlot({
                
                # product select also
                if(input$product == "All") {
                        x <- complaints_sentiments
                }
                else {
                        x <- complaints_sentiments %>%
                                filter(product == input$product)  
                }
                
                # compensation or not
                if(input$compensation == "All") {
                        x <- x
                }
                else if(input$compensation == "Yes") {
                        x <- x %>%
                                filter(consumer_compensated == TRUE)
                }
                else if(input$compensation == "No") {
                        x <- x %>%
                                filter(consumer_compensated == FALSE)
                }
                
                # date range
                x <- x %>%
                        filter(date_received > input$dates[1] & date_received < input$dates[2])
                
                # plot
                if(input$compensation == "All") {
                        ggplot(x, aes(tot_sentiment, fill = consumer_compensated)) + 
                                geom_histogram(binwidth = 2) +
                                xlab("Total Sentiment") +
                                ylab("Complaints") +
                                scale_fill_discrete(name="compensated",
                                                    labels=c("No", "Yes")) +
                                xlim(c(-20,20))
                }
                else if(input$compensation == "Yes") {
                        ggplot(x, aes(tot_sentiment, fill = consumer_compensated)) + 
                                geom_histogram(binwidth = 2, fill = "#00BFC4") +
                                xlab("Total Sentiment") +
                                ylab("Complaints") +
                                scale_fill_discrete(name="compensated",
                                                    labels=c("Yes")) +
                                xlim(c(-20,20))
                }
                else if(input$compensation == "No") {
                        ggplot(x, aes(tot_sentiment, fill = consumer_compensated)) + 
                                geom_histogram(binwidth = 2, fill = "#F8766D") +
                                xlab("Total Sentiment") +
                                ylab("Complaints") +
                                scale_fill_discrete(name="compensated",
                                                    labels=c("No")) +
                                xlim(c(-20,20))
                }
                
        })
        
        # output$linePlot <- renderPlot({
        #         
        #         
        #         
        # })
        
        
        output$topicPlot <- renderPlot({
                
                # define plot input:
                if(input$k == 2) {
                        topicPlot <- top_terms_2
                }
                if(input$k == 3) {
                        topicPlot <- top_terms_3
                }
                if(input$k == 4) {
                        topicPlot <- top_terms_4
                }
                if(input$k == 5) {
                        topicPlot <- top_terms_5
                }
                
                #plot
                ggplot(topicPlot, aes(term, beta, fill = factor(topic))) +
                        geom_col(show.legend = FALSE) +
                        facet_wrap(~ topic, scales = "free") +
                        coord_flip()
                
        })
        
        
        
        
        ## Some reactive function for Sample Analysis
        
        # define complaint to work on
        complaint <- reactive({
                if(input$radbut == "Own") {input$text}
                else if(input$radbut == "Random") {
                        complaints$consumer_complaint_narrative[sample(1:20000, 1)]}
                else if(input$radbut == "ID") {complaints$consumer_complaint_narrative[input$idno]}
                })
        
        # create table:
        tab <- reactive({
                data.frame(id = 21000, complaint = complaint(), stringsAsFactors = FALSE)
        })
        
        # a word unigram list of words excluding stop words
        my_list <- reactive({
                unnest_tokens(tab(), output = words, input = complaint, token = "words") %>%
                filter(!words %in% stopwords(), str_detect(words, "[a-z]"))
        })
        
        # add sentiment score column to the word_list frame
        words_list_sentiment <- reactive({
                my_list() %>%
                left_join(my_sentiments, by = c("words" = "word")) %>%
                filter(!is.na(sentiment)) %>%
                group_by(id) %>%
                mutate(tot_sentiment = sum(score)) %>%
                ungroup()
        })
        
        id_scores <- reactive({
                words_list_sentiment() %>%
                        group_by(id) %>%
                        summarise(tot_sentiment = mean(tot_sentiment))
                
        })
        
        output$myText <- renderText({
                
                # display text again.. maybe cut this out later
                print(complaint())
                
        })
        
        output$myTable <- renderTable(striped = TRUE, digits = 0, {
                
                # print a table of positive and negative words
                mytable <- words_list_sentiment()
                print(mytable[,c(2,3,4)])
        })
        
        output$sentiment <- renderText({

                # print out the total sentiment score
                print(id_scores()$tot_sentiment)
        })
        
        output$percentile <- renderText({
                
                # print out the percentile
                percentile <- ecdf(complaints_sentiments$tot_sentiment)
                target <- percentile(id_scores()$tot_sentiment)
                print(c(round(target*100), 'th percentile'))
        })
        
        
})
