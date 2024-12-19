
% Main Code to Train and Test Speaker Recognition Model
% Step 1: Extract Features using commonVoiceHelper
[adsTrain, adsTest] = commonVoiceHelper();
% Read a sample file from the training datastore
[sampleTrain, dsInfo] = read(adsTrain);
% Define feature extractor parameters
fs = dsInfo.SampleRate;
windowLength = round(0.03 * fs);
overlapLength = round(0.025 * fs);
% Create audio feature extractor
afe = audioFeatureExtractor(...
SampleRate=fs, ...
Window=hamming(windowLength, "periodic"), ...
OverlapLength=overlapLength, ...
zerocrossrate=true, ...
shortTimeEnergy=true, ...
pitch=true, ...
mfcc=true);
% Extract and normalize features for training
[features, labels, M, S, featureMap, energyThreshold, zcrThreshold] = extractNormalizedFeatures(adsTrain, afe);
% Step 2: Train KNN Classifier
trainedClassifier = fitcknn(features, labels, ...
Distance="euclidean", ...
NumNeighbors=5, ...
DistanceWeight="squaredinverse", ...
Standardize=false, ...
ClassNames=unique(labels));
% Step 3: Cross-validation and accuracy
k = 5; % Number of folds for cross-validation
c = cvpartition(labels, KFold=k);
partitionedModel = crossval(trainedClassifier, CVPartition=c);
% Compute validation accuracy
% validationAccuracy = 1 - kfoldLoss(partitionedModel, LossFun="ClassifError");
% fprintf('\nValidation accuracy = %.2f%%\n', validationAccuracy * 100);
%
% % Step 4: Commenting out visualization of confusion chart for validation set
% validationPredictions = kfoldPredict(partitionedModel);
% figure(Units="normalized", Position=[0.4 0.4 0.4 0.4]);
% confusionchart(labels, validationPredictions, title="Validation Accuracy", ...
% ColumnSummary="column-normalized", RowSummary="row-normalized");
% Test the trained classifier on the test set
testClassifierOnDatastore(adsTest, afe, trainedClassifier, M, S, featureMap, energyThreshold, zcrThreshold);
% Run the interactive speaker recognition function
recognizeSpeaker(afe, trainedClassifier, M, S, featureMap, energyThreshold, zcrThreshold);
%% Functions
function [features, labels, M, S, featureMap, energyThreshold, zcrThreshold] = extractNormalizedFeatures(ads, afe)
% Extract features with thresholds
energyThreshold = 0.005;
zcrThreshold = 0.2;
allFeatures = extract(afe, ads);
allLabels = ads.Labels;
featureMap = info(afe);
features = [];
labels = [];
for ii = 1:numel(allFeatures)
thisFeature = allFeatures{ii};
isSpeech = thisFeature(:, featureMap.shortTimeEnergy) > energyThreshold;
isVoiced = thisFeature(:, featureMap.zerocrossrate) < zcrThreshold;
voicedSpeech = isSpeech & isVoiced;
thisFeature(~voicedSpeech, :) = [];
thisFeature(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];
label = repelem(allLabels(ii), size(thisFeature, 1));
features = [features; thisFeature];
labels = [labels, label];
end
% Normalize features
M = mean(features, 1);
S = std(features, [], 1);
features = (features - M) ./ S;
end
function testClassifierOnDatastore(ads, afe, classifier, M, S, featureMap, energyThreshold, zcrThreshold)
% Test the classifier on the test set and display confusion charts
features = [];
labels = [];
numVectorsPerFile = [];
allFeatures = extract(afe, ads);
allLabels = ads.Labels;
for ii = 1:numel(allFeatures)
thisFeature = allFeatures{ii};
isSpeech = thisFeature(:, featureMap.shortTimeEnergy) > energyThreshold;
isVoiced = thisFeature(:, featureMap.zerocrossrate) < zcrThreshold;
voicedSpeech = isSpeech & isVoiced;
thisFeature(~voicedSpeech, :) = [];
numVec = size(thisFeature, 1);
thisFeature(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];
label = repelem(allLabels(ii), numVec);
numVectorsPerFile = [numVectorsPerFile, numVec];
features = [features; thisFeature];
labels = [labels, label];
end
features = (features - M) ./ S;
prediction = predict(classifier, features);
prediction = categorical(string(prediction));
% % Commenting out visualization of confusion chart for test accuracy per frame
% figure(Units="normalized", Position=[0.4 0.4 0.4 0.4]);
% confusionchart(labels(:), prediction, title="Test Accuracy (Per Frame)", ...
% ColumnSummary="column-normalized", RowSummary="row-normalized");
% Mode of predictions for each file
r2 = prediction(1:numel(ads.Files));
idx = 1;
for ii = 1:numel(ads.Files)
r2(ii) = mode(prediction(idx:idx + numVectorsPerFile(ii) - 1));
idx = idx + numVectorsPerFile(ii);
end
% % Commenting out visualization of confusion chart for test accuracy per file
% figure(Units="normalized", Position=[0.4 0.4 0.4 0.4]);
% confusionchart(ads.Labels, r2, title="Test Accuracy (Per File)", ...
% ColumnSummary="column-normalized", RowSummary="row-normalized");
end
function recognizeSpeaker(afe, trainedClassifier, M, S, featureMap, energyThreshold, zcrThreshold)
% Interactive speaker recognition function
[fileName, filePath] = uigetfile({'*.wav'}, 'Select an Audio File');
if isequal(fileName, 0)
disp('No file selected');
return;
end
audioFile = fullfile(filePath, fileName);
[features, numVectorsPerFile] = extractFeaturesFromFile(audioFile, afe, M, S, featureMap, energyThreshold, zcrThreshold);
% Predict the speaker for each frame
prediction = predict(trainedClassifier, features);
prediction = categorical(string(prediction));
% Get the most common prediction as the file's speaker label
finalPrediction = mode(prediction);
fprintf('Predicted Speaker: %s\n', string(finalPrediction));
end
function [features, numVectorsPerFile] = extractFeaturesFromFile(audioFile, afe, M, S, featureMap, energyThreshold, zcrThreshold)
% Extract features from a single audio file
[audioData, fs] = audioread(audioFile);
if fs ~= afe.SampleRate
audioData = resample(audioData, afe.SampleRate, fs);
end
allFeatures = extract(afe, audioData);
isSpeech = allFeatures(:, featureMap.shortTimeEnergy) > energyThreshold;
isVoiced = allFeatures(:, featureMap.zerocrossrate) < zcrThreshold;
voicedSpeech = isSpeech & isVoiced;
features = allFeatures(voicedSpeech, :);
features(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];
features = (features - M) ./ S;
numVectorsPerFile = size(features, 1);
end
