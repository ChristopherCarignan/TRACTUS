function TRACTUS_prep
%% Created by Christopher Carignan, 2014
% Contact: carignanc@gmail.com, www.christophercarignan.com

% The function 'TRACTUS_prep.m' performs a number of tasks in
% preparation for using the function 'TRACTUS.m' to analyze ultrasound
% images. Outputs are saved in a .mat structure object in the
% user-specified RESULTS folder. The outputs in this structure are used as
% inputs for analysis using the 'TRACTUS.m' function.

% The following required functions must be added to Matlab's search path by
% using 'Set Path' in the home menu:

% SRAD.m
% poly_select.m
% us_LoG_check.m
% us_SRAD_check.m


%% TRACTUS_prep.m version
prep_file.TRACTUS_prep_ver = '2.1.1';

% TRACTUS_prep.m version 2.0 (05/14/2015):
% Removed automatic ultrasound fan detection
% Protocol modified for average image creation
% Implemented creation and use of 'us_SRAD_check.m'
% Implemented changes to 'us_LoG_check.m'
% Changed noise mask creation to be compatible across ultrasound platforms
% Added feedback to user on creation of JPEGs when analyzing a video file

% TRACTUS_prep.m version 2.1.1 (09/16/2015):
% Removed loop redundancy
% Added warning for analysis on too few images


%% Determine OS
switch ispc % check OS type
    case 1 % is PC
        my_slash = '\';
    case 0 % is not PC
        my_slash = '/';
end

%% User selection of either individual ultrasound frames or full video file
analysis_type = menu('Will you be analyzing image frames or a video file?',...
    'images', 'video');

switch analysis_type
    case 1 % user chooses IMAGES
        prompt = {'Speaker name:', 'Image file type:'};
        dlg_title = 'TRACTUS';
        def = {'example01', 'jpg'};
        answer = inputdlg(prompt, dlg_title, 1, def);
        
        % user selects folder with ultrasound images
        img_dir = uigetdir('','Specify IMAGE directory');
        eval(strcat('img_dir = ''', img_dir, my_slash, ''';'))
        
        prep_file.analysis_type = 'images';
        [prep_file.speaker, speaker] = deal(answer{1});
        [prep_file.img_type, img_type] = deal(answer{2});
        
    case 2 % user chooses VIDEO
        prep_file.analysis_type = 'video';
        [prep_file.img_type, img_type] = deal('jpg');
        
        prompt = {'Speaker name:'};
        dlg_title = 'TRACTUS';
        def = {'example01'};
        answer = inputdlg(prompt, dlg_title, [1,length(dlg_title)+20], def);
        
        % user selects ultrasound video file
        [video_file, video_path] = uigetfile('', 'Select ultrasound video file');
        
        wait_box = msgbox({'Please wait while JPEG frames are created from video file.';...
            'This may take a few minutes.'}, 'TRACTUS');
        
        % load video file
        eval(strcat('obj = VideoReader(''', video_path, video_file, ''');'))
        vid = read(obj);
        frames = obj.NumberOfFrames;
        
        img_dir = strcat(video_path, 'frames', my_slash);
        
        % create 'frames' folder for creation of images from video
        if exist(img_dir, 'dir') == 0
            % if directory doesn't exist, create it
            eval(strcat('mkdir(''', video_path, 'frames'')'));
        else
            % if directory exists, delete all previous images (if any)
            eval(strcat('delete(''', video_path, 'frames', my_slash, '*', img_type, ''')'));
        end
        
        % write frames from video to 'frames' directory
        for x = 1:frames
            imwrite(vid(:,:,:,x), strcat(img_dir, 'frame-', num2str(x), '.jpg'));
        end
        
        [prep_file.speaker, speaker] = deal(answer{1});
        
        % close dialog box, if it is still open
        if ishandle(wait_box)
            delete(wait_box)
        end
end


%% Define directories
% user selects results folder
results_dir = uigetdir(img_dir, 'Specify RESULTS directory');
eval(strcat('results_dir = ''', results_dir, my_slash, ''';'))

wait_box = msgbox({'Please wait for ROI preparation.';...
    'This may take a few minutes.'}, 'TRACTUS');

prep_file.img_dir = img_dir;
prep_file.results_dir = results_dir;

% count number of 'img_type' files in directory
eval(strcat('imgs = dir([''', img_dir, ''', ''*', img_type, ''']);'))
img_count = length(imgs);


%% Average images for tongue selection %%
% Error dialogue if not enough images for sampling
if floor(img_count*0.05) < 1
    errordlg({'It looks like you don''t have enough images for sampling.';...
        'Please include at least 20 images for a proper analysis.'}, 'TRACTUS')
end

for i = 1:floor(img_count*0.05) % sample only 5% of images for ROI selection
    filename = imgs(i*20).name;
    eval(strcat('my_img = im2double(imread(''', img_dir, filename, '''));')) % read image file
    
    % convert color image to black and white
    if ndims(my_img) > 2
        my_img = rgb2gray(my_img);
    end
    
    % calculate min and max pixel values and scale image
    my_min = min(my_img(:));
    my_max = max(my_img(:));
    img_scaled = (my_img - my_min)/(my_max - my_min);
    
    % add scaled image to matrix
    %img_sel(:,:,i) = im2bw(img_scaled,0.6);
    img_sel(:,:,i) = img_scaled;
end

% calculate average of all images
img_avg = mean(img_sel, 3);


%% Select polynomial coordinates for image extraction %%
% close dialog box, if it is still open
if ishandle(wait_box)
    delete(wait_box)
end

% make polynomial selection using 'poly_select.m' function
% log mask dimensions/coordinates
roi_mask = poly_select(img_avg);
prep_file.roi_mask = roi_mask;

% get boundaries of polygonal selection mask
poly_coords = bwboundaries(roi_mask);
[maxlength, maxidx] = max(cellfun('length', poly_coords));

% find coordinates of rotated polygonal selection mask
min_x = min(poly_coords{maxidx}(:,2));
max_x = max(poly_coords{maxidx}(:,2));

min_y = min(poly_coords{maxidx}(:,1));
max_y = max(poly_coords{maxidx}(:,1));

roi_coords = [min_y max_y; min_x max_x];

% choose middle image in directory for filter parameter check
my_img = round(img_count/2);
filename = imgs(my_img).name;

% read image file
eval(strcat('my_img = imread(''', img_dir, filename, ''');'))

% convert color image to black and white
if ndims(my_img) > 2
    my_img = rgb2gray(my_img);
end

% create noise matrix and mask
noise = randi([im2uint8(my_min) im2uint8(my_max)], size(my_img,1), size(my_img,2));
rev_mask = abs(roi_mask - 1);
noise_mask = uint8(immultiply(noise, rev_mask));
prep_file.noise_mask = noise_mask;

% blackout pixels outside of the ROI and apply noise mask
my_img = immultiply(my_img, roi_mask);
my_img = my_img + noise_mask;

% call 'us_SRAD_check.m'
[niter, lambda, rect] = us_SRAD_check(my_img, roi_coords, roi_mask);
my_img = SRAD(my_img, niter, lambda, rect);
my_img = medfilt2(my_img, [round(size(my_img,1)/50) round(size(my_img,2)/50)]);

% call 'us_LoG_check.m'
[hsize, sigma] = us_LoG_check(my_img, roi_coords, roi_mask);

% log filter parameters
prep_file.LoG_hsize = hsize;
prep_file.LoG_sigma = sigma;
prep_file.SRAD_niter = niter;
prep_file.SRAD_lambda = lambda;
prep_file.SRAD_rect = rect;


%% Save TRACTUS preparation output file
eval(strcat('save(''', results_dir, speaker,'_prep.mat'', ''prep_file'')'))

% close dialog box, if it is still open
if ishandle(wait_box)
    delete(wait_box)
end

% close figure
close force

end
