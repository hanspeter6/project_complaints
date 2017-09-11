# load required packages
library(shiny)
library(tidyverse)
library(tidytext)
library(stringr)
library(lubridate)
library(tm)
library(topicmodels)
library(plotly)
library(ggplot2)

# load the required objects now
complaints_raw <- readRDS("complaints_raw.rds")
complaints_sentiment_negs <- readRDS("complaints_sentiment_negs.rds")
complaints_dtm <- readRDS("complaints_dtm.rds")
top_terms_2 <- readRDS("top_terms_2.rds")
top_terms_3 <- readRDS("top_terms_3.rds")
top_terms_4 <- readRDS("top_terms_4.rds")
top_terms_5 <- readRDS("top_terms_5.rds")

## setting up object for later use


shinyServer(function(input, output) {
        
        ## setting up reactive objects

        # scoring sentiments' bing lexicon
        my_sentiments <- reactive ({
                sentiments %>%
                filter(lexicon == "bing") %>%
                mutate(score = ifelse(sentiment == "positive", 1, -1)) %>%
                select(word, sentiment, score)
        })
        
        # tot sentiment per id
        id_sentiment <- reactive ({
                complaints_sentiment_negs %>%
                group_by(id) %>%
                summarise(tot_sentiment = sum(score))
        })
        
        # target data frame
        df_sentiments <- reactive ({
                complaints_sentiment_negs %>%
                select(-words, - sentiment, -score) %>%
                group_by(id) %>%
                filter(row_number() == 1) %>%
                left_join(id_sentiment()) %>%
                filter(tot_sentiment != 0) %>%
                mutate(sentiment = ifelse(tot_sentiment > 0, "positive", "negative"))
        })
        
        # creating an object based on key inputs (product, compensatin, dates) for 
        # use in other renders
        x <- reactive({
                # product
                if(input$product == "All") {
                        a <- df_sentiments()
                        }
                else {
                        a <- df_sentiments() %>%
                                filter(product == input$product)
                        }
                
                # compensation
                if(input$compensation == "All") {
                        b <- a
                }
                else if(input$compensation == "Yes") {
                        b <- a %>%
                                filter(consumer_compensated == TRUE)
                }
                else if(input$compensation == "No") {
                        b <- a %>%
                                filter(consumer_compensated == FALSE)
                }
                
                # date range
                c <- b %>%
                        filter(date_received > input$dates[1] & date_received < input$dates[2])
                c
        
                })
        
        ## SENTIMENT ANALYSIS
        
        # histogram of sentiments
        output$histPlot <- renderPlotly({
                
                # defining bottom title
                if(input$compensation == "All") {
                        title <- "Total Sentiment: Compensations Paid and Not Paid"
                }
                else if(input$compensation == "Yes") {
                        title <- "Total Sentiments: Compensations Paid" 
                }
                else if(input$compensation == "No") {
                        title <- "Total Sentiments: Compensations Not Paid"
                }
                
                # defining top title
                if(input$product == "All") {
                        top_title <- "Products: All"
                }
                if(input$product == "Mortgage") {
                        top_title <- "Product: Mortgages"
                }
                if(input$product == "Credit card") {
                        top_title <- "Product: Credit Cards"
                }
                if(input$product == "Debt collection") {
                        top_title <- "Product: Debt Collections"
                }
                if(input$product == "Credit reporting") {
                        top_title <- "Product: Credit Reporting"
                }
                if(input$product == "Bank account or service") {
                        top_title <- "Product: Bank Account or service"
                }
  
                ggplotly(ggplot(x(), aes(tot_sentiment, fill = sentiment)) + 
                        geom_histogram(binwidth = 1) +
                        xlab(title) +
                        ylab("Complaints") +
                        labs(title = top_title) +
                        scale_fill_discrete(name="sentiment",
                                            labels=c("negative", "positive")) +
                        xlim(c(-20,20)))
                
                
        })
        
        # reactives for lineplot
        for_graph_day <- reactive({
                x() %>%
                mutate(sentiment_number = ifelse(sentiment == "positive", 1, 0)) %>%
                group_by(date_received) %>%
                summarise(ave_day = mean(tot_sentiment),
                          tot_day = n(),
                          tot_pos = sum(sentiment_number),
                          prop_neg = 1 - tot_pos/tot_day,
                          sum_day = sum(tot_sentiment))
        })
        
        for_graph_month <- reactive({
                x() %>%
                mutate(sentiment_number = ifelse(sentiment == "positive", 1, 0)) %>%
                group_by(month) %>%
                summarise(ave_month = mean(tot_sentiment),
                          tot_month = n(),
                          tot_pos = sum(sentiment_number),
                          prop_neg = 1 - tot_pos/tot_month,
                          sum_month = sum(tot_sentiment))
        })
        
        # bubble plot
        output$linePlot <- renderPlotly({
                
                if(input$period == "Day"){
                        ggplotly(qplot(date_received, tot_day, col = prop_neg, data = for_graph_day(),
                      xlab = "Date", ylab = "Total Complaints Received"))
                        
                }
                
                else if(input$period == "Month") {
                        ggplotly(qplot(month, tot_month, size = ave_month, col = prop_neg, data = for_graph_month(),
                              xlab = "Date", ylab = "Total Complaints Received"))
                        
                }

        })
        
        ## TOPIC ANALYSIS
        
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
        
        ## SAMPLE ANALYSIS
        
        # define specific complaint to work on
        complaint <- reactive({
                if(input$radbut == "Own") {input$text}
                else if(input$radbut == "Random") {
                        complaints_raw$consumer_complaint_narrative[sample(1:20000, 1)]}
                else if(input$radbut == "ID") {complaints_raw$consumer_complaint_narrative[input$idno]}
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
                left_join(my_sentiments(), by = c("words" = "word")) %>%
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
                print(c('Total Sentiment Score', id_scores()$tot_sentiment))
        })
        
        output$percentile <- renderText({
                
                # print out the percentile
                percentile <- ecdf(complaints_sentiments$tot_sentiment)
                target <- percentile(id_scores()$tot_sentiment)
                print(c('Percentile: ', round(target*100)))
        })
        
        
})
