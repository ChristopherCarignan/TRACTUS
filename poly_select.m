function [ poly_mask, poly_x, poly_y ] = poly_select( my_img )
% Created by Christopher Carignan on September 18, 2013
% Contact: carignanc@gmail.com, www.christophercarignan.com

% Allows user to create a polynomial selection of an image
% Function first converts image to grayscale if it is RGB
% Function will continue to run until user validates selection by clicking
    % 'Yes' in the resulting dialog box.
% After user validation, function will output:
    % the mask of the selection as 'poly_mask'
    % the coordinates of the polynomial selection as 'poly_x' and 'poly_y'

if ndims(my_img) > 2
    my_img = rgb2gray(my_img); %convert image to grayscale if the image is RGB
end

figure(1)
imshow(my_img)
set(gcf,'NumberTitle','off');
title('Region of interest selection')
hold on

waitfor(msgbox({'1. Click to create a polygon.';'';...
    '2. Make your final click line up with your first click (cursor = circle).';'';...
    '3. When finished, double-click inside selection.'},'ROI selection directions'))

validate = 'No'; %predefine 'validate' variable for while loop

while strcmp(validate,'No')==1 %loop will continue to run until user clicks 'Yes'
    [poly_mask,poly_x,poly_y] = roipoly(my_img);
    
    poly_x = round(poly_x);
    poly_y = round(poly_y);
    
    set(gcf,'NumberTitle','off');
    imshow(immultiply(my_img,poly_mask)) %overlays polynomial selection mask on image
    title('Region of interest selection')
    
    validate = questdlg('Is this selection correct?','Region of interest') ;
end

if strcmp(validate,'Cancel')==1 %if user cancels selection, all output variables are set to zero
    poly_mask=0;
    poly_x=0;
    poly_y=0;
end

close force %close figure

end

