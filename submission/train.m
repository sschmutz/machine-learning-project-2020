%% reading train features (headline_id, word_id, word_count)

train_features = dlmread('data/train_features.csv', ',', 1, 0);


%% reading train lables

train_labels = readtable('data/train_labels.csv');

train_labels_20min = train_labels{:,"source"} == "20min";

indices_20min = find(train_labels_20min == 1);
indices_nzz = find(train_labels_20min == 0);


%% create document-term-matrix

num_train_headlines = 65482;
num_vocabulary_words = 44108;

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
class_prob_20min = (sum(train_matrix(indices_20min, :)) + 1)./(wordcount_20min + num_train_headlines);
class_prob_nzz = (sum(train_matrix(indices_nzz, :)) + 1)./(wordcount_nzz + num_train_headlines);
