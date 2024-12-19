%commonVoiceHelper Code
disp('Testing set counts:');
disp(countEachLabel(adsTest));
% Call function to display all speakers and their files
displayAllSpeakers(adsTrain);
end
function displayAllSpeakers(adsTrain)
% Display all speakers and their corresponding files
uniqueSpeakers = unique(adsTrain.Labels); % Get unique speaker labels
% Loop through each unique speaker
for i = 1:length(uniqueSpeakers)
speakerLabel = uniqueSpeakers(i); % Get the current speaker label
speakerIndices = find(adsTrain.Labels == speakerLabel); % Find files for this speaker
% Display speaker label
fprintf('Speaker %s:\n', string(speakerLabel));
% Loop through and display files for this speaker
for j = 1:length(speakerIndices)
fprintf(' %s\n', adsTrain.Files{speakerIndices(j)});
end
fprintf('\n'); % New line for better readability
endfunction [adsTrain, adsTest] = commonVoiceHelper()
% Specify the path where you extracted the dataset
dataPath = '/Users/maxinetolentino/Documents/MATLAB/Examples/R2024b/audio_wavelet/PROJ'; % Update this path
% Read the validated table
dataTable = readtable(fullfile(dataPath, 'validated.tsv'), 'FileType', 'text', 'Delimiter', 'tab');
% Convert client_id and path columns to strings for easier handling
dataTable.client_id = string(dataTable.client_id);
dataTable.path = string(dataTable.path);
% Get unique speaker IDs and count their occurrences
ids = unique(dataTable.client_id);
counts = zeros(length(ids), 1);
for i = 1:length(ids)
counts(i) = sum(strcmp(dataTable.client_id, ids(i)));
end
% Sort speakers by the number of audio files they have
[s, idxs] = sort(counts);
% Attempt to filter speakers within the 14-22 range
selectedIdxs = idxs(s >= 14 & s <= 22);
% If fewer than 10 speakers are found, expand the range to get the closest count
if length(selectedIdxs) < 10
% Find the top 10 speakers with the most files if 14-22 range is insufficient
selectedIdxs = idxs(end-9:end);
end
% Select filtered speaker IDs and rows in dataTable
ids = ids(selectedIdxs);
rows = ismember(dataTable.client_id, ids);
% Generate file paths for the selected audio files without adding an extra extension
files = fullfile(dataPath, 'clips', dataTable.path(rows));
% Retrieve speaker IDs for selected files and create the audio datastore
speakers = string(dataTable.client_id(rows));
ads = audioDatastore(files);
% Assign numerical labels (1 to 10) for the speakers
ads.Labels = categorical(speakers, unique(speakers), string(1:length(unique(speakers))));
% Split the datastore into training (80%) and testing (20%)
[adsTrain, adsTest] = splitEachLabel(ads, 0.8, 'randomize');
% Display file paths and corresponding speaker labels in adsTest
disp('Test audio file paths and corresponding speakers:');
% for i = 1:numel(adsTest.Files)
% fprintf('File: %s, Speaker: %s\n', adsTest.Files{i}, string(adsTest.Labels(i)));
% end
% Display counts of each label in training and testing sets
disp('Training set counts:');
disp(countEachLabel(adsTrain));

end
