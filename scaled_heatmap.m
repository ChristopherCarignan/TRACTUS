function [ ] = scaled_heatmap( my_data, type )
% Created by Christopher Carignan, 2014
% Contact: carignanc@gmail.com, www.christophercarignan.com

%Creates and plots a heatmap of a given data matrix 'my_data'
%'my_data' can be a grayscale image
%Image is scaled to fit data
%Legend bar is included

if ndims(my_data) == 3
   my_data = rgb2gray(my_data); 
end

scmax = max(abs(my_data(:)));

if strcmp(class(my_data),'uint8') == 1
    scmax = typecast(uint16(scmax),'int16');
end

imagesc(my_data,[0-scmax scmax])

switch type
    case 'color'
    colormap(jet)
    
    case 'bw'
    colormap(gray)
end
colorbar

%Remove X-axis and axis marks
set(gca, 'XTickLabelMode', 'Manual')
set(gca, 'XTick', [])
%Remove Y-axis and axis marks
set(gca, 'YTickLabelMode', 'Manual')
set(gca, 'YTick', [])

axis image

end
