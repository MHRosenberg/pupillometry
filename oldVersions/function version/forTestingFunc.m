subVidName_minusNumber = '~/MHR/a_Research/a_Code/MATLAB/a_Tsao/pupillometry/tsaoPupil.mat';
vidStruct = load(subVidName_minusNumber);
input_vid = vidStruct.data;

% input_vid = input_vid(:,:,1:10);

%%% preallocate centroid, area, etc?

[centroid, area, outputVid ] = quickPupilMeasure(input_vid);