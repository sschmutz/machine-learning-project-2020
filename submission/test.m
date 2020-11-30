%% reading test features (headline_id, word_id, word_count)

num_test_headlines = 21827;
num_vocabulary_words = 44108;

test_features = dlmread('data/test_features.csv', ',', 1, 0);
stop_words = readtable('data/vocabulary_stop_words.csv');


% remove stop_words
test_features = test_features(~ismember(test_features(:,2), stop_words{:,"word_id"}),:);

% select maximum num_test_headlines with a maximum vocabulary size
% of num_vocabulary_words

selected_headlines = 1:num_test_headlines;

test_indices = ismember(test_features(:,1), selected_headlines) & ...
                test_features(:,2) <= num_vocabulary_words;

test_features = test_features(test_indices,:);

%% reading test lables

test_labels = readtable('data/test_labels.csv');

test_labels_20min = test_labels{:,"source"} == "20min";
test_labels_20min = test_labels_20min(1:num_test_headlines);

indices_20min = find(test_labels_20min == 1);
indices_nzz = find(test_labels_20min == 0);


%% create document-term-matrix

test_matrix_sparse = sparse(test_features(:,1), ... 
                            test_features(:,2), ... 
                            test_features(:,3), ...
                            num_test_headlines, num_vocabulary_words);
                         
test_matrix = full(test_matrix_sparse);


%% calculate predictions

log_20min = test_matrix*(log(class_prob_20min))' + log(prior_prob_20min);
log_nzz = test_matrix*(log(class_prob_nzz))'+ log(prior_prob_nzz);

test_predictions_20min = log_20min > log_nzz;

%% calculate test accuracy

mean(test_labels_20min == test_predictions_20min)
