function [accuracy_train, accuracy_test] = cross_validation (DTM, labels_20min)
% ----------------------------------------------------------------------- %
% This function returns the mean train and test accuracies determined
% by 10-fold cross validation
%
% Inputs:
%   DTM:            Document-Term-Matrix containing word counts for all
%                   headlines
%   labels_20min:   Logical vector with rows labeled as 20min=true  
%
% Outputs:
%   accuracy_train: Mean accuracy of training folds
%   accuracy_test:  Mean accuracy of test (validation) folds   
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
%       document_term_matrix ('data/train_features.csv', 'data/train_labels.csv', 65482, 44108, false)
%
%   [accuracy_train, accuracy_test] = ...
%       cross_validation(DTM_train, train_labels_20min);
%
%% determine dimensions of DTM and initialise matrices
num_headlines_cv = size(DTM, 1);
row_numbers_cv = (1:num_headlines_cv)';

num_vocabulary_cv = size(DTM, 2);

train_accuracy_cv = zeros(10, 1);
test_accuracy_cv = zeros(10, 1);

%% run 10-fold cross validation
for fold = 1:10
    
    from = fold*(num_headlines_cv/10) - (num_headlines_cv/10 - 1);
    to = fold*(num_headlines_cv/10);
    
    test_indices_cv = row_numbers_cv(:,1)>=from & row_numbers_cv(:,1)<=to;
    train_indices_cv =  ~test_indices_cv;
    
    % everything with index between from and to is the
    % test set for the current fold
    DTM_test_cv = DTM(test_indices_cv, :);
    test_labels_20min_cv = labels_20min(test_indices_cv, :);
    
    % everything with index not between from and to is the
    % training set for the current fold
    DTM_train_cv = DTM(train_indices_cv, :);
    train_labels_20min_cv = labels_20min(train_indices_cv, :);
    
    % calculate prior probabilities
    indices_20min_train_cv = find(train_labels_20min_cv == 1);
    indices_nzz_train_cv = find(train_labels_20min_cv == 0);

    prior_prob_20min_cv = length(indices_20min_train_cv)/num_headlines_cv;
    prior_prob_nzz_cv = 1-prior_prob_20min_cv;
    
    % calculate class conditional probabilities
    % get number of words for each headline
    headlines_words_cv = sum(DTM_train_cv, 2);

    % sum up words per class
    wordcount_20min_cv = sum(headlines_words_cv(indices_20min_train_cv));
    wordcount_nzz_cv = sum(headlines_words_cv(indices_nzz_train_cv));

    % calculate class conditional probabilities
    % we add 1 to each wordcount to avoid probabilities of 0
    class_prob_20min_cv = (sum(DTM_train_cv(indices_20min_train_cv, :)) + 1)./(wordcount_20min_cv + num_vocabulary_cv);
    class_prob_nzz_cv = (sum(DTM_train_cv(indices_nzz_train_cv, :)) + 1)./(wordcount_nzz_cv + num_vocabulary_cv);
    
    
    
    % Evaluate train accuracy
    log_20min_train_cv = DTM_train_cv*(log(class_prob_20min_cv))' + log(prior_prob_20min_cv);
    log_nzz_train_cv = DTM_train_cv*(log(class_prob_nzz_cv))'+ log(prior_prob_nzz_cv);

    train_predictions_20min_cv = log_20min_train_cv > log_nzz_train_cv;

    train_accuracy_cv(fold) = mean(train_labels_20min_cv == train_predictions_20min_cv);

    % Evaluate test accuracy
    log_20min_test_cv = DTM_test_cv*(log(class_prob_20min_cv))' + log(prior_prob_20min_cv);
    log_nzz_test_cv = DTM_test_cv*(log(class_prob_nzz_cv))'+ log(prior_prob_nzz_cv);

    test_predictions_20min_cv = log_20min_test_cv > log_nzz_test_cv;

    test_accuracy_cv(fold) = mean(test_labels_20min_cv == test_predictions_20min_cv);
    
end

%% calculate mean of accuracy of each of the 10-folds
accuracy_train =  mean(train_accuracy_cv);
accuracy_test = mean(test_accuracy_cv);

end