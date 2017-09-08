#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(tidytext)
library(stringr)
library(lubridate)
library(tm)
library(topicmodels)

# load the required objects
complaints_sentiments <- readRDS("complaints_sentiments.rds")
complaints_dtm <- readRDS("complaints_dtm.rds")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  output$histPlot <- renderPlot({
    
    # generate histograms of total sentiment created input$product from ui.R
          # product select
          if(input$product == "All") {
                  x <- complaints_sentiments
          }
          else {
                  x <- complaints_sentiments %>%
                          filter(product == input$product)  
          }
          
          # # compensation or not
          # if(input$compensation == "Yes & No") {
          #         x <- x 
          # }
          # else if(input$compensation == "Yes") {
          #         x <- x %>%
          #                 filter(consumer_compensated == TRUE)
          # }
          # else if(input$compensation == "No") {
          #         x <- x %>%
          #                 filter(consumer_compensated == FALSE)
          # }
          
          # dealing with date range
          x <- x %>% filter(date_received > input$dates[1] & date_received < input$dates[2])

    ggplot(x, aes(tot_sentiment, fill = consumer_compensated)) + 
            geom_histogram(binwidth = 2) +
            xlab("Total Sentiment") +
            ylab("Complaints") +
            scale_fill_discrete(name="compensated",
                                labels=c("No", "Yes")) +
            xlim(c(-20,20))
    
  })
  
  output$topicPlot <- renderPlot({
          
          # Doing LDA. k = number of topics (need to generalise this for k = 2 - 5)
          set.seed(56)
          complaints_lda <- LDA(complaints_dtm, k = input$k)
              
          # consider the beta parameters (ie the probabilities of a given topic k generating a particular word i)
          # gamma: this gives the topic "mixtures" for each document.
          
          # first consider the beta parameters
          complaints_topics <- tidy(complaints_lda, matrix = "beta")
          
          # extract top 15 terms in each topic and arrange and plot
          top_terms <- complaints_topics %>%
                  group_by(topic) %>%
                  top_n(15, beta) %>%
                  ungroup() %>%
                  arrange(topic, -beta)
          
          top_terms %>%
                  mutate(term = reorder(term, beta)) %>%
                  ggplot(aes(term, beta, fill = factor(topic))) +
                  geom_col(show.legend = FALSE) +
                  facet_wrap(~ topic, scales = "free") +
                  coord_flip()
          
  })
  
  
  output$myText <- renderText({
          
          # trying to display my textinput
          print(input$text)
          
  })
  
  output$sentiment <- renderText({
          
          # Sentiment score
          
          # create table:
          tab <- data.frame(id = 21000, complaint = input$text)
          tab$complaint <- as.character(tab$complaint)
          
          # a word unigram list of words
          my_list <- unnest_tokens(tab, output = words, input = complaint, token = "words")
          
          # get rid of stopwords
          my_list2 <- my_list %>%
                  filter(!words %in% stopwords(), str_detect(words, "[a-z]"))
          
          # add sentiment score column to the word_list frame
          
          my_sentiments <- sentiments %>%
                  filter(lexicon == "bing") %>%
                  mutate(score = ifelse(sentiment == "positive", 1, -1)) %>%
                  select(word, sentiment, score)
          
          words_list_sentiment <- my_list2 %>%
                  left_join(my_sentiments, by = c("words" = "word")) %>%
                  filter(!is.na(sentiment)) %>%
                  group_by(id) %>%
                  mutate(tot_sentiment = sum(score)) %>%
                  ungroup()
          
          id_scores <- words_list_sentiment %>%
                  group_by(id) %>%
                  summarise(tot_sentiment = mean(tot_sentiment))
          
          # now want the quantile of the score of the new complaint:
          
          percentile <- ecdf(complaints_sentiments$tot_sentiment)
          target <- percentile(id_scores$tot_sentiment)
          
          out <- c(as.character(id_scores$tot_sentiment), as.character(target))
          print(out)
 
          # now want to get topic probabilities..(gamma) for the my new complaint
          #  fuck...
          
  })
  
  
})
