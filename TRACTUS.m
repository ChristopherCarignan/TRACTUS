function TRACTUS
%% Created by Christopher Carignan, 2014
% Contact: carignanc@gmail.com, www.christophercarignan.com

% The function 'TRACTUS.m' analyzes ultrasound images using a Principal
% Components Analysis model. Results are saved in the RESULTS folder which
% was specified by the user when running 'TRACTUS_prep.m'

% The following required functions must be added to Matlab's search path by
% using 'Set Path' in the home menu:

% SRAD.m


%% User selects TRACTUS_prep output file
[prep_file, prep_path] = uigetfile('','Select TRACTUS_prep output file');
eval(strcat('load(''', prep_path, prep_file,''');'))


%% TRACTUS_prep.m and TRACTUS.m versions
prep_version = prep_file.TRACTUS_prep_ver;
run_version = '2.0';

% TRACTUS.m version 1.1 (11/03/2014):
% added "heatmap_height" and "heatmap_width" dimensions to *_misc.txt output file

% TRACTUS.m version 1.2 (11/07/2014):
% modified estimation of run time

% TRACTUS.m version 2.0 (05/30/2015):
% updated for compatibility with TRACTUS_prep.m version 2.0
% added ability to choose either number of PCs or PCA variance threshold
    % for optimization of number of PCs
% added SRAD filter argument values to misc output file


%% User prompts with input arguments 

% Choose either number of PCs or PCA variance threshold
pc_choice = menu(['Do you want to choose a specific number of PCs to retain in the analysis' sprintf('\n')...
    'or optimize the number of PCs for a percentage of variance explained?'],...
    'Choose number of PCs','Optimize for percentage of variance');

switch pc_choice
    case 1 % user chose to use a specific number of PCs
        pc_num = str2double(inputdlg('Please specify the number of PCs you want to use.','TRACTUS: PC choice'));
    case 2 % user chose to optimize the number of PCs for variance explained
        pc_thresh = str2double(inputdlg(['Please specify the percentage of variance you want to account for.' sprintf('\n')...
            '(NB: Please use an integer value, without a percentage (%) symbol.)'],'TRACTUS: PC number optimization'));
end

prompt = {['Downsampling (0 = 0% resolution, 1 = 100% resolution):' sprintf('\n')...
    '(NB: This parameter may greatly affect run time.)'],...
    'Occlusal plane rotation (degrees, counter-clockwise):',...
    ['Are you providing a filelist for analysis? (y/n)' sprintf('\n')...
    'The filelist must be a 1-column vector of 0 and 1.' sprintf('\n')...
    '(NB: If you put ''n'', all images will be used for analysis.)']};
dlg_title = 'TRACTUS inputs';
def = {'0.3','0',''};

answer = inputdlg(prompt, dlg_title, 2, def);

% create variables from user inputs
disc_fac = str2double(answer{1});
rot_ang = str2double(answer{2});
filelist_check = answer{3};

% read variables from prep file
speaker = prep_file.speaker;
img_type = prep_file.img_type;
hsize = prep_file.LoG_hsize;
sigma = prep_file.LoG_sigma;
niter = prep_file.SRAD_niter;
lambda = prep_file.SRAD_lambda;
speckle_rect = prep_file.SRAD_rect;
roi_mask = prep_file.roi_mask;
noise_mask = prep_file.noise_mask;


%% Define directories
img_dir = prep_file.img_dir;
results_dir = prep_file.results_dir;

% count number of 'img_type' files in directory
eval(strcat('imgs = dir([''', img_dir, ''', ''*', img_type, ''']);'))
img_count = length(imgs);

% read file list if supplied by user; if not, create one
if filelist_check == 'y'
    [filelist_name, filelist_path] = uigetfile('', 'Select filelist (*.txt)');
    eval(strcat('filelist = dlmread(''', filelist_path, filelist_name, ''','','');'))
elseif filelist_check == 'n'
    filelist = ones(img_count,1);
else
    % error message if user doesn't give an answer in the filelist field
    errordlg({'It looks like you forgot to specify a FILELIST preference';...
        'in the input prompt... please try again!'}, 'TRACTUS')
    return
end


%% Create filters for imaging filtering

% create Laplacian of Gaussian filter
LoG_filt = fspecial('log',hsize,sigma);

% choose middle image in directory for filter parameter check
img_num = round(img_count/2);
filename = imgs(img_num).name;

% read image file
eval(strcat('my_img = imread(''', img_dir, filename, ''');'))

% convert color image to black and white
if ndims(my_img) > 2
    my_img = rgb2gray(my_img);
end


%% Find coordinates of rotated image mask
if ndims(my_img) > 2
    pre_rot = im2uint8(rgb2gray(ones(size(my_img))));
else
    pre_rot = im2uint8(ones(size(my_img)));
end
rot_img = immultiply(pre_rot, roi_mask);
rot_img = imrotate(rot_img, rot_ang, 'bicubic', 'loose');% rotate mask to occlusal plane

% get boundaries of rotated polygonal selection mask
poly_coords = bwboundaries(rot_img);
[maxlength, maxidx] = max(cellfun('length', poly_coords));

% find coordinates of rotated polygonal selection mask
min_x = min(poly_coords{maxidx}(:,2));
max_x = max(poly_coords{maxidx}(:,2));

min_y = min(poly_coords{maxidx}(:,1));
max_y = max(poly_coords{maxidx}(:,1));


%% Estimate run time based on number of images
% broad approximation of run time is based on a Dell Optiplex 990 with:
% PC running Windows 7 64-bit, SP 1
% Intel Core i7-2600 CPU @ 3.40 GHz
% 8 GB RAM

resolution = round((max_x - min_x)*(max_y - min_y)*disc_fac);
seconds = img_count*sqrt(resolution)/700;
minutes = seconds/60;
hours = minutes/60;
minutes = round((minutes*100))/100;
hours = round((hours*100))/100;

eval(strcat('wait_box = msgbox({''TRACTUS will now analyze your images.'';''This will take approximately...',...
    num2str(minutes),' minutes (',num2str(hours),' hours)''},''TRACTUS analysis'');'))


%% Prepare image matrix for PC analyses
x = 1;
for i = 1:length(filelist)
    
    if filelist(i) == 1
        filename = imgs(i).name;
        
        eval(strcat('my_img = imread(''', img_dir, filename, ''');')) % read image file
        
        if ndims(my_img) > 2
            my_img = rgb2gray(my_img); % convert color image to black and white
        end
        
        % blackout pixels outside of ROI and apply noise mask
        my_img = immultiply(my_img, roi_mask);
        my_img = my_img + noise_mask;
        
        % noise reduction via anisotropic filter and median filter
        my_img = SRAD(my_img, niter, lambda, speckle_rect);
        my_img = medfilt2(my_img, [round(size(my_img,1)/50) round(size(my_img,2)/50)]);
        
        % filter image (Laplacian of Gaussian)
        my_img = imfilter(my_img, LoG_filt);
        
        % mask, rotate, and crop image
        my_img = immultiply(my_img, roi_mask); % overlays polynomial selection mask on image
        my_img = imrotate(my_img, rot_ang,'bicubic','loose'); % rotate image to occlusal plane
        img_crop = my_img(min_y:max_y,min_x:max_x); % create cropped image
        
        % downsample image using bicubic interpolation (for reduced dimensionality in PCA model)
        pca_crop = imresize(img_crop, disc_fac, 'bicubic');
        
        % convert cropped image to vector, aggregate vectors for all tokens
        crop_vec = reshape(pca_crop.', 1, []);
        crop_vecs(x,:) = crop_vec;
        
        % log filename
        filenames{x,1} = filename;
        
        x = x + 1;
    end
end

filenames = char(filenames);

pca_height = size(pca_crop,1);
pca_width = size(pca_crop,2);


%% Log and save misc. parameters used
% log speaker name
misc_output{1} = 'speaker_name';
misc_output{2} = speaker;
% log discretation factor used for analysis
misc_output{5} = 'downsampling_factor';
misc_output{6} = num2str(disc_fac);
% log occlusal plane counter-clockwise rotation angle
misc_output{7} = 'rotation_ang';
misc_output{8} = num2str(rot_ang);
% log LoG filter parameter used: hsize
misc_output{9} = 'LoG_hsize';
misc_output{10} = num2str(hsize);
% log LoG filter parameter used: sigma
misc_output{11} = 'LoG_sigma';
misc_output{12} = num2str(sigma);
% log SRAD filter parameter used: niter
misc_output{13} = 'SRAD_niter';
misc_output{14} = num2str(niter);
% log SRAD filter parameter used: lambda
misc_output{15} = 'SRAD_lambda';
misc_output{16} = num2str(lambda);
% log SRAD filter parameter used: rect
misc_output{17} = 'SRAD_rect';
misc_output{18} = num2str(speckle_rect);
% log PCA heatmap dimension (height)
misc_output{19} = 'heatmap_height';
misc_output{20} = num2str(pca_height);
% log PCA heatmap dimension (width)
misc_output{21} = 'heatmap_width';
misc_output{22} = num2str(pca_width);
% log version of TRACTUS_prep function used
misc_output{23} = 'TRACTUS_prep_ver';
misc_output{24} = prep_version;
% log version of TRACTUS function used
misc_output{25} = 'TRACTUS_ver';
misc_output{26} = run_version;


%% Free up memory
clearvars -except filenames crop_vecs pc_num pc_choice pc_thresh speaker pca_height pca_width results_dir wait_box misc_output


%% Run PC Analysis on cropped image vector matrix
crop_vecs = im2double(crop_vecs);
% run PCA model
[pc, scores, pcvars] = pca(crop_vecs);
% calculate cumulative percentage explained by PCs
perc_exp = cumsum(pcvars./sum(pcvars)*100);

% verify if user chose the # of PCs to retain or a variance threshold
if pc_choice == 2
   pc_num = find(perc_exp >= pc_thresh,1);
end

% log number of PCs used
misc_output{3} = 'PC_num';
misc_output{4} = num2str(pc_num);

% save logged parameters to textfile
eval(strcat('fid = fopen(''', results_dir, speaker, '_misc.txt'', ''wt'');'))
fprintf(fid, '"%s"\t"%s"\n', misc_output{:});
fclose(fid);

% obtain residuals
[residuals] = pcares(crop_vecs, pc_num);

% make array of PC scores
pc_data = scores(:,1:pc_num);


%% Convert vectors back to cropped image (i.e. heatmaps)
for i = 1:pc_num
    % column 1: PC number
    pca_heatmaps(1+pca_height*(i-1) : pca_height+pca_height*(i-1), 1) = i;
    % remap PC loadings to spatial orientation (i.e. PC heatmaps)
    pca_heatmaps(1+pca_height*(i-1) : pca_height+pca_height*(i-1), 2 : pca_width+1) = reshape(pc(:,i), pca_width, pca_height).';
    
    % column 1: PC number
    res_heatmaps(1+pca_height*(i-1) : pca_height+pca_height*(i-1), 1) = i;
    % remap PC residuals to spatial orientation (i.e. residual heatmaps)
    res_heatmaps(1+pca_height*(i-1) : pca_height+pca_height*(i-1), 2 : pca_width+1) = reshape(residuals(i,:), pca_width, pca_height).';
end


%% Save results files to RESULTS directory
% save PC scores, filenames, and percentages of variance explained
eval(strcat('dlmwrite(''', results_dir, speaker, '_pc_scores.txt'', pc_data, ''delimiter'', ''\t'')'))
eval(strcat('dlmwrite(''', results_dir, speaker, '_filenames.txt'', filenames, ''delimiter'', '''')'))
eval(strcat('dlmwrite(''', results_dir, speaker, '_var_explained.txt'', perc_exp, ''delimiter'', '''')'))

% save PC and residual heatmaps
eval(strcat('dlmwrite(''', results_dir, speaker, '_pc_heatmaps.txt'', pca_heatmaps, ''delimiter'', ''\t'')'))
eval(strcat('dlmwrite(''', results_dir, speaker, '_res_heatmaps.txt'', res_heatmaps, ''delimiter'', ''\t'')'))

% save vector matrix as bitmap image file
eval(strcat('imwrite(crop_vecs, ''', results_dir, speaker, '_vecs.bmp'')'))

% close dialog box, if it is still open
if ishandle(wait_box)
    delete(wait_box)
end

end
