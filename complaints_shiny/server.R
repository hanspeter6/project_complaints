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
complaints_tdf <- readRDS("complaints_tdf.rds")

# server functions
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
                if(input$compensation == "Yes & No") {
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
                if(input$compensation == "Yes & No") {
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
        
        complaints_dtm <- reactive({
                complaints_tdf %>%
                        filter(id %in% x()$id) %>%
                        cast_dtm(id, words, n)
        })
        
        complaints_lda_2 <- reactive({
                set.seed(56)
                LDA(complaints_dtm(), k = 2)
        })
        
        complaints_lda_3 <- reactive({
                set.seed(56)
                LDA(complaints_dtm(), k = 3)
        })
        
        complaints_lda_4 <- reactive({
                set.seed(56)
                LDA(complaints_dtm(), k = 4)
        })
        
        complaints_lda_5 <- reactive({
                set.seed(56)
                LDA(complaints_dtm(), k = 5)
        })
        
        top_terms_2 <- reactive({
                tidy(complaints_lda_2(), matrix = "beta") %>%
                        group_by(topic) %>%
                        top_n(15, beta) %>%
                        ungroup() %>%
                        arrange(topic, -beta) %>%
                        mutate(term = reorder(term, beta))
        })
        top_terms_3 <- reactive({
                tidy(complaints_lda_3(), matrix = "beta") %>%
                        group_by(topic) %>%
                        top_n(15, beta) %>%
                        ungroup() %>%
                        arrange(topic, -beta) %>%
                        mutate(term = reorder(term, beta))
        })
        top_terms_4 <- reactive({
                tidy(complaints_lda_4(), matrix = "beta") %>%
                        group_by(topic) %>%
                        top_n(15, beta) %>%
                        ungroup() %>%
                        arrange(topic, -beta) %>%
                        mutate(term = reorder(term, beta))
        })
        top_terms_5 <- reactive({
                tidy(complaints_lda_5(), matrix = "beta") %>%
                        group_by(topic) %>%
                        top_n(15, beta) %>%
                        ungroup() %>%
                        arrange(topic, -beta) %>%
                        mutate(term = reorder(term, beta))
        })
        
        
        output$topicPlot <- renderPlot({
                
                # define plot input:
                if(input$k == 2) {
                        topicPlot <- top_terms_2()
                }
                if(input$k == 3) {
                        topicPlot <- top_terms_3()
                }
                if(input$k == 4) {
                        topicPlot <- top_terms_4()
                }
                if(input$k == 5) {
                        topicPlot <- top_terms_5()
                }
                
                #plot
                ggplot(topicPlot, aes(term, beta, fill = factor(topic))) +
                        geom_col(show.legend = FALSE) +
                        facet_wrap(~ topic, scales = "free") +
                        coord_flip()
                
        })
        
        
        output$prod <- renderText({
                paste("Product: ",
                      input$product)
        })
        
        output$dateRangeText  <- renderText({
                paste("Date Range: ", 
                      paste(as.character(input$dates), collapse = " to ")
                )
        })
        
        output$comp <- renderText({
                paste("Compensation Paid: ",
                      input$compensation)
        })
        
        
        # biplots
        
        beta_spread_2 <- reactive({
                complaints_lda_2() %>%
                        tidy(matrix = "beta") %>%
                        mutate(topic = paste0("topic", topic)) %>%
                        spread(topic, beta)
                
        })
        
        beta_spread_3 <- reactive({
                complaints_lda_3() %>%
                        tidy(matrix = "beta") %>%
                        mutate(topic = paste0("topic", topic)) %>%
                        spread(topic, beta)
                
        })
        
        beta_spread_4 <- reactive({
                complaints_lda_4() %>%
                        tidy(matrix = "beta") %>%
                        mutate(topic = paste0("topic", topic)) %>%
                        spread(topic, beta)
                
        })
        
        beta_spread_5 <- reactive({
                complaints_lda_5() %>%
                        tidy(matrix = "beta") %>%
                        mutate(topic = paste0("topic", topic)) %>%
                        spread(topic, beta)
                
        })
        
        output$allPairs <- renderUI({
                t <- combinat::combn2(1:input$k)
                v <- vector()
                for(i in 1: nrow(t)) {
                        c <- as.character(t[i,])
                        cvec <- paste("Topics", c[1], "&", c[2])
                        v <- append(v, cvec)
                }
                radioButtons("pairs", "Choose Topic Pair", v)
        })
        
        output$biPlot <- renderPlot({
                
                # now need to select two topics eg topic 1, topic 2:
                
        
                
                # and set up graph dataset
                
                
                
                input <- c(paste0("topic", 1), paste0("topic", 2))
                
                topic_pairs_df <- beta_spread_2() %>%
                        select(term, input[1], input[2])
                
                bigBeta <- topic_pairs_df[topic_pairs_df[,2] > 0.007 | topic_pairs_df[,3] > 0.007,]
                
                log_ratio <- log2(bigBeta[,3]/bigBeta[,2])
                
                pairs <- bigBeta %>%
                        mutate(log_ratio = log_ratio[,1]) %>%
                        group_by(direction = log_ratio > 0) %>%
                        top_n(10, abs(log_ratio)) %>%
                        ungroup() %>%
                        mutate(term = reorder(term, log_ratio))
                
                # and plot it
                ggplot(pairs, aes(term, log_ratio)) +
                        geom_col() +
                        labs(y = "Log2 ratio of beta in topic 3 / topic 2") +
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
        
        ## clean and create wordlist for use in sentiment and topic analysis
        
        # replace non-alphabetical characters with space
        complaint_clean <- reactive({
                complaint() %>%
                        str_replace_all("[^A-Za-z]", " ") %>%
                        str_replace_all("X", "")
        })
        
        # create a table for use in unnest_tokens, ensuring 
        tab_sample <- reactive({
                data.frame(id = 21000, complaint = complaint_clean(), stringsAsFactors = FALSE)
        })
        
        # then a word unigram list of words, getting rid of stopwords
        sample_list <- reactive({
                unnest_tokens(tab_sample(), output = words, input = complaint, token = "words") %>%
                        filter(!words %in% stopwords(), str_detect(words, "[a-z]")) %>%
                        filter(!words %in% c("etc", "re", letters))
        })
        
        # create tdf:
        complaint_sample_tdf <- reactive({
                sample_list() %>%
                        group_by(id, words) %>%
                        count() %>%
                        ungroup()
        })
        
        # create doc term matrix
        complaint_sample_dtm <- reactive({
                complaint_sample_tdf() %>%
                        cast_dtm(id, words, n)
        })
        
        # add sentiment score column to the word_list frame
        words_list_sentiment <- reactive({
                sample_list() %>%
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
                print(id_scores()$tot_sentiment)
        })
        
        output$percentile <- renderText({
                
                # print out the percentile
                percentile <- ecdf(df_sentiments()$tot_sentiment)
                target <- percentile(id_scores()$tot_sentiment)
                print(round(target*100))
        })
        
        output$gammas <- renderTable(digits = 2, {
                
                # identify lda object for k = no of topics
                if(input$k == 2) {
                        lda <- complaints_lda_2()
                }
                if(input$k == 3) {
                        lda <- complaints_lda_3()
                }
                if(input$k == 4) {
                        lda <- complaints_lda_4()
                }
                if(input$k == 5) {
                        lda <- complaints_lda_5()
                }
                
                # 
                ts <- posterior(lda, complaint_sample_dtm())
                q <- data.frame(Topic = 1:input$k, Proportion = ts[[2]][1,])
                print(q)
                
                
        })
        
        
})
