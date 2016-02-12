function [ hsize, sigma ] = us_LoG_check( my_img, crop_coords, roi_mask )
% Created by Christopher Carignan, 2015
% Contact: carignanc@gmail.com, www.christophercarignan.com

% us_LoG_check.m version 1.2 (09/16/2015):
% Updated Java syntax to be compatible with Matlab R2015

% default filter values
hsize = 60;
sigma = 0.4;

% create figure for plotting
fig = figure;
set(fig,'NumberTitle','off');
title('LoG filtering results')
hold on

% call main plotting function
LoG_plotter(hsize,sigma,my_img,crop_coords,roi_mask)

% hold function until user saves filter parameters @save_filt
uiwait

%% Main plotting function
    function LoG_plotter(hsize,sigma,my_img,crop_coords,roi_mask)
        % create hsize slider
        hsize_sld = uicontrol('Style', 'slider',...
            'Min',20,'Max',100,'Value',hsize,'pos',[10 10 200 20],...
            'SliderStep',[0.025 0.1],'Enable','on','Callback', @hsize_update);
        
        % display hsize value
        hsize_val = uicontrol('style','edit','Tag','SliderText',...
            'string',num2str(hsize),'pos',[60 30 100 20]);
        
        % add a label to the hsize slider
        h_txt = uicontrol('Style','text','String','hsize','pos',[60 50 100 20]);
        
        % begin tracking hsize slider value
        h_listen = addlistener(hsize_sld,'ContinuousValueChange',@hsize_update);
        
        % create sigma slider
        sigma_sld = uicontrol('Style', 'slider',...
            'Min',0.2,'Max',0.6,'Value',sigma,'pos',[220 10 200 20],...
            'Enable','on','Callback', @sigma_update);
        
        % display sigma value
        sigma_val = uicontrol('style','edit','Tag','SliderText',...
            'string',num2str(sigma),'pos',[270 30 100 20]);
        
        % add a label to the sigma slider
        s_txt = uicontrol('Style','text','String','sigma','pos',[270 50 100 20]);
        
        % begin tracking sigma slider value
        s_listen = addlistener(sigma_sld,'ContinuousValueChange',@sigma_update);
        
        % obtain hsize and sigma values from sliders
        %Previous Matlab version:
        %hsize = 2*round(h_listen.SourceObject.Value/2);
        %sigma = ceil(s_listen.SourceObject.Value*1000)/1000;
        hsize = 2*round(h_listen.Source{1}.Value/2);
        sigma = ceil(s_listen.Source{1}.Value*1000)/1000;
        
        % add a filter confirmation button
        LoG_button = uicontrol('Style', 'pushbutton', 'String', 'Save LoG filter',...
            'Position', [440 40 100 30],'Callback',@save_filt);
        
        % update plot
        LoG_update(hsize,sigma,my_img,crop_coords,roi_mask)
    end

%% Update UI with change to hsize slider value
    function hsize_update(hsize_sld,ignore)
        hTxt = findobj(gcf,'Tag','SliderText');
        set(hTxt(2),'String',num2str(2*round(get(hsize_sld,'Value')/2)))
        hsize = 2*round(get(hsize_sld,'Value')/2);
        
        % update plot
        LoG_update(hsize,sigma,my_img,crop_coords,roi_mask)
    end

%% Update UI with change to sigma slider value
    function sigma_update(sigma_sld,ignore)
        hTxt = findobj(gcf,'Tag','SliderText');
        set(hTxt(1),'String',num2str(ceil(get(sigma_sld,'Value')*1000)/1000))
        sigma = ceil(get(sigma_sld,'Value')*1000)/1000;
        
        % update plot
        LoG_update(hsize,sigma,my_img,crop_coords,roi_mask)
    end

%% Update plot with change to slider values
    function LoG_update(hsize,sigma,my_img,crop_coords,roi_mask)
        % LoG filter parameters
        my_LoG = fspecial('log',hsize,sigma); 
        my_filt = imfilter(my_img,my_LoG);
        my_filt = immultiply(my_filt,roi_mask);
        
        % crop image according to ROI boundaries
        my_filt = my_filt(crop_coords(1,1):crop_coords(1,2),crop_coords(2,1):crop_coords(2,2));
        
        % plot new image
        imshow(my_filt)
    end

%% Confirm filter parameters
    function save_filt(src,ignore)
        % end function and save filter parameters
        uiresume
    end

close force %close figure

end

