# TRACTUS
MATLAB functions for PCA-based dynamic ultrasound image analysis

TRACTUS_README.txt
Christopher Carignan, 2014

**********
TRACTUS (Temporally Resolved Articulatory Configuration Tracking of UltraSound; Carignan, 2014) is a suite of Matlab (Mathworks, 2014) functions designed to perform temporal analysis on ultrasound images without the need for tracing of tongue contours. Analysis is based on a principal component analysis (PCA) model which includes ultrasound frames as observations and pixel intensity values as dimensions. Through orthogonal transformation of the data, the PCA model identifies linearly uncorrelated variables (principal components, PCs) which account for the greatest amount of variance in the data. TRACTUS generates PC scores for each ultrasound frame, and orients PC loadings (i.e. correlation coefficients) onto their original spatial location, which are saved to the user-specified results directory as heatmaps which allow the user to visually examine the articulatory configurations associated with each PC. The PC scores which are saved to the results directory can be plotted and analyzed as temporal vectors which determine the extent to which each ultrasound frame is correlated with the given PC and associated heatmap. These scores and loadings can also be transformed via linear discriminant analysis, linear correlation, etc., with classes/priors based on any number of relevant categories (e.g., consonant place of articulation, front diagonal of the vowel space, etc.) in order to generate a temporal vector which is associated no longer with an individual PC, but with how the PCs are correlated with phonetically/phonologically relevant groups.

In order to use TRACTUS, the user must obtain licensing for the Matlab software and its toolboxes. Once Matlab is running, the user must add the directories for 'TRACTUS_prep.m', 'TRACTUS.m', and all of the additional functions to Matlab's search path. Once this step is completed, all of the functions which are necessary to run TRACTUS will be recognized by Matlab and available for use.

The first step is to run the 'TRACTUS_prep.m' function by typing 'TRACTUS_prep' into the Matlab Command Window and pressing the Enter key on the keyboard. This function is designed to run several analyzes in preparation for the TRACTUS analysis and save the results in a proprietary file, from which they will be retrieved and used automatically in the TRACTUS analysis. The user must simply carefully follow the onscreen instructions in order to use 'TRACTUS_prep.m'. TRACTUS can be used to analyze both individual ultrasound frame images and ultrasound video files. When used to analyze video files, TRACTUS will create a 'frames' subdirectory where the video file is kept, and save individual frame images as jpeg files to this subdirectory.

Once the user has completed the previous step, the next step is to run the 'TRACTUS.m' function simply by typing 'TRACTUS' into the Matlab Command Window and pressing Enter. The user will be directed to select the proprietary file which was created and saved by the 'TRACTUS_prep.m' function. The user must then carefully follow the onscreen instructions in order to perform the TRACTUS analysis. If the user prefers to run the TRACTUS analysis on only part of the images in the user-specified image folder (e.g., only images associated with speech) the user must supply a text file which contains a single column of logical values, with number of rows equal to the number of images in the image directory. For each row in the column, 1 denotes an image which is to be included in the analysis and 0 denotes an image which is not to be included. If no file list is supplied, all images in the directory will be used in the TRACTUS analysis.

Once the analysis has been completed, the following results files will be available in the user-specified results directory:

*_filenames.txt: Contains the file names for each image used in the analysis, in linear order.

*_misc.txt: A log which contains the values of several variables which were used in the analysis.

*_pc_heatmaps.txt: Contains the heatmaps for each PC retained in the analysis. These heatmaps can be viewed by using the 'pc_heatmap_plot.m' function in http://phon.chass.ncsu.edu/tractus/visualization. Please view the function for instructions on use.

*_pc_scores.txt: Contains PC scores for each ultrasound frame. Rows are PC scores for each frame, and columns 1 to n are the scores for n PCs used in analysis (determined by the user).

*_res_heatmaps.txt: Contains heatmaps constructed from the residuals of the PCA model.

*_var_explained.txt: Conatins a single column of combined percentages of variance explained by each PC, where row 1 is the percentage of variance explained by PC1, row 2 is the percentage of variance explained by PC1 + PC2, etc.

*_vecs.bmp: A bitmap image file which contains the vector matrix used in the PCA analysis. 

**********

References

Carignan, C. (2014). TRACTUS (Temporally Resolved Articulatory Configuration Tracking of UltraSound) software suite. URL: http://christophercarignan.github.io/TRACTUS/.

Mathworks (2014). MATLAB R2014a (Version 8.3). URL: http://www.mathworks.com/products/matlab/
