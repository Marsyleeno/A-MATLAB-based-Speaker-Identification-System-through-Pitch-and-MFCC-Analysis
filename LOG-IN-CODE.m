%LOG-IN CODE
function speakerIdentificationGUI
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
    
    % Create a GUI figure
    fig = figure('Name', 'Speaker Identification System', ...
                 'NumberTitle', 'off', 'Position', [300, 300, 400, 400]);

    % Email/Username input
    uicontrol('Style', 'text', 'Position', [50, 300, 100, 20], ...
              'String', 'Email/Username:', 'HorizontalAlignment', 'right');
    usernameField = uicontrol('Style', 'edit', 'Position', [160, 300, 180, 25]);

    % Record voice buttons
    uicontrol('Style', 'text', 'Position', [50, 250, 100, 20], ...
              'String', 'Voice Input:', 'HorizontalAlignment', 'right');
    startButton = uicontrol('Style', 'pushbutton', 'Position', [160, 250, 80, 30], ...
                            'String', 'Start', 'Callback', @startRecording);
    stopButton = uicontrol('Style', 'pushbutton', 'Position', [260, 250, 80, 30], ...
                           'String', 'Stop', 'Enable', 'off', 'Callback', @stopRecording);
    
    % Log In button
    analyzeButton = uicontrol('Style', 'pushbutton', 'Position', [150, 180, 100, 40], ...
                              'String', 'Log In', 'Enable', 'off', 'Callback', @analyzeSpeaker);

    % Result display
    resultText = uicontrol('Style', 'text', 'Position', [50, 120, 300, 40], ...
                           'String', '', 'FontSize', 10, ...
                           'HorizontalAlignment', 'center', 'ForegroundColor', 'blue');
    
    % Sentence to read display
    uicontrol('Style', 'text', 'Position', [50, 60, 300, 40], ...
              'String', ['Read this sentence: ', randomSentence], ...
              'FontSize', 10, 'HorizontalAlignment', 'center', 'ForegroundColor', 'green');
    
    % Global variables to store recording state and audio data
    global recorder recordedAudio fs;
    fs = 44100; % Sampling frequency
    
    % Start recording callback
    function startRecording(~, ~)
        recorder = audiorecorder(fs, 16, 1); % 16-bit, 1 channel
        record(recorder);
        set(startButton, 'Enable', 'off');
        set(stopButton, 'Enable', 'on');
        set(resultText, 'String', 'Recording... Speak now.');
    end

    % Stop recording callback
    function stopRecording(~, ~)
        stop(recorder);
        recordedAudio = getaudiodata(recorder);
        set(stopButton, 'Enable', 'off');
        set(startButton, 'Enable', 'on');
        set(analyzeButton, 'Enable', 'on');
        set(resultText, 'String', 'Recording stopped. Ready to analyze.');
    end

    % Log In button callback
    function analyzeSpeaker(~, ~)
        username = get(usernameField, 'String');
        if isempty(username)
            msgbox('Please enter an email or username.', 'Error', 'error');
            return;
        end
        if isempty(recordedAudio)
            msgbox('No recorded voice data available. Please record your voice first.', 'Error', 'error');
            return;
        end
        
        % Extract MFCC and pitch features
        mfccFeatures = mfcc(recordedAudio, fs);
        pitchValues = pitch(recordedAudio, fs);
        
        % Combine features (mean of MFCCs and pitch for demo)
        features = [mean(mfccFeatures, 1), mean(pitchValues)];
        
        % Dummy KNN classifier
        predictedSpeaker = knnClassifier(features);
        
        % Display the result
        set(resultText, 'String', sprintf('Identified as: %s', predictedSpeaker));
    end

    % Dummy KNN classifier function
    function speaker = knnClassifier(features)
        % Replace this with actual KNN model logic
        speaker = 'Speaker1'; % Placeholder
    end
end

