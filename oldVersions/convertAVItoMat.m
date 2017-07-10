%%%%%%%%%%%%%%%%%%%%%%%%%%% CODE TO CONVERT AVI TO .MAT
%%% Matt Rosenberg MHRosenberg@caltech.edu

%%% parameters start
cd '/home/orthogonull/A_MHR/a_Research/a_Anderson/pupil dilation sample movies/2SF1-4_PD_data_day1/'; %%% directory containing avi file
file = 'USS1.avi'; %%% actual name of avi file
name = strrep(file, '.avi', '');
framesPerSubVid = 5000; %%% number of frames to save in each .mat video file
saveDirectory = '/home/orthogonull/A_MHR/a_Research/a_Anderson/pupil dilation sample movies/2SF1-4_PD_data_day1/'; % be sure to add the trailing \ (slashes reversed between unix and windows)
%%% parameters end

tic
vidObj = VideoReader(file);
vidWidth = vidObj.Width;
vidHeight = vidObj.Height;

loadFrames = 1;
startFrame = 1;
subVidNum = 1;

while loadFrames
    mov = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'));
    k = 1;
    while hasFrame(vidObj) && k <=framesPerSubVid;
        mov(k).cdata = readFrame(vidObj);
        disp(['subvideo ' num2str(subVidNum) '; frame ' num2str(k)]);
        k = k+1;
    end
    subVidName = char([saveDirectory name '_' num2str(subVidNum) '.mat']);
    subVidNum = subVidNum + 1;
    if exist(subVidName) ~= 0
        disp('file not saved due to danger of overwriting existing file')
        break
    else
        save(subVidName, 'mov',  '-v7.3') %%% hdf5 wrapped in a mat file. faster loading for newer matlab versions only
    end
    if ~hasFrame(vidObj)
        break
    end
end
toc
