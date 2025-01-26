function logInSystem1()
    % Create a figure for the System
    fig = uifigure('Name', 'Speaker Recognition System', 'Position', [500, 300, 500, 500]);

    % Feature Extraction Parameters
    fs = 48000; % Sampling rate (must match the Sign-Up code)
    windowLength = round(0.03 * fs);
    overlapLength = round(0.025 * fs);
    afe = audioFeatureExtractor(...
        SampleRate=fs, ...
        Window=hamming(windowLength, "periodic"), ...
        OverlapLength=overlapLength, ...
        zerocrossrate=true, ...
        shortTimeEnergy=true, ...
        pitch=true, ...
        mfcc=true);

    % Store afe in application data for access in other callbacks
    setappdata(fig, 'afe', afe);

    % List of sentences to read
    sentences = {
        'The library closes at eight o''clock tonight.';
        'She sells sea shells by the seashore.';
        'The melody of the piano filled the entire room.';
        'Clouds gather before the rain begins to pour.';
        'This package contains fragile glass items.';
        'The train to the city departs every hour.';
        'Technology has advanced rapidly in recent years.';
        'Warm sunlight streamed through the kitchen window.';
        'Always double-check the details before signing.';
        'The mountains stood tall against the clear blue sky.';
        'Can you believe how quickly the year has passed?';
        'A cup of hot coffee is perfect on a cold day.';
        'The garden is blooming with vibrant flowers.';
        'Every traveler tells a unique story about their journey.';
        'The clock on the wall ticks loudly in the silence.';
        'Turn left at the next traffic signal to reach the park.';
        'Languages are bridges that connect people worldwide.';
        'The bakery on Main Street sells the best pastries.';
        'Carefully place the book back on the top shelf.';
        'Bright colors make the room feel more cheerful.';
        'Open the window to let in some fresh air.';
        'The artist sketched a beautiful portrait in minutes.';
        'This road trip has been a wonderful adventure.';
        'Kindness can make a significant difference in someone''s life.';
        'The echo of her laughter filled the empty hall.';
        'Remember to save your work frequently on the computer.';
        'The stars twinkled brightly in the clear night sky.';
        'His voice was calm and soothing as he explained the process.';
        'Take a deep breath and focus on the present moment.';
        'The sound of the waves crashing was both powerful and serene.'
    };

     % Randomly select a sentence
    randomIndex = randi(length(sentences));
    randomSentence = sentences{randomIndex}; % Choose the sentence


    % Username input field
    uilabel(fig, 'Position', [50, 420, 100, 30], 'Text', 'Username:', 'FontSize', 18);
    usernameField = uieditfield(fig, 'text', 'Position', [150, 420, 300, 30], 'FontSize', 18);
    
    % Record voice buttons
    uilabel(fig, 'Position', [50, 360, 100, 30], ...
            'Text', 'Voice Input:','FontSize', 18);
    startButton = uibutton(fig, 'Text', 'Start', ...
                           'Position', [160, 360, 100, 40], ...
                           'FontSize', 16, ... % Set the font size to 14 points
                           'ButtonPushedFcn', @(btn, event) startRecording());
    stopButton = uibutton(fig, 'Text', 'Stop', ...
                          'Position', [280, 360, 100, 40], ...
                          'Enable', 'off', ...
                          'FontSize', 16, ... % Set the font size to 14 points
                          'ButtonPushedFcn', @(btn, event) stopRecording());
    
    % Log In button
    analyzeButton = uibutton(fig, 'Text', 'Log In', ...
                             'Position', [220, 250, 100, 40], ...
                             'Enable', 'off', ...
                             'FontSize', 16, ... % Set the font size to 14 points
                             'ButtonPushedFcn', @(btn, event) analyzeSpeaker());
    
    % Result display
    resultText = uilabel(fig, 'Position', [50, 320, 300, 40], ...
                         'Text', '', ...
                         'FontSize', 16, ...
                         'HorizontalAlignment', 'center', ...
                         'FontColor', 'blue');
    
    % Sentence to read display
    uilabel(fig, 'Position', [50, 60, 400, 40], ...
            'Text', ['Read this sentence: ', randomSentence], ...
            'FontSize', 18, ...
            'HorizontalAlignment', 'center', ...
            'FontColor', 'red');

    %  Variable to store recording state and audio data
    fs = 48000; % Sampling frequency
              
        % Start recording callback
    function startRecording(~, ~)
        recorder = audiorecorder(fs, 16, 1); % Initialize recorder
        setappdata(fig, 'recorder', recorder); % Store recorder in app data
        record(recorder); % Start recording
        set(startButton, 'Enable', 'off');
        set(stopButton, 'Enable', 'on');
        resultText.Text = 'Recording... Speak now.';
    end
    
    function stopRecording(~, ~)
    recorder = getappdata(fig, 'recorder'); % Retrieve recorder from app data
    if isempty(recorder)
        msgbox('Recorder is not initialized.', 'Error', 'error');
        return;
    end
    stop(recorder); % Stop recording
    recordedAudio = getaudiodata(recorder); % Retrieve recorded audio
    setappdata(fig, 'recordedAudio', recordedAudio); % Store recorded audio in app data
    set(stopButton, 'Enable', 'off');
    set(startButton, 'Enable', 'on');
    set(analyzeButton, 'Enable', 'on');
    resultText.Text = 'Recording stopped. Ready to analyze.';
end
    function analyzeSpeaker(~, ~)

    % Retrieve the audio feature extractor
    afe = getappdata(fig, 'afe');
    if isempty(afe)
        uialert(fig, 'Audio feature extractor is not initialized.', 'Error');
        return;
    end

    % Retrieve username from input
    username = usernameField.Value; % Use Value property to get the text
    if isempty(username)
        msgbox('Please enter your username.', 'Error', 'error');
        return;
    end

    % Retrieve recorded audio
    recordedAudio = getappdata(fig, 'recordedAudio'); % Retrieve recorded audio
    if isempty(recordedAudio)
        msgbox('No recorded voice data available. Please record your voice first.', 'Error', 'error');
        return;
    end

    % Load trained model and normalization parameters
    if exist('trainedKNNClassifier.mat', 'file') == 2
        load('trainedKNNClassifier.mat', 'trainedClassifier', 'M', 'S', 'featureMap', 'energyThreshold', 'zcrThreshold');
    else
        uialert(fig, 'Trained model not found. Please train the model first.', 'Error');
        return;
    end

    % Recognize the user from the recorded audio
    [features, ~] = extractFeaturesFromRecordedAudio(recordedAudio, fs, afe, M, S, featureMap, energyThreshold, zcrThreshold);
    prediction = predict(trainedClassifier, features);
    prediction = categorical(string(prediction)); % Convert to categorical

    % Load the existing training data
    load('existingTrainingData.mat', 'adsTrain');
    existingLabels = adsTrain.Labels;

    % Check if the username exists in the training data
    if ~ismember(categorical({username}), existingLabels)
        uialert(fig, ['Username "', username, '" not found in the system.'], 'Error');
        return;
    end

    % Compare the predicted label with the entered username
    predictedUser = mode(prediction); % Use the most common prediction
    if predictedUser == categorical({username})
        createCustomDialog('Log-In Successful.', 'Success', 'blue', fig);
    else
        createCustomDialog('Access Denied: Voice does not match.', 'Error', 'red', fig);
    end

    
    disp(['Predicted User: ', char(predictedUser)]);
    % disp(['Mean Distance: ', num2str(meanDistance)]);

    % Custom function to create a larger message dialog
    function createCustomDialog(message, title, color, parentFig)
        dialogFig = uifigure('Name', title, 'Position', [500, 500, 400, 200], 'CloseRequestFcn', @(src, event) delete(src));
        uilabel(dialogFig, ...
            'Text', message, ...
            'FontSize', 15, ... % Larger font size
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'center', ...
            'Position', [50, 50, 300, 100]);

        % obs = trainedClassifier.NumObservations;
        % 
        % 
        % % Compute validation accuracy and display confusion chart (temporary for paper results)
        % k = 5; % Number of folds for cross-validation
        % c = cvpartition(obs, 'KFold', k); % Use labels from adsTrain
        % partitionedModel = crossval(trainedClassifier, 'CVPartition', c);
        % 
        % % Compute and display validation accuracy
        % validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');
        % fprintf('\nValidation accuracy = %.2f%%\n', validationAccuracy * 100);
        % validationPredictions = kfoldPredict(partitionedModel);
        % 
        % 
        % % Assume `username` contains the specific username for the uploaded file
        % % Assume `labels` contains the full set of labels for the dataset
        % % Assume `validationPredictions` contains predictions for the uploaded file
        % 
        % % Convert username to categorical to match labels format
        % usernameCategory = categorical({username}); % Convert username to categorical
        % 
        % % Filter actual labels for the specific username
        % relevantIndices = (existingLabels == usernameCategory); % Logical indices for relevant labels
        % filteredLabels = existingLabels(relevantIndices); % Filtered actual labels
        % 
        % % Filter predictions to match the relevant class
        % filteredPredictions = validationPredictions(relevantIndices); % Filtered predictions
        % 
        % % Check if there are predictions for the relevant class
        % if isempty(filteredLabels) || isempty(filteredPredictions)
        %     warning('No predictions or labels available for the specified username.');
        % else
        %     % Plot the confusion chart for the relevant class
        %     figure(Units="normalized", Position=[0.4 0.4 0.4 0.4]);
        %     confusionchart(filteredLabels, filteredPredictions, 'Title', "Confusion Chart for Specific User", ...
        %         'ColumnSummary', "column-normalized", 'RowSummary', "row-normalized");
end       
    end


    function [features, numVectorsPerFile] = extractFeaturesFromRecordedAudio(recordedAudio, fs, afe, M, S, featureMap, energyThreshold, zcrThreshold)
        % Extract features from recorded audio
        if fs ~= afe.SampleRate
            recordedAudio = resample(recordedAudio, afe.SampleRate, fs);
        end
        allFeatures = extract(afe, recordedAudio);
        isSpeech = allFeatures(:, featureMap.shortTimeEnergy) > energyThreshold;
        isVoiced = allFeatures(:, featureMap.zerocrossrate) < zcrThreshold;
        voicedSpeech = isSpeech & isVoiced;
        features = allFeatures(voicedSpeech, :);
        features(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];
        features = (features - M) ./ S;
        numVectorsPerFile = size(features, 1);
    end

    % function recognizeUser(afe, trainedClassifier, M, S, featureMap, energyThreshold, zcrThreshold)
    % 
    %     [features, numVectorsPerFile] = extractFeaturesFromRecordedAudio(audioFile, afe, M, S, featureMap, energyThreshold, zcrThreshold);
    % 
    %     % Predict the speaker for each frame
    %     prediction = predict(trainedClassifier, features);
    %     prediction = categorical(string(prediction));
    % 
    %     % % Get the most common prediction as the file's speaker label
    %     % finalPrediction = mode(prediction);
    %     % fprintf('Predicted Speaker: %s\n', string(finalPrediction));
    % end


    
    % function testClassifierOnRecordedAudio(recordedAudio, afe, classifier, M, S, featureMap, energyThreshold, zcrThreshold)
    %     % Test the classifier
    %     features = [];
    %     labels = [];
    %     numVectorsPerFile = [];
    %     allFeatures = extract(afe, recordedAudio);
    %     allLabels = adsTrain.Labels;
    %     for ii = 1:numel(allFeatures)
    %         thisFeature = allFeatures{ii};
    %         isSpeech = thisFeature(:, featureMap.shortTimeEnergy) > energyThreshold;
    %         isVoiced = thisFeature(:, featureMap.zerocrossrate) < zcrThreshold;
    %         voicedSpeech = isSpeech & isVoiced;
    %         thisFeature(~voicedSpeech, :) = [];
    %         numVec = size(thisFeature, 1);
    %         thisFeature(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];
    %         label = repelem(allLabels(ii), numVec);
    %         numVectorsPerFile = [numVectorsPerFile, numVec];
    %         features = [features; thisFeature];
    %         labels = [labels, label];
    %     end
    %     features = (features - M) ./ S;
    %     prediction = predict(classifier, features);
    %     prediction = categorical(string(prediction));
    % 
    % end

      % function distances = calculateDistances(trainedClassifier, features)
      %   % Extract the training data from the classifier
      %   trainingData = features; % Assuming the KNN classifier stores training data in 'X'
      % 
      %   % Calculate Euclidean distances between features and training data
      %   distances = zeros(size(features, 1), 1);
      %   for i = 1:size(features, 1)
      %       distances(i) = min(sqrt(sum((trainingData - features(i, :)).^2, 2)));
      %   end

end
