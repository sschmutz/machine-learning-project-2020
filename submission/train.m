%% reading train features (headline_id, word_id, word_count)

num_train_headlines = 65482;
num_vocabulary_words = 44108;

train_features = dlmread('data/train_features.csv', ',', 1, 0);

% select maximum num_train_headlines with a maximum vocabulary size
% of num_vocabulary_words

selected_headlines = 1:num_train_headlines;

train_indices = ismember(train_features(:,1), selected_headlines) & ...
                train_features(:,2) <= num_vocabulary_words;

train_features = train_features(train_indices,:);


%% reading train lables

train_labels = readtable('data/train_labels.csv');

train_labels_20min = train_labels{:,"source"} == "20min";
train_labels_20min = train_labels_20min(1:num_train_headlines);

indices_20min = find(train_labels_20min == 1);
indices_nzz = find(train_labels_20min == 0);


%% create document-term-matrix

train_matrix_sparse = sparse(train_features(:,1), ... 
                             train_features(:,2), ... 
                             train_features(:,3), ...
                             num_train_headlines, num_vocabulary_words);
                         
train_matrix = full(train_matrix_sparse);


%% calculate prior probabilities

prior_prob_20min = length(indices_20min)/num_train_headlines;
prior_prob_nzz = 1-prior_prob_20min;


%% calculate class conditional probabilities

% get number of words for each headline
headlines_words = sum(train_matrix, 2);

% sum up words per class
wordcount_20min = sum(headlines_words(indices_20min));
wordcount_nzz = sum(headlines_words(indices_nzz));

% calculate class conditional probabilities
% we add 1 to each wordcount to avoid probabilities of 0
class_prob_20min = (sum(train_matrix(indices_20min, :)) + 1)./(wordcount_20min + num_train_headlines);
class_prob_nzz = (sum(train_matrix(indices_nzz, :)) + 1)./(wordcount_nzz + num_train_headlines);
