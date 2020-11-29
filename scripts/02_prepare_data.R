library(tidyverse)
library(tidytext)
library(here)


# read datasets -----------------------------------------------------------
# Only keep unique headlines

headlines_20min <-
  read_csv(here("data", "headlines_20min.csv")) %>%
  select(text, object) %>%
  mutate(source = "20min") %>%
  unique()

headlines_nzz <-
  read_csv(here("data", "headlines_nzz.csv")) %>%
  select(text, object) %>%
  mutate(source = "nzz") %>%
  unique()

# source: https://github.com/solariz/german_stopwords/blob/master/german_stopwords_plain.txt
stop_words_german <-
  read_csv(here("data", "stop_words_german.txt"), col_names = c("word"))

# Combine the two datasets and only keep unique headlines
headlines <-
  bind_rows(headlines_20min, headlines_nzz) %>%
  mutate(headline_id = 1:n())


# create vocabulary -------------------------------------------------------

# define minimum occurrences required for a word to be included in vocabulary
min_word_count <- 2

vocabulary <-
  headlines %>%
  unnest_tokens(word, text) %>%
  count(word, sort = TRUE, name = "word_count") %>%
  rowid_to_column("word_id") %>%
  filter(word_count >= min_word_count)

vocabulary_stop_words <-
  vocabulary %>%
  inner_join(stop_words_german, by = "word") %>%
  select(-word_count)


# split training and test data --------------------------------------------

train_fraction <- 0.75

set.seed(20201122)

train <-
  headlines %>%
  sample_frac(train_fraction) %>%
  arrange(headline_id) %>%
  rowid_to_column("train_id") 

train_labels <-
  train %>%
  select(train_id, source, object)

train_features <-
  vocabulary %>%
  select(word_id, word) %>%
  inner_join(unnest_tokens(train, word, text), by = "word") %>%
  select(train_id, word_id) %>%
  group_by(train_id, word_id) %>%
  summarise(word_count = n())


test  <- 
  headlines %>%
  anti_join(train, by = "headline_id") %>%
  arrange(headline_id) %>%
  rowid_to_column("test_id") 

test_labels <-
  test %>%
  select(test_id, source, object)

test_features <-
  vocabulary %>%
  select(word_id, word) %>%
  inner_join(unnest_tokens(test, word, text), by = "word") %>%
  select(test_id, word_id) %>%
  group_by(test_id, word_id) %>%
  summarise(word_count = n())



# write datasets ----------------------------------------------------------

write_csv(vocabulary, here("submission", "data", "vocabulary.csv"))
write_csv(vocabulary_stop_words, here("submission", "data", "vocabulary_stop_words.csv"))

write_csv(train_labels, here("submission", "data", "train_labels.csv"))
write_csv(train_features, here("submission", "data", "train_features.csv"))

write_csv(test_labels, here("submission", "data", "test_labels.csv"))
write_csv(test_features, here("submission", "data", "test_features.csv"))


