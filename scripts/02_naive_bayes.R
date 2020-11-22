library(tidyverse)
library(tidytext)
library(caret)
library(here)


# read datasets -----------------------------------------------------------

headlines_20min <-
  read_csv(here("data", "headlines_20min.csv")) %>%
  mutate(source = "20min")

headlines_nzz <-
  read_csv(here("data", "headlines_nzz.csv")) %>%
  mutate(source = "nzz")

# source: https://github.com/solariz/german_stopwords/blob/master/german_stopwords_plain.txt
stop_words_german <-
  read_csv(here("data", "stop_words_german.txt"), col_names = c("word"))

# Combine the two datasets
headlines <-
  bind_rows(headlines_20min, headlines_nzz) %>%
  mutate(headlines_id = 1:n())

# remove replicates and split text in order to have one word per line
headlines_tidy <-
  headlines %>%
  distinct(object, text, source) %>%
  unnest_tokens(word, text) 

# create vocabulary
vocabulary <-
  headlines_tidy %>%
  count(word, sort = TRUE) %>%
  mutate(vocabulary_id = 1:n())

vocabulary_without_stop_words <-
  headlines_tidy %>%
  anti_join(stop_words_german, by = "word") %>%
  count(word, sort = TRUE) %>%
  mutate(vocabulary_id = 1:n())
  

# split training and test data --------------------------------------------

train_fraction <- 0.75

set.seed(20201122)
train <-
  headlines %>%
  sample_frac(train_fraction)

test  <- 
  headlines %>%
  anti_join(train, by = "headlines_id")


# calculate priors --------------------------------------------------------

prior_prob_20min <-
  train %>%
  filter(source == "20min") %>%
  nrow() / nrow(train)

prior_prob_nzz <-
  train %>%
  filter(source == "nzz") %>%
  nrow() / nrow(train)

# because we only have two classes, those two probabilities have to sum to 1
prior_prob_20min + prior_prob_nzz


# calculate class conditional probabilities -------------------------------

cond_prob_20min <-
  train %>%
  filter(source == "20min") %>%
  select(text) %>%
  unnest_tokens(word, text) %>%
  # add 1 instance of each word from vocabulary to avoid probability of 0
  # when a word not present in training set appears
  bind_rows(select(vocabulary, word)) %>%
  count(word) %>%
  mutate(prob = n/sum(n))

cond_prob_nzz <-
  train %>%
  filter(source == "nzz") %>%
  select(text) %>%
  unnest_tokens(word, text) %>%
  # add 1 instance of each word from vocabulary to avoid probability of 0
  # when a word not present in training set appears
  bind_rows(select(vocabulary, word)) %>%
  count(word) %>%
  mutate(prob = n/sum(n))


# calculate scores for example headline -----------------------------------

headline <- tibble(text = "Grosse Rettungsaktion, weil sich mehrere Personen verirrt haben")

headline_tidy <-
  headline %>%
  unnest_tokens(word, text)

# create score of headline for each class
score_20min <-
  headline_tidy %>%
  left_join(cond_prob_20min, by = "word") %>%
  pull(prob) %>%
  prod() * prior_prob_20min

score_nzz <-
  headline_tidy %>%
  left_join(cond_prob_nzz, by = "word") %>%
  pull(prob) %>%
  prod() * prior_prob_nzz

# compare scores to determine the larger (=predicted class)
score_20min > score_nzz


# predict class of test data ----------------------------------------------

test_predictions <-
  test %>%
  select(headlines_id, text, source) %>%
  unnest_tokens(word, text) %>%
  left_join(cond_prob_20min, by = "word") %>%
  rename(prob_20min = prob) %>%
  left_join(cond_prob_nzz, by = "word") %>%
  rename(prob_nzz = prob) %>%
  group_by(headlines_id) %>%
  summarise(score_20min = prod(prob_20min) * prior_prob_20min,
            score_nzz = prod(prob_nzz) * prior_prob_nzz) %>%
  mutate(source_predicted = if_else(score_20min > score_nzz, true = "20min", false = "nzz"))


# compare label and prediction of test data -------------------------------

test_label <- as_factor(test$source)
test_prediction <- as_factor(test_predictions$source_predicted)

confusionMatrix(test_prediction, test_label)

accuracy <- mean(test_label == test_prediction)
