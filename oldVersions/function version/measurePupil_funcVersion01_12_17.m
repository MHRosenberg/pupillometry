%%%% this file performs the actual measurement of the pupil and is called by pupillometryForThanos_auto12_13_16.m
% Matt Rosenberg MHRosenberg@caltech.edu


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

subFrame = frame;
C = centerOfMass(subFrame);
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

centroid(frameNum,:) = [centers(1,1) centers(1,2)]; % x and y respectively
area(frameNum) = pi*(radii(1)^2);


% POLARITY = temp;
% display(['polarity: ' POLARITY]);

% if ~isempty(centers)
%     
%     display([char(10) num2str(size(centers,1)) ' CIRCLE(s) FOUND!! in frame: ' num2str(frameNum) ' ; sensitivity: ' num2str(SENSITIVITY) ...
%         ' ; edge thresh: ' num2str(EDGE_THRESH) ' polarity: ' POLARITY '; method: ' METHOD char(10) 'radius: ' num2str(radii(1))]);
%     
%     centers(:,1) = centers(:,1) + roi_topLeftX; % x vals in coordinates of box
%     centers(:,2) = centers(:,2) + roi_topLeftY; % y vals in coordinates of box
%     
%     [c indClosestX] = min(abs(centers(1:5,1)-estCenterX)); %%% choose circle with x pos closest to estimated. 
%     [c indClosestY] = min(abs(centers(1:5,2)-estCenterY)); %%% choose circle with y pos closest to estimated. 
%     [c indClosestRadius] = min(abs(radii(1:5,1)-manualRadiusEstimate)); %%% choose circle with y pos closest to estimated.
%     [c indClosestToCenterOfMass] = min(sqrt((C(2)-centers(1:5,1)).^2 + (C(1)-centers(1:5,2)).^2));  % NOTE MISMATCHING X,Y CONVENTIONS try swapping as sanity check
%     
%     if indClosestX ~= indClosestY
%        if abs(radii(indClosestX)-manualRadiusEstimate) < abs(radii(indClosestY)-manualRadiusEstimate)  
%             indChosen = indClosestX;
%        else
%             indChosen = indClosestY;
%        end
%     else
%         indChosen = indClosestX;
%     end
%     
%     
%     %%%%% confidence measure here for if indClosestX ~= indClosestY
%     
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVES VALUES HERE!
%     xPos = centers(indChosen,1);
%     yPos = centers(indChosen,2);
% %     radii(indChosen) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% for debug only 
% %     xPos 
% %     yPos 
% %     metric(indChosen) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% for debug only
%     results_constrained(frameNum, :) = [radii(indChosen) xPos yPos metric(indChosen)]; % compares circles closest to expected x and y positions and chooses the one that's closest to the expected radius
%     
%     xPos = centers(1,1);
%     yPos = centers(1,2);
%     results_firstEntry(frameNum, :) = [radii(1) xPos yPos metric(1)]; % saves whatever circle imfindcircles thought was strongest
%     
%     xPos = centers(indClosestX,1);
%     yPos = centers(indClosestX,2);
%     results_closestX(frameNum, :) = [radii(indClosestX) xPos yPos metric(indClosestX)]; % saves whatever circle was closest to expected x pos
%     
%     xPos = centers(indClosestY,1);
%     yPos = centers(indClosestY,2);
%     results_closestY(frameNum, :) = [radii(indClosestY) xPos yPos metric(indClosestY)]; % saves whatever circle was closest to expected y pos
%     
%     xPos = centers(indClosestRadius,1);
%     yPos = centers(indClosestRadius,2);
%     results_closestRadius(frameNum, :) = [radii(indClosestRadius) xPos yPos metric(indClosestRadius)]; % saves whatever circle was closest to expected radius
%     
%     xPos = centers(indClosestToCenterOfMass,1);
%     yPos = centers(indClosestToCenterOfMass,2);
%     results_closestToCenterOfMass(frameNum, :) = [radii(indClosestToCenterOfMass) xPos yPos metric(indClosestToCenterOfMass)]; % saves whatever circle was closest to expected radius
%     
%     
%     %%%% PLOTS RESULTS IF PARAMETER SET IN pupillometryForThanos_auto is set to 1; 
%     if PLOT_RESULTS ==1
%         % draw circles for best 5 found
%         numCirclesFound = size(centers,1);
%         if numCirclesFound < MAX_NUM_DRAWN_CIRCLES
%             numCirclesToDraw = numCirclesFound;
%         else
%             numCirclesToDraw = MAX_NUM_DRAWN_CIRCLES;
%         end
%         centersStrong = centers(1:numCirclesToDraw,:);
%         centersStrong(1:numCirclesToDraw,1) = centersStrong(1:numCirclesToDraw,1);
%         centersStrong(1:numCirclesToDraw,2) = centersStrong(1:numCirclesToDraw,2);
%         radiiStrong5 = radii(1:numCirclesToDraw);
%         metricStrong5 = metric(1:numCirclesToDraw);
%         
%         % plot cross for actual pupil measure in order of saved results
%         
% %         imshow(frame,'DisplayRange', [184 4092]); 
%         imshow(frame); 
%         pv1 = [centers(indChosen,1) centers(indChosen,2)-radii(indChosen,1)]; % pts for vertical line
%         pv2 = [centers(indChosen,1) (centers(indChosen,2)+radii(indChosen,1))];
%         ph1 = [centers(indChosen,1)-radii(indChosen,1) centers(indChosen,2)]; % pts for horizontal line
%         ph2 = [centers(indChosen,1)+radii(indChosen,1) (centers(indChosen,2))];
%         hold off;
% %         viscircles(centersStrong, radiiStrong5,'EdgeColor','b','LineStyle',':','LineWidth',.00005); %%%%%%%%%%%%%% plot circles
%         hold on
%         plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','r');
%         plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','r');
%         hold on
%         
%         pv1 = [centers(1,1) centers(1,2)-radii(1,1)]; % pts for vertical line
%         pv2 = [centers(1,1) (centers(1,2)+radii(1,1))];
%         ph1 = [centers(1,1)-radii(1,1) centers(1,2)]; % pts for horizontal line
%         ph2 = [centers(1,1)+radii(1,1) (centers(1,2))];
%         plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','y');
%         plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','y');
%         hold on
%         
%         pv1 = [centers(indClosestX,1) centers(indClosestX,2)-radii(indClosestX,1)]; % pts for vertical line
%         pv2 = [centers(indClosestX,1) (centers(indClosestX,2)+radii(indClosestX,1))];
%         ph1 = [centers(indClosestX,1)-radii(indClosestX,1) centers(indClosestX,2)]; % pts for horizontal line
%         ph2 = [centers(indClosestX,1)+radii(indClosestX,1) (centers(indClosestX,2))];
%         plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','g');
%         plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','g');
%         hold on
%         
%         pv1 = [centers(indClosestY,1) centers(indClosestY,2)-radii(indClosestY,1)]; % pts for vertical line
%         pv2 = [centers(indClosestY,1) (centers(indClosestY,2)+radii(indClosestY,1))];
%         ph1 = [centers(indClosestY,1)-radii(indClosestY,1) centers(indClosestY,2)]; % pts for horizontal line
%         ph2 = [centers(indClosestY,1)+radii(indClosestY,1) (centers(indClosestY,2))];
%         plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','b');
%         plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','b');
%         hold on
%         
%         pv1 = [centers(indClosestRadius,1) centers(indClosestRadius,2)-radii(indClosestRadius,1)]; % pts for vertical line
%         pv2 = [centers(indClosestRadius,1) (centers(indClosestRadius,2)+radii(indClosestRadius,1))];
%         ph1 = [centers(indClosestRadius,1)-radii(indClosestRadius,1) centers(indClosestRadius,2)]; % pts for horizontal line
%         ph2 = [centers(indClosestRadius,1)+radii(indClosestRadius,1) (centers(indClosestRadius,2))];
%         plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','w');
%         plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','w');
%         hold on
%         
%         pv1 = [centers(indClosestToCenterOfMass,1) centers(indClosestToCenterOfMass,2)-radii(indClosestToCenterOfMass,1)]; % pts for vertical line
%         pv2 = [centers(indClosestToCenterOfMass,1) (centers(indClosestToCenterOfMass,2)+radii(indClosestToCenterOfMass,1))];
%         ph1 = [centers(indClosestToCenterOfMass,1)-radii(indClosestToCenterOfMass,1) centers(indClosestToCenterOfMass,2)]; % pts for horizontal line
%         ph2 = [centers(indClosestToCenterOfMass,1)+radii(indClosestToCenterOfMass,1) (centers(indClosestToCenterOfMass,2))];
%         plot([pv1(1),pv2(1)],[pv1(2),pv2(2)],'Color','c');
%         plot([ph1(1),ph2(1)],[ph1(2),ph2(2)],'Color','c');
%         hold on
%         
%         plot(C(2),C(1), 'rx');
%         hold on;
%         
%         if WAIT_FOR_BUTTON_PRESS_AFTER_PLOT == 1; 
%             k = waitforbuttonpress;
%         elseif PAUSE_DURATION_AFTER_PLOT ~= 0
%             pause(PAUSE_DURATION_AFTER_PLOT);
%         end
%     end
% else
%     display('No circles found');
% end


% clear c 

% display('waiting for input');



%%%% code no longer used:

% colors = colormap('jet'); %%%%%%%%% blue to red

% measure
% figure(1)
% imshow(frame,'Border','tight')
% colormap(jet)
% hold on

% TINY_VAL = 0.000001;
% POLARITY = 'bright'; % bright or dark

% RADIUS_RANGE = [40 80];
% 
% EXPECTED_RADIUS = 22;

% SENSITIVITY_1SHOT = 0.97; %0.95;
% EDGE_THRESH_1SHOT = 0.001; %0.01; %0.000001;
% MAX_NUM_DRAWN_CIRCLES = 10;

%         [centers, radii, metric] = imfindcircles(frame,RADIUS_RANGE, ...
%             'Method', 'PhaseCode', 'ObjectPolarity',POLARITY,'Sensitivity',sensitivity,'EdgeThreshold',edgeThresh);
%         [centers, radii, metric] = imfindcircles(frame,RADIUS_RANGE);

