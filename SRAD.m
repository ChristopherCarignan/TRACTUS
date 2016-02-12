function [J,rect] = SRAD(I,niter,lambda,rect)

%SRAD speckle reducing anisotropic diffusion.
%   Y. Yu and S.T. Acton, "Speckle reducing anisotropic diffusion," IEEE
%   Transactions on Image Processing, vol. 11, pp. 1260-1270, 2002.
%   <http://viva.ee.virginia.edu/publications/j_srad.pdf>
%
%INPUTS
%   I...........log compressed input image
%   niter.......number of iterations
%   lambda......smoothing time step
%   rect........homogeneous ROI [x y width height]
%
%DEFAULT INPUTS
%   rect........user specified at run-time
%
%OUTPUT
%   J...........log compressed output image
%   rect........homogeneous ROI [x y width height]
%
%USAGE
%
%   J = SRAD(I,NITER,LAMBDA) performs SRAD on the log compressed image I 
%   using NITER iterations and a timestep LAMBDA.  A large number of 
%   iterations produces more smoothing, while a large timestep produces 
%   faster smoothing.  Too small an NITER or too large a LAMBDA are not
%   recommended.
%
%   J = SRAD(...,RECT) uses the user specified rectangle RECT to define 
%   the region of uniform speckle.  RECT is specfied as in IMCROP or
%   GETRECT as [x y width height].
%
%   [J,rect] = SRAD(...) returns the rectangle RECT to the command line. 
%   RECT is specfied as in IMCROP or  GETRECT as [x y width height].

%WRITTEN BY:  Drew Gilliam
%
%MODIFICATION HISTORY:
%   2005      Drew Gilliam
%       --creation
%       --modified original Yu MATLAB code - faster/user friendly 
%   2006.02   Alla Aksel
%       --Added comments
%   2006.03   Drew Gilliam
%       --Changed header comments
%       --re-wrote Rob Janiczek c-code, added to SRAD function
%         new c-code version is 2x as fast as MATLAB version
%   2006.04   Drew Gilliam
%       --added diffusion coefficent saturation on [0,1]

% global FLAG_SRAD_CCODE FLAG_SRAD_WAIT
FLAG_SRAD_CCODE = 0;     % 1 = use c-code
FLAG_SRAD_WAIT  = 0;     % 1 = display wait bar

%==========================================================================
% SETUP
%==========================================================================

% check number of inputs
error(nargchk(3,4,nargin))

% area of uniform speckle
if nargin < 4 || isempty(rect)
  imshow(I,[],'notruesize');
  rect = getrect;
end

% make image a double and normalize on [0,1]
I = double(I);
mx = max(I(:));
mn = min(I(:));
I = (I-mn)/(mx-mn);

% image size
[M,N] = size(I);



%==========================================================================
% C-CODE
%==========================================================================
if FLAG_SRAD_CCODE
    % get row/col of rect
    r = [floor(rect(2)), ceil(rect(2)+rect(4))];
    c = [floor(rect(1)), ceil(rect(1)+rect(3))];

    % saturate row/col
    rsat = r<1 | M<r;
    r = (~rsat.*r) + (rsat.*[1 M]);

    csat = c<1 | N<c;
    c = (~csat.*c) + (csat.*[1 N]);

    % SRAD c-code
    J = SRAD_c(single(I),niter,lambda,...
        r(1),r(2),c(1),c(2),FLAG_SRAD_WAIT);
    J = double(J);

    
%==========================================================================
% MATLAB
%==========================================================================    
else

    % image indices (using boudary conditions)
    iN = [1, 1:M-1];
    iS = [2:M, M];
    jW = [1, 1:N-1];
    jE = [2:N, N];

    % log uncompress (also eliminates zero value pixels)
    I = exp(I);

    % wait bar
    if FLAG_SRAD_WAIT, 
        hwait = waitbar(0,'SRAD: Diffusing Image');
    end
    
    
    % main algorithm
    for iter = 1:niter

        % speckle scale function
        Iuniform = imcrop(I,rect);
        q0_squared = var(Iuniform(:)) / (mean(Iuniform(:))^2);

        % differences
        dN = I(iN,:) - I;
        dS = I(iS,:) - I;
        dW = I(:,jW) - I;
        dE = I(:,jE) - I;

        % normalized discrete gradient magnitude squared (equ 52,53)
        G2 = (dN.^2 + dS.^2 + dW.^2 + dE.^2) ./ I.^2;

        % normalized discrete laplacian (equ 54)
        L = (dN + dS + dW + dE) ./ I;

        % ICOV (equ 31/35)
        num = (.5*G2) - ((1/16)*(L.^2));
        den = (1 + ((1/4)*L)).^2;
        q_squared = num ./ (den + eps);

        % diffusion coefficent (equ 33)
        den = (q_squared - q0_squared) ./ (q0_squared *(1 + q0_squared) + eps);
        c = 1 ./ (1 + den);
        
        % saturate diffusion coefficent
        c(c<0) = 0;
        c(c>1) = 1;

        % divergence (equ 58)
        cS = c(iS, :);
        cE = c(:,jE);
        D = (c.*dN) + (cS.*dS) + (c.*dW) + (cE.*dE);

        % update (equ 61)
        I = I + (lambda/4)*D;

        % update waitbar
        if FLAG_SRAD_WAIT, waitbar(iter/niter,hwait); end

        % display
    %     if ~mod(iter,10)
    %         figure(1)
    %         imshow(I,[],'notruesize')
    %         title(sprintf('Iteration %d',iter));
    %         drawnow
    %     end

    end

    % log compression & output
    J = log(I);

    % close wait bar
    if FLAG_SRAD_WAIT, close(hwait); end

end    
    
return



%**************************************************************************
% END OF FILE
%**************************************************************************
