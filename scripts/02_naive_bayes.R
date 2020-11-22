library(tidyverse)
library(tidytext)
library(caret)
library(magrittr)
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

# Combine the two datasets and only keep unique headlines
headlines <-
  bind_rows(headlines_20min, headlines_nzz) %>%
  distinct(text, source) %>%
  mutate(headlines_id = 1:n())


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


# calculate class conditional probabilities -------------------------------

cond_prob_20min <-
  train %>%
  filter(source == "20min") %>%
  select(text) %>%
  unnest_tokens(word, text) %>%
  count(word) %>%
  mutate(prob = n/sum(n))

cond_prob_20min_wo_stop <-
  train %>%
  filter(source == "20min") %>%
  select(text) %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words_german, by = "word") %>%
  count(word) %>%
  mutate(prob = n/sum(n))


cond_prob_nzz <-
  train %>%
  filter(source == "nzz") %>%
  select(text) %>%
  unnest_tokens(word, text) %>%
  count(word) %>%
  mutate(prob = n/sum(n))

cond_prob_nzz_wo_stop <-
  train %>%
  filter(source == "nzz") %>%
  select(text) %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words_german, by = "word") %>%
  count(word) %>%
  mutate(prob = n/sum(n))


# calculate scores for example headline -----------------------------------

# just an example for a single headline
headline <- tibble(text = "Grosse Rettungsaktion, weil sich mehrere Personen verirrt haben")
# headline <- tibble(text = "Erpressungsversuch gegen Alain Berset: Es geht die Schweiz nichts an, ob der Bundesrat eine Affäre hatte oder nicht. Es zählt eine andere Frage")

headline_tidy <-
  headline %>%
  unnest_tokens(word, text)

# create score of headline for each class
# replace NA in column prob after left_join by 1/sum(n words in training) in order
# to account for a word which was not present in the training set of this class
score_20min <-
  headline_tidy %>%
  left_join(cond_prob_20min, by = "word") %>%
  mutate(prob = replace_na(prob, 1/sum(cond_prob_20min$n))) %>%
  pull(prob) %>%
  prod() * prior_prob_20min

score_nzz <-
  headline_tidy %>%
  left_join(cond_prob_nzz, by = "word") %>%
  mutate(prob = replace_na(prob, 1/sum(cond_prob_nzz$n))) %>%
  pull(prob) %>%
  prod() * prior_prob_nzz

prob_20min <-
  score_20min/(score_20min+score_nzz)

prob_nzz <-
  score_nzz/(score_20min+score_nzz)

# compare probabilities to determine the larger (=predicted class)
prob_20min > prob_nzz


# predict class of test data ----------------------------------------------

test_predictions <-
  test %>%
  select(headlines_id, text, source) %>%
  unnest_tokens(word, text) %>%
  left_join(cond_prob_20min, by = "word") %>%
  mutate(prob = replace_na(prob, 1/sum(cond_prob_20min$n))) %>%
  rename(prob_word_20min = prob) %>%
  left_join(cond_prob_nzz, by = "word") %>%
  mutate(prob = replace_na(prob, 1/sum(cond_prob_nzz$n))) %>%
  rename(prob_word_nzz = prob) %>%
  group_by(headlines_id) %>%
  summarise(score_20min = prod(prob_word_20min) * prior_prob_20min,
            score_nzz = prod(prob_word_nzz) * prior_prob_nzz) %>%
  mutate(prob_20min = score_20min/(score_20min+score_nzz),
         prob_nzz = score_nzz/(score_20min+score_nzz)) %>%
  mutate(source_predicted = if_else(prob_20min > prob_nzz, true = "20min", false = "nzz")) %>%
  left_join(test, by = "headlines_id")


test_predictions_wo_stop <-
  test %>%
  select(headlines_id, text, source) %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words_german, by = "word") %>%
  left_join(cond_prob_20min_wo_stop, by = "word") %>%
  mutate(prob = replace_na(prob, 1/sum(cond_prob_20min_wo_stop$n))) %>%
  rename(prob_word_20min = prob) %>%
  left_join(cond_prob_nzz_wo_stop, by = "word") %>%
  mutate(prob = replace_na(prob, 1/sum(cond_prob_nzz_wo_stop$n))) %>%
  rename(prob_word_nzz = prob) %>%
  group_by(headlines_id) %>%
  summarise(score_20min = prod(prob_word_20min) * prior_prob_20min,
            score_nzz = prod(prob_word_nzz) * prior_prob_nzz) %>%
  mutate(prob_20min = score_20min/(score_20min+score_nzz),
         prob_nzz = score_nzz/(score_20min+score_nzz)) %>%
  mutate(source_predicted = if_else(score_20min > score_nzz, true = "20min", false = "nzz")) %>%
  left_join(test, by = "headlines_id")


# compare label and prediction of test data -------------------------------

test_predictions %$%
  confusionMatrix(as_factor(source_predicted), as_factor(source))

test_predictions_wo_stop %$%
  confusionMatrix(as_factor(source_predicted), as_factor(source))


# analyze misclassified headlines -----------------------------------------
library(ggbeeswarm)

test_predictions %>%
  filter(source_predicted != source) %>%
  select(text, source, source_predicted, prob_20min, prob_nzz) %>%
  pivot_longer(cols = starts_with("prob"), names_to = "prob_source", values_to = "prob") %>%
  ggplot(aes(x = source, y = prob, col = prob_source)) +
  geom_quasirandom()

test_predictions_wo_stop %>%
  filter(source_predicted != source) %>%
  select(text, source, source_predicted, prob_20min, prob_nzz) %>%
  pivot_longer(cols = starts_with("prob"), names_to = "prob_source", values_to = "prob") %>%
  ggplot(aes(x = source, y = prob, col = prob_source)) +
  geom_quasirandom()



test_predictions %>%
  pivot_longer(cols = starts_with("prob"), names_to = "prob_source", values_to = "prob") %>%
  ggplot(aes(x = prob, color = prob_source)) +
  geom_freqpoly()

test_predictions_wo_stop %>%
  pivot_longer(cols = starts_with("prob"), names_to = "prob_source", values_to = "prob") %>%
  ggplot(aes(x = prob, color = prob_source)) +
  geom_freqpoly()



test_predictions %>%
  filter(source_predicted != source,
         source_predicted == "nzz") %>%
  pull(prob_nzz) %>%
  mean()

test_predictions %>%
  filter(source_predicted != source,
         source_predicted == "20min") %>%
  pull(prob_20min) %>%
  mean()


test_predictions_wo_stop %>%
  filter(source_predicted != source,
         source_predicted == "nzz") %>%
  pull(prob_nzz) %>%
  mean()

test_predictions_wo_stop %>%
  filter(source_predicted != source,
         source_predicted == "20min") %>%
  pull(prob_20min) %>%
  mean()
