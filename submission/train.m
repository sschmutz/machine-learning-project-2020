%% reading train data set (text, source, headline_id)
train_data = readtable('data/train.csv');

%% calculate class probabilities
labels = train_data{:,'source'};

n_nzz = sum(labels == "nzz");
n_20min = sum(labels == "20min");

prior_nzz = n_nzz/(n_nzz+n_20min);
prior_20min = n_20min/(n_nzz+n_20min);

%% create word vocabulary
train_data_size = size(train_data);
train_data_rows = train_data_size(1);

vocabulary = containers.Map('KeyType', 'char', 'ValueType', 'uint32');

for row = 1:3 %train_data_rows
    words = split(train_data{row, 'text'});
    
    for word_index = 1:length(words)
        word = words{word_index};
        
        if isKey(vocabulary, word)
            vocabulary(word) = vocabulary(word)+1;
        else
            vocabulary(word) = 1;
            
        end
    end
end

word = keys(vocabulary)';
count = values(vocabulary)';
vocabulary_table = table(word, count, 'VariableNames', {'word' 'count'});
vocabulary_table = sortrows(vocabulary_table, 'count', 'descend');

vocabulary_id = (1:size(vocabulary_table))';

vocabulary_table = addvars(vocabulary_table, vocabulary_id);

%% create document-term-matrix

