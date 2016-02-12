function sd_idx = divvy(lengthsd,numframes,framesize)

% Divide a series of integers specified by lengthsd into some
% number of frames specified by numframes.

% This function is intended to be used to find partition
% points in sampled data series, and the lengthsd parameter
% will usually be the length of a data series.

% lengthsd  = an integer >= 1
% numframes = number of frames into which lengthsd is divided
% framesize = optional fixed size for each frame; if framesize
%             is 0 or undefined, frames are dynamically sized
%             but should never differ from other frames by
%             more than 1

% NOTE: lengthsd, numframes, and framesize should all be positive
% integers, though it isn't required that they be of an integer type,
% i.e. a floating point value like 3.000 is okay.

% Return a vector of structures that specify the start and
% endpoints of each divvied frame.

% Example: sd is a vector of 20 sampled data points, and
% you want to partition it into three more-or-less equal
% frames that include all the data points.

%>> d = divvy(20,3)
% d =
% 1x3 struct array with fields:
%    endpt
%    startpt
%>> d(1)
%ans =
%      endpt: 7
%    startpt: 1
%>> d(2)
%ans =
%      endpt: 13
%    startpt: 8
%>> d(3)
%ans =
%      endpt: 20
%    startpt: 14

% default to framesize of 0
if exist('framesize') == 0
 framesize = 0;
end

%if ((numframes <= 0) || (mod(numframes,1)))
%    error('Number of frames must be a positive integer.');
%elseif ((lengthsd <= 0) || (mod(lengthsd,1)))
%    error('Length must be a positive integer.');
%elseif ((framesize <= 0) || (mod(framesize,1)))
%    error('Region size must be a positive integer.');
%elseif (numframes > lengthsd)
%    error('Number of frames exceeds the length.');
%end

% divvy into correct number of frames of (mostly) equal size
start = 1;
for i = 1:numframes
   sd_idx(i).startpt = start;
   sd_idx(i).endpt   = round(i*lengthsd/numframes);
   start             = sd_idx(i).endpt + 1;
end

% adjust size of each frame to framesize, if requested, and center
% new frame in the old frame
if framesize
   for i = 1:numframes
       frame_length      = sd_idx(i).endpt - sd_idx(i).startpt + 1;
       [startpt,endpt]   = center_frame(frame_length,framesize);
       sd_idx(i).endpt   = sd_idx(i).startpt + endpt   - 1;
       sd_idx(i).startpt = sd_idx(i).startpt + startpt - 1;
   end
end
