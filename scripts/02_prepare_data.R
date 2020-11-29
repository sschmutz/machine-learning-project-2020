library(tidyverse)
library(tidytext)
library(here)


# read datasets -----------------------------------------------------------
# Only keep unique headlines

headlines_20min <-
  read_csv(here("data", "headlines_20min.csv")) %>%
  select("text") %>%
  mutate(source = "20min") %>%
  unique()

headlines_nzz <-
  read_csv(here("data", "headlines_nzz.csv")) %>%
  select("text") %>%
  mutate(source = "nzz") %>%
  unique()

# source: https://github.com/solariz/german_stopwords/blob/master/german_stopwords_plain.txt
stop_words_german <-
  read_csv(here("data", "stop_words_german.txt"), col_names = c("word"))

# Combine the two datasets and only keep unique headlines
headlines <-
  bind_rows(headlines_20min, headlines_nzz) %>%
  mutate(headline_id = 1:n())


# split training and test data --------------------------------------------

train_fraction <- 0.75

set.seed(20201122)
train <-
  headlines %>%
  sample_frac(train_fraction)

test  <- 
  headlines %>%
  anti_join(train, by = "headline_id")



# write datasets ----------------------------------------------------------

write_csv(test, here("submission", "data", "test.csv"))
write_csv(train, here("submission", "data", "train.csv"))
write_csv(stop_words_german, here("submission", "data", "stop_words_german.csv"))
