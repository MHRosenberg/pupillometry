function [centroidReturn, areaReturn, output_vidReturn ] = quickPupilMeasure(input_vid)

mov = input_vid;

% PREALLOCATE THESE if using globabl!
% global centroid area output_vid % works but probably better to avoid global

centroid = nan(size(input_vid,3),2);
area = nan(size(input_vid,3),1);
output_vid = nan(size(input_vid));


%%% START PARAMETERS (read CAREFULLY!)
%%% circle finding algorithm parameters (imfindcircles.m) parameters
SENSITIVITY = .97;%.95%!!!0.97; %0.95; %%%%%%%%%% higher values give more circles
EDGE_THRESH = 0.00001;%.0001;%!!!0.005 0.001 %0.03; %0.01; %0.000001; %%%%%%%%%% lower values give more circles
LOWER_RADIUS_BOUND = 5;%20; % in pixels (INCREASE HERE TO EXCLUDE IMPOSSIBLY SMALL CIRCLES)
% RADIUS_RANGE = [LOWER_RADIUS_BOUND, ceil(min(abs(roi_topLeftX-roi_topRightX), abs(roi_topLeftY-roi_bottomLeftY))/2)];
RADIUS_RANGE = [LOWER_RADIUS_BOUND, 100]
POLARITY = 'bright'; % 'bright' for white circles; 'dark' for black circles
METHOD = 'PhaseCode'; % PhaseCode or TwoStage (slower)
%     filter = ones(20,20) / 100; %%%%% used to brighten and smooth image PROBABLY NEEDS TO BE CHANGED FOR EACH ILLUMINATION LEVEL!
filter = ones(10,10) / 100;
%%%%%%%%alternate way to define the RADIUS_RANGE
%%% extraSearchPercentOfEstimate = 50;
%%% RADIUS_RANGE = [max(LOWER_RADIUS_BOUND,ceil(manualRadiusEstimate*(extraSearchPercentOfEstimate/100))), ceil(manualRadiusEstimate*((extraSearchPercentOfEstimate+100)/100))]; %%%%%% USER SPECIFIED RADIUS ESTIMATE


% automation parameters
START_FRAME = 1; %%%%%%%%%%%% frame to start analysis at
FRAME_JUMP = 1; % number of frames to advance by in automation
LAST_FRAME = 10; % set to 0 if you want to process all frames
saveDirectory = '~/'; % MAKE SURE TO HAVE TRAILING '/' !!!

AVI_OUTPUT_DIRECTORY = '~/'; %%% where summary avi file will be saved; DON'T FORGET THE TRAILING SLASH!!!
AVI_OUTPUT_NAME = 'tsaoTest.avi';

outputVideo = VideoWriter(fullfile(AVI_OUTPUT_DIRECTORY,AVI_OUTPUT_NAME)); %%%% name output file here
annotatedMov = struct('cdata', cell(1,NUM_FRAMES));
open(outputVideo)

% %%% output file parameters
% dateStr = datestr(datetime,'mm/dd/yy');
% dateStr = strrep(dateStr,'/','_');
% fileName = char([saveDirectory 'results_' dateStr '_subVid_' num2str(subVid) '.mat']);

%%% MAIN automation loop; see parameters above
figure
for frameNum = START_FRAME:FRAME_JUMP:length(mov)
    display(['frame: ' num2str(frameNum)]);
    %         frame = mov(frameNum).cdata;
    %     frame = mov(:,:,1);
    frame = mov(:,:,frameNum);
    frame = max(max(max(frame)))-frame;
    
    %         frame = rgb2gray(frame);
    
    %%% to prevent slow-down /crashing
    %     if mod(frameNum,100) == 0 && PLOT_RESULTS == 1
    %         close all
    %         figure(1)
    %     end
    
    %%% DESIRED PREPROCESSING STEPS GO HERE:
    frame = imfill(frame);
    frame = imadjust(frame);
    
    
    %     frame = fspecial('average')
    %     h = fspecial('disk');
    %         frame = imfilter(frame,filter); % filter defined in the parameters above
    %%%
    
    %     measurePupil_12_14_16; %%%%%%%%% script handling actual pupil measurement (along with saving and plotting (if desired))
    measurePupil_funcVersion01_12_17
    
    if LAST_FRAME ~= 0 && frameNum == LAST_FRAME
        break;
    end
end

centroidReturn = centroid;
areaReturn = area;
output_vidReturn = output_vid;

end

%%%
% %%% save all data to master struct results
% results = [];
% results.parameters.sensitivity = SENSITIVITY;
% results.parameters.edgeThresh = EDGE_THRESH;
% results.parameters.radiusRange = RADIUS_RANGE;
% results.parameters.polarity = POLARITY;
% results.parameters.method = METHOD;


% results.closestRadius = results_closestRadius;
% results.closestX = results_closestX;
% results.closestY = results_closestY;
% results.constrained = results_constrained;
% results.firstEntry = results_firstEntry;
% results.closestToCenterOfMass = results_closestToCenterOfMass;
% results.parameters.preprocessing = PREPROCESS_DESCRIPTION; %%% modify PREPROCESS_DESCRIPTION definition above to describe preprocessing steps / general notes.
% results.parameters.exampleImage = frame;
% results.parameters.manualRadiusEstimate = manualRadiusEstimate;
% results.ROIs = ROIs;

%%%%%%%% save data to file in location specified by saveDirectory parameter
% if exist(fileName) ~= 0
%     disp('file not saved because a risk of overwriting data exists; check saveDirectory to verify no files with the same name exist');
% else
%     disp('saving')
%     save(fileName,'results');
%     disp(['saved: ' fileName])
% end


%%%% this file performs the actual measurement of the pupil and is called by pupillometryForThanos_auto12_13_16.m
% Matt Rosenberg MHRosenberg@caltech.edu

function getPupilValues()

% to suppress warnings
if isempty(warning('query','last')) == 0 % code can be accelerated by running imfindcircles.m on subsets of the radius range but this biases the results...
    warning('off','last')
end

%%% main circle finding algorith using phasecode parameter
[centers, radii, metric] = imfindcircles(frame,RADIUS_RANGE, ...
    'Method', METHOD, 'ObjectPolarity',POLARITY, 'Sensitivity', SENSITIVITY, 'EdgeThreshold', EDGE_THRESH);

if isempty(centers) && METHOD == 'PhaseCode'
    [centers, radii, metric] = imfindcircles(frame,RADIUS_RANGE, ...
        'Method', 'TwoStage', 'ObjectPolarity',POLARITY, 'Sensitivity', SENSITIVITY, 'EdgeThreshold', EDGE_THRESH);
elseif isempty(centers) && METHOD == 'TwoStage'
    [centers, radii, metric] = imfindcircles(frame,RADIUS_RANGE, ...
        'Method', 'PhaseCode', 'ObjectPolarity',POLARITY, 'Sensitivity', SENSITIVITY, 'EdgeThreshold', EDGE_THRESH);
end

% subFrame = frame;
% C = centerOfMass(subFrame);

% C(2) = C(2) +roi_topLeftX;
% C(1) = C(1) +roi_topLeftY;

% %%%%%%%%%%%%%% for if radius might be dark
if isempty(centers)
    temp = POLARITY;
    if strcmp(POLARITY,'bright')
        POLARITY = 'dark';
    elseif strcmp(POLARITY,'dark')
        POLARITY = 'bright';
    else
        display('polarity in invalid state')
    end
    [centers, radii, metric] = imfindcircles(frame,RADIUS_RANGE, ...
        'Method', 'PhaseCode', 'ObjectPolarity',POLARITY, 'Sensitivity', SENSITIVITY_1SHOT, 'EdgeThreshold', EDGE_THRESH_1SHOT);
end

%
% centersStrong = centers(1:numCirclesToDraw,:);
% centersStrong(1:numCirclesToDraw,1) = centersStrong(1:numCirclesToDraw,1);
% centersStrong(1:numCirclesToDraw,2) = centersStrong(1:numCirclesToDraw,2);
% radiiStrong5 = radii(1:numCirclesToDraw);
% metricStrong5 = metric(1:numCirclesToDraw);

% plot cross for actual pupil measure in order of saved results

%         imshow(frame,'DisplayRange', [184 4092]);
imshow(frame);
pv1 = [centers(1,1) centers(1,2)-radii(1,1)]; % pts for vertical line
pv2 = [centers(1,1) (centers(1,2)+radii(1,1))];
ph1 = [centers(1,1)-radii(1,1) centers(1,2)]; % pts for horizontal line
ph2 = [centers(1,1)+radii(1,1) (centers(1,2))];
hold off;
%         viscircles(centersStrong, radiiStrong5,'EdgeColor','b','LineStyle',':','LineWidth',.00005); %%%%%%%%%%%%%% plot circles
hold on
plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','r');
plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','r');
hold on

%%%%%%%%%%%% save video of results
temp = getframe;
annotatedMov(rankedFrameInd).cdata = temp.cdata;

% for ii = FIRST_FRAME:LAST_FRAME
%     writeVideo(outputVideo,annotatedMov(ii).cdata);
%     disp(['saving frame: ' num2str(ii) ' of ' num2str(LAST_FRAME) ' to avi file in working directory'])
% end
%%%%%%%%%%

centroid(frameNum,:) = [centers(1,1) centers(1,2)]; % x and y respectively
area(frameNum) = pi*(radii(1)^2);
output_vid(frameNum,:,:) = temp;

end


