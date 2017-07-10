%%% Pupil Metric Generator
% by Matt Rosenberg (MHRosenberg@caltech.edu)
%
% instructions:
% 0. convert avi video files to .mat format using convertAVItoMat.m
% 1. load video via line 21 (uncomment if necessary)
% 2. getPupilROI.m must be run at least once! (ie alreadyRanGetPupilROi = 0 for the first time running the code)
%        - click and drag around the region in which the pupil could be found
%        - click and drag around the region in which the pupil actually appears in sample image
%        -SANITY CHECK: 2 red rectangles should be displayed; additionally figure 10 should show the image you selected; if either is not the case, rerun.
% 3. (optional) to avoid typing commands over and over: use the preprocessing block of code (set PREPROCESS to 1 to use the preprocessing block and 0 to skip it)
%         - see lines 70 to 134 for key press shortcuts
% 4. based on what preprocessing steps seem to work, add the commands to the designated block in the main automation loop
% 5. see postprocessing12_13_16.m for result summaries and creation of annotated videos
% NOTE: code is computationally intensive and interim saving of results may be necessary to avoid matlab crashing.
% CAREFUL: check all parameters are appropriate (end of parameter section is marked in a comment)
%
% control + c to halt code operation


%%%% IMPORTANT: read and modify all parameters starting on line 57!!!!

%%% load and select ROI/pupil parameters
firstSubVidNum = 1; % MUST CORRESPOND TO TRAILING NUMBERS BETWEEN THE FILE NAME AND THE EXTENSION!
lastSubVidNum = 1;
cameraSetupChangesBetweenSubvideos = 0;
alreadyRanGetPupilROI = 0; %%% default should be 0
subvideoAlreadyLoaded = 0; %%% default should be 0
% subVidName_minusNumber = '~/MHR/a_Research/a_Code/MATLAB/a_Tsao/pupillometry/tsaoPupil.mat'; % MUST BE .mat format!!! video directory and file name (without number and extension)
subVidName_minusNumber = '/home/orthogonull/A_MHR/a_Research/a_Anderson/pupil dilation sample movies/2SF1-4_PD_data_day1/Rat1.mat'; % MUST BE .mat format!!! video directory and file name (without number and extension)
%%% END PARAMETERS

%imshow(data(:,:,1),'DisplayRange', [184 4092])


for subVid = firstSubVidNum:lastSubVidNum
    
    %%%%%%%%%%%%%%%%%%%% MUST BE RUN ONCE BEFORE PREPROCESSING OR AUTOMATION
    %%% load video in .mat format here
    
    if subvideoAlreadyLoaded ~= 1
%         disp('loading movie');
%         actualSubVidName = [subVidName_minusNumber num2str(subVid) '.mat'];
%         load(actualSubVidName)
        load(subVidName_minusNumber)
%         mov = data;
    end
    
    if alreadyRanGetPupilROI == 0 || cameraSetupChangesBetweenSubvideos == 1
        disp('select ROI and pupil by click and dragging a rectangle around each')
        getPupilROI_12_13_16;
        
        %%%% sanity check that ROI is reasonable; should show image that was selected by user; rerun getPupilROI if result is one pixel (intermittent rbbox bug)
        figure(10)
        imshow(frame(roi_topLeftY:roi_bottomLeftY,roi_topLeftX:roi_topRightX),'DisplayRange', [184 4092])
%         imagesc(frame(roi_topLeftY:roi_bottomLeftY,roi_topLeftX:roi_topRightX))
    end
    %%% of stuff that must be run at least once (ie everything below
    
    
    %%% START PARAMETERS (read CAREFULLY!)
    
    %%% circle finding algorithm parameters (imfindcircles.m) parameters
    SENSITIVITY = .97;%.95%!!!0.97; %0.95; %%%%%%%%%% higher values give more circles
    EDGE_THRESH = 0.00001;%.0001;%!!!0.005 0.001 %0.03; %0.01; %0.000001; %%%%%%%%%% lower values give more circles
    LOWER_RADIUS_BOUND = 5;%20; % in pixels (INCREASE HERE TO EXCLUDE IMPOSSIBLY SMALL CIRCLES)
    RADIUS_RANGE = [LOWER_RADIUS_BOUND, ceil(min(abs(roi_topLeftX-roi_topRightX), abs(roi_topLeftY-roi_bottomLeftY))/2)];
    POLARITY = 'bright'; % 'bright' for white circles; 'dark' for black circles
    METHOD = 'PhaseCode'; % PhaseCode or TwoStage (slower)
%     filter = ones(20,20) / 100; %%%%% used to brighten and smooth image PROBABLY NEEDS TO BE CHANGED FOR EACH ILLUMINATION LEVEL!
    filter = ones(10,10) / 100; 
    %%%%%%%%alternate way to define the RADIUS_RANGE
    %%% extraSearchPercentOfEstimate = 50;
    %%% RADIUS_RANGE = [max(LOWER_RADIUS_BOUND,ceil(manualRadiusEstimate*(extraSearchPercentOfEstimate/100))), ceil(manualRadiusEstimate*((extraSearchPercentOfEstimate+100)/100))]; %%%%%% USER SPECIFIED RADIUS ESTIMATE
    
    %%% plotting parameters
    PLOT_RESULTS = 1;
    WAIT_FOR_BUTTON_PRESS_AFTER_PLOT = 0; % 1 if you want to press a key before the next frame's results are shown
    PAUSE_DURATION_AFTER_PLOT = 0.0000001; % seconds
    MAX_NUM_DRAWN_CIRCLES = 10;
    
    %%% preprocessing parameters
    PREPROCESS_PILOTING = 0; %%%%%%%%%%%%%%%%% SET TO 1 IF YOU WANT TO EXPLORE PARAMETERS
    PREPROCESS_FRAME = 1; %%%%%%%%%%% frame to preprocess/debug
%     frame = mov(PREPROCESS_FRAME).cdata;
    frame = mov(:,:,PREPROCESS_FRAME);
%     frame = rgb2gray(frame);
    orig = frame;
    %     f = gcf;
    %%% parameters for edge extraction
    CANNY_THRESH = [.04, .1]; % this helped for Sotiris' videos but I wasn't able to find values that helped here; Thresh must be [low high], where 0 < low < high < 1.
    FILTER_METHOD = 'canny';
    PREPROCESS_DESCRIPTION = 'imfill then imadjust (on the whole image)'; % modify to describe ultimate preprocessing steps conducted; this line is saved into the master results.parameters info
    
    % automation parameters
    START_FRAME = 1; %%%%%%%%%%%% frame to start analysis at
    FRAME_JUMP = 1; % number of frames to advance by in automation
    LAST_FRAME = 0; % set to 0 if you want to process all frames
    saveDirectory = '~/MHR/a_Research/Siapas/pupillometry/results/12_24_16/'; % MAKE SURE TO HAVE TRAILING '/' !!!
    
    %%% output file parameters
    dateStr = datestr(datetime,'mm/dd/yy');
    dateStr = strrep(dateStr,'/','_');
    fileName = char([saveDirectory 'results_' dateStr '_subVid_' num2str(subVid) '.mat']);
    
    
    
    
    figure(1) % actual results are shown here
    
    disp(['Manual radius estimate in pixels: ' num2str(manualRadiusEstimate) char(10) 'If value is 1 or incorrect, rerun getPupilROI (uncomment line above)?'])
    while PREPROCESS_PILOTING == 1
        WAIT_FOR_BUTTON_PRESS_AFTER_PLOT = 1;
        frameNum = PREPROCESS_FRAME;
        figure(1)
        imshow(frame,'Border','tight')
        disp(['waiting for initial key press' char(10) 'q to exit preprocessing (preprocessing steps must be added to automation loop below to be effective)' ...
            char(10) 'see lines 69 - 135 for key commands' char(10)])
        j = waitforbuttonpress;
        if f.CurrentCharacter == 'f'
            %frame =imcomplement(imfill(imcomplement(frame),'holes')); % not quite as good
            frame = imfill(frame);
        elseif f.CurrentCharacter == 'i'
            frame = imcomplement(frame);
        elseif f.CurrentCharacter == 'h'
            k = waitforbuttonpress;
            if f.CurrentCharacter == 'h'
                frame(roi_topLeftY:roi_bottomLeftY,roi_topLeftX:roi_topRightX) = histeq(frame(roi_topLeftY:roi_bottomLeftY,roi_topLeftX:roi_topRightX), 4);
            elseif f.CurrentCharacter == 'j'
                frame = imadjust(frame); % seems to be better than the restricted version below
                %             frame(roi_topLeftY:roi_bottomLeftY,roi_topLeftX:roi_topRightX) = imadjust(frame(roi_topLeftY:roi_bottomLeftY,roi_topLeftX:roi_topRightX));
            end
        elseif f.CurrentCharacter == 'r' %%%%%%%%%%%%% expand radius window
            RADIUS_RANGE = [5 manualRadiusEstimate*3];
            disp(['radius now: ' num2str(RADIUS_RANGE)])
        elseif f.CurrentCharacter == 'p'
            if strcmp(POLARITY,'dark')
                POLARITY = 'bright';
            else
                POLARITY = 'dark';
            end
            disp(['polarity now: ' POLARITY])
        elseif f.CurrentCharacter == 's'
            frameToLoad = str2double(input('Enter desired frame and press enter', 's'));
            PREPROCESS_FRAME = frameToLoad;
            frame = mov(frameToLoad).cdata;
            frame = rgb2gray(frame);
            orig = frame;
        elseif f.CurrentCharacter == 'd' %%% distorts boundary but might be appropriate for canny edge filtering/smoothing
            SE = strel('disk',10,0);
            frame = imdilate(frame,SE);
        elseif f.CurrentCharacter == 'e'
            EDGE_THRESH = EDGE_THRESH + .01;
        elseif f.CurrentCharacter == 'c'
            frame = edge(frame, FILTER_METHOD); % none of the default filters worked well in my hands
            %         frame = edge(frame, FILTER_METHOD, CANNY_THRESH);
            %         [frame, thresh]= edge(frame, 'canny');
            CANNY_THRESH(1) = CANNY_THRESH(1) + 0.005
        elseif f.CurrentCharacter == 't'
            frame(frame < 85.5) = 0;
        elseif f.CurrentCharacter == 'o' %%%%%%%%%%% reset image to original
            frame = orig;
            disp('frame reset to original')
        elseif f.CurrentCharacter == 'z'  %%%%%%%%%%%%% pause loop
            disp('paused in debugger (if breakpoint is set there)');
        elseif f.CurrentCharacter == 'g'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% run circle find
            disp('press s for parameter sweep; press numeral 1 for default imfindcircles')
            k = waitforbuttonpress;
            if f.CurrentCharacter == 's' %% see values above for appropriate starting places; sweep all parameter values of sensitivity and edgeThresh in imfindcircles
                measurePupil_sweepAllValues_11_7_16;
            elseif f.CurrentCharacter == '1' %% numeral one ; run quick circle find test
                measurePupil_12_14_16;
            end
            disp('press any key clear plotted results and restart the preprocessing loop')
        elseif f.CurrentCharacter == 'q'
            PREPROCESS_PILOTING = 0;
            WAIT_FOR_BUTTON_PRESS_AFTER_PLOT = 0;
        else
            disp('Is nothing changing? Check that caps lock is disabled.')
        end
    end
    
    %%% preallocate data containers
    if ~exist('results_constrained', 'var')
        results_constrained = nan(length(mov),4); % compares radii of circles closest in x or y position and chooses the circle where the radius is closet to expected; rows are frames; columns: radius, x position, y position
    end
    if ~exist('results_firstEntry', 'var')
        results_firstEntry = nan(length(mov),4); % rows are frames; columns: radius, x position, y position
    end
    if ~exist('results_closestX', 'var')
        results_closestX = nan(length(mov),4);
    end
    if ~exist('results_closestY', 'var')
        results_closestY = nan(length(mov),4);
    end
    if ~exist('results_closestRadius', 'var')
        results_closestRadius = nan(length(mov),4);
    end
    if ~exist('results_closestToCenterOfMass', 'var')
        results_closestRadius = nan(length(mov),4);
    end
    
    
    %%% MAIN automation loop; see parameters above
    for frameNum = START_FRAME:FRAME_JUMP:length(mov)
%         frame = mov(frameNum).cdata;
        frame = mov(:,:,frameNum);
        frame = max(max(max(frame)))-frame;
        
%         frame = rgb2gray(frame);
        
        %%% to prevent slow-down /crashing
        if mod(frameNum,100) == 0 && PLOT_RESULTS == 1
            close all
            figure(1)
        end
        
        %%% DESIRED PREPROCESSING STEPS GO HERE:
        frame = imfill(frame);
        frame = imadjust(frame);
        
        
        %     frame = fspecial('average')
        %     h = fspecial('disk');
%         frame = imfilter(frame,filter); % filter defined in the parameters above
        %%%
        
        measurePupil_12_14_16; %%%%%%%%% script handling actual pupil measurement (along with saving and plotting (if desired))
        
        if LAST_FRAME ~= 0 && frameNum == LAST_FRAME
            break;
        end
    end
    
    %%%
    %%% save all data to master struct results
    results = [];
    results.closestRadius = results_closestRadius;
    results.closestX = results_closestX;
    results.closestY = results_closestY;
    results.constrained = results_constrained;
    results.firstEntry = results_firstEntry;
    results.closestToCenterOfMass = results_closestToCenterOfMass;
    results.parameters.sensitivity = SENSITIVITY;
    results.parameters.edgeThresh = EDGE_THRESH;
    results.parameters.radiusRange = RADIUS_RANGE;
    results.parameters.polarity = POLARITY;
    results.parameters.method = METHOD;
    results.parameters.preprocessing = PREPROCESS_DESCRIPTION; %%% modify PREPROCESS_DESCRIPTION definition above to describe preprocessing steps / general notes.
    results.parameters.exampleImage = frame;
    results.parameters.manualRadiusEstimate = manualRadiusEstimate;
    results.ROIs = ROIs;
    
    %%%%%%%% save data to file in location specified by saveDirectory parameter    
    if exist(fileName) ~= 0
        disp('file not saved because a risk of overwriting data exists; check saveDirectory to verify no files with the same name exist');
    else
        disp('saving')
        save(fileName,'results');
        disp(['saved: ' fileName])
    end
    
    %prepare for next video
%     subvideoAlreadyLoaded = 0;
    java.lang.System.gc()
    pause(1)
    close all
    
    
end

% % %     %%% preprocessing ideas
% % %
% % %     % apply gaussian filter to the Image
% % %     %     h = fspecial('gaussian',4,5);
% % %     %     img =  imfilter(img,h,'replicate');
% % %     %
% % %     %     % Convert RGB to HSV
% % %     % [h,s,v] = rgb2hsv(pic);
% % %     %
% % %     % % Erode Hue
% % %     % se = strel('disk',5);
% % %     % erodedHue = imerode(h,se);
% % %     %
% % %     % % Dilate Hue
% % %     % se = strel('disk',8);
% % %     % dilatedErodedHue = imdilate(erodedHue,se);
% % %     %
% % %     % % Convert Image to binary Image
% % %     % bw = im2bw(dilatedErodedHue,graythresh(dilatedErodedHue));
% % %
% % %     %{ ideas
% % %
% % %     % starburst algorithm (probably not that great)
% % %     % horizontal/vertical edge map
% % %     % try using variance image
% % %
% % %
% % %     % readimage.m }{ datastore
% % %
% % %     %}
% % %
% % %    %set(fig,'Name',['Pupil Metric Generator: click and drag a rectangle around the eye. Press Q to quit. Frame: ' num2str(ind)])
% % %     %         frame = imread(pics{frameNum});
% % %     %     frame = mov(frameNum).cdata;
% % %     %     frame = coins
