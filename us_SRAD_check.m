function [ niter, lambda, rect ] = us_SRAD_check( my_img, crop_coords, roi_mask )
% Created by Christopher Carignan, 2015
% Contact: carignanc@gmail.com, www.christophercarignan.com

% us_SRAD_check.m version 1.2 (09/16/2015):
% Updated Java syntax to be compatible with Matlab R2015

% default filter values
niter = 6;
lambda = 0.5;
rect = [round(size(my_img,2)/2) round(size(my_img,2)/2)...
    round(size(my_img,2)/15) round(size(my_img,1)/15)];

% create figure for plotting
fig = figure;
set(gcf,'NumberTitle','off');
title('SRAD filtering results')
hold on

% call main plotting function
SRAD_plotter(niter,lambda,rect,my_img,crop_coords,roi_mask)

% hold function until user saves filter parameters @save_filt
uiwait

%% Main plotting function
    function SRAD_plotter(niter,lambda,rect,my_img,crop_coords,roi_mask)
        % create niter slider
        niter_sld = uicontrol('Style', 'slider',...
            'Min',0,'Max',12,'Value',niter,'pos',[10 10 200 20],...
            'Enable','on','Callback', @niter_update);
        
        % display niter value
        niter_val = uicontrol('style','edit','Tag','SliderText',...
            'string',num2str(niter),'pos',[60 30 100 20]);
        
        % add a label to the niter slider
        n_txt = uicontrol('Style','text','String','# of iterations','pos',[60 50 100 20]);
        
        % begin tracking hsize slider value
        n_listen = addlistener(niter_sld,'ContinuousValueChange',@niter_update);
        
        % create lambda slider
        lambda_sld = uicontrol('Style', 'slider',...
            'Min',0.1,'Max',1,'Value',lambda,'pos',[220 10 200 20],...
            'Enable','on','Callback', @lambda_update);
        
        % display lambda value
        lambda_val = uicontrol('style','edit','Tag','SliderText',...
            'string',num2str(lambda),'pos',[270 30 100 20]);
        
        % add a label to the sigma slider
        l_txt = uicontrol('Style','text','String','lambda','pos',[270 50 100 20]);
        
        % begin tracking sigma slider value
        l_listen = addlistener(lambda_sld,'ContinuousValueChange',@lambda_update);
        
        % add a filter confirmation button
        LoG_button = uicontrol('Style', 'pushbutton', 'String', 'Save SRAD filter',...
            'Position', [440 40 100 30],'Callback',@save_filt);
        
        % obtain hsize and sigma values from sliders
        %Previous Matlab version:
        %niter = round(n_listen.SourceObject.Value); 
        %lambda = ceil(l_listen.SourceObject.Value*100)/100;
        niter = round(n_listen.Source{1}.Value); 
        lambda = ceil(l_listen.Source{1}.Value*100)/100;
        
        % update plot
        SRAD_update(niter,lambda,rect,my_img,crop_coords,roi_mask)
    end

%% Update UI with change to niter slider value
    function niter_update(niter_sld,ignore)
        hTxt = findobj(gcf,'Tag','SliderText');
        set(hTxt(2),'String',num2str(round(get(niter_sld,'Value'))))
        niter = round(get(niter_sld,'Value'));
        
        % update plot
        SRAD_update(niter,lambda,rect,my_img,crop_coords,roi_mask)
    end

%% Update UI with change to lambda slider value
    function lambda_update(lambda_sld,ignore)
        hTxt = findobj(gcf,'Tag','SliderText');
        set(hTxt(1),'String',num2str(ceil(get(lambda_sld,'Value')*100)/100))
        lambda = ceil(get(lambda_sld,'Value')*100)/100;
        
        % update plot
        SRAD_update(niter,lambda,rect,my_img,crop_coords,roi_mask)
    end

%% Update plot with change to slider values
    function SRAD_update(niter,lambda,rect,my_img,crop_coords,roi_mask)
        % SRAD filter parameters
        my_filt = SRAD(my_img, niter, lambda, rect);
        
        % median filter
        my_img = medfilt2(my_img, [round(size(my_img,1)/50) round(size(my_img,2)/50)]);
        
        % apply ROI mask
        my_filt = immultiply(my_filt, roi_mask);
        
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
