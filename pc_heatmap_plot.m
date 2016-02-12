function pc_heatmap_plot( type, pc_heatmaps, my_pc )
% Created by Christopher Carignan, 2014
% Contact: carignanc@gmail.com, www.christophercarignan.com

% Function 'pc_heatmap_plot' creates scaled heatmaps from a textfile where
% the first column is the PC number and the remain columns are pixels from
% the corresponding heatmap. This textfile is created using either of the
% functions 'ultrasound_pca' or 'us_pca'.

% INPUT arguments:
% 'pc_heatmaps' is an array containing the PC numbers (column 1) and
    % corresponding heatmaps (columns 2:end)
    % NB: this textfile first needs to be imported to the MATLAB workspace
    % as a matrix before it can be used on this function
% 'my_pc' is the number of the PC of the respective heatmap

% RUN example:
% pc_heatmap_plot('color',r32pcaheatmaps,6)

pc_nums = max(pc_heatmaps(:,1));

map_height = size(pc_heatmaps,1)/pc_nums;

figure

scaled_heatmap(pc_heatmaps(my_pc*map_height-map_height+1:my_pc*map_height,2:end), type)

eval(strcat('title(''Heatmap for PC',num2str(my_pc),''')'))

end
