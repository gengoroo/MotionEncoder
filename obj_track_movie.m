%vision.ForegroundDetector
%https://www.mathworks.com/help/vision/ref/vision.foregrounddetector-system-object.html#d126e121989

function obj_track_movie(fn_full,varargin)

    [pn, fn] = fileparts(fn_full);

    min_blobarea = 250;
    yn_save_movie = 'n';
    for ii=1:nargin-1
        if strcmp('min_blobarea',varargin{ii})
            min_blobarea = varargin{ii+1};
        end
        if strcmp('yn_save_movie',varargin{ii})
            yn_save_movie = varargin{ii+1};
        end
    end

    videoSource = VideoReader(fn_full);
    detector = vision.ForegroundDetector(...
       'NumTrainingFrames', 5, ...%for short movie
       'InitialVariance', 30*30);
    %Perform blob analysis.
    blob = vision.BlobAnalysis(...
       'CentroidOutputPort', false, 'AreaOutputPort', false, ...
       'BoundingBoxOutputPort', true, ...
       'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', min_blobarea);
    %Insert a border.
    shapeInserter = vision.ShapeInserter('BorderColor','White');

    if yn_save_movie =='y'%書き込み準備
        fn_save = [fn(1:end-4) '_track.avi'];
        pn_save = [pn, '\track'];
        mkdir(pn_save);
        writerObj = VideoWriter([pn_save '\' fn_save]);
        open(writerObj);
    end

    % 追跡実行
    videoPlayer = vision.VideoPlayer();
    while hasFrame(videoSource)
         frame  = readFrame(videoSource);
         fgMask = detector(frame);
         bbox   = blob(fgMask);
         out    = shapeInserter(frame,bbox);
         videoPlayer(out);
         writeVideo(writerObj,out);%書き込み  
         pause(0.1);
    end
    release(videoPlayer);


end