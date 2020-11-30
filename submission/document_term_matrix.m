function [DTM, labels_20min] = document_term_matrix (features_path, labels_path, num_headlines, num_vocabulary, exclude_stop)
% ----------------------------------------------------------------------- %
% This function returns a Document-Term-Matrix (DTM) and indices of class
% labels which can be used to train a Multinomial Naive Bayes classifier.
%
% Inputs:
%   features_path:  Path to features list with following columns:
%                   (train/test_id, word_id, word_count)
%   labels_path:    Path to labels list with following columns:
%                   (train/test_id, source, object)
%   num_headlines:  Maximum number of headlines to include
%   num_vocabulary: Maximum number of different words to include
%   exclude_stop:   Logical if stop words should be excluded or not
%
% Outputs:
%   DTM:            Document-Term-Matrix containing word counts for all
%                   headlines
%   labels_20min:   Logical vector with rows labeled as 20min=true   
%
% ----------------------------------------------------------------------- %
% Authors:
%   Harry Chirayil
%   Christopher Keim
%   Stefan Schmutz
% Created: 
%   2020-11-30
%
% ----------------------------------------------------------------------- %
% Example of usage: 
%   [DTM_train, train_labels_20min] = ...
%    document_term_matrix ('data/train_features.csv', 'data/train_labels.csv', 65482, 44108, false)
%
%   [DTM_test, test_labels_20min] = ...
%    document_term_matrix ('data/test_features.csv', 'data/test_labels.csv', 21827, 44108, false)
%
%% reading train features (train/test_id, word_id, word_count)

features = dlmread(features_path, ',', 1, 0);
stop_words = readtable('data/vocabulary_stop_words.csv');


% remove stop_words if chosen
if exclude_stop == true
    features = features(~ismember(features(:,2), stop_words{:,"word_id"}),:);
end

% select maximum num_headlines with a maximum vocabulary size
% of num_vocabulary
selected_headlines = 1:num_headlines;

indices = ismember(features(:,1), selected_headlines) & ...
                   features(:,2) <= num_vocabulary;

features = features(indices,:);


%% reading train lables

labels = readtable(labels_path);

labels_20min = labels{:,"source"} == "20min";
labels_20min = labels_20min(1:num_headlines);


%% create document-term-matrix

DTM_sparse = sparse(features(:,1), ... 
                    features(:,2), ... 
                    features(:,3), ...
                    num_headlines, num_vocabulary);
                         
DTM = full(DTM_sparse);


end