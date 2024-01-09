%dir1='F:\3d_registration\results\Results_flat_ram_sup1.5_30_32_32_4\ICA_cmplxavg_2px_selected_v2\'
dir1='./';
dir2=dir1;
name1='seg-based';
name2=name1;
%cone_filename='Cone_selection.mat';
%org_filename='Phase_unwrap_error_corrected.mat';
cone_filename='registered_averaged_isos_03.tiff';
%org_filename='Phase_unwrap_error_corrected.mat';
org_filename='whole_ORG_en_face_03.mat';

global PIXELS_NOT_CONES;
PIXELS_NOT_CONES=1;
COMPARE=0; % Show two different ORGs side-by-side?

if PIXELS_NOT_CONES
    fixed=imread([dir1 cone_filename]);
    %fixed=imrotate(fixed,90);
    moving = fixed; % only 1 file
    org_file1 = load([dir1 org_filename]);
    org_file2 = org_file1;

    orgs1=org_file1.ISOS_COST_del_phi_adjacent_A_scans_2D2;
    orgs1 = angle(reshape(orgs1,[size(orgs1,1)*size(orgs1,2),size(orgs1,3)] ) );
    orgs1 = orgs1';
    orgs2 = orgs1;    

    image_size = size(org_file1.ISOS_COST_del_phi_adjacent_A_scans_2D2, [1 2]);

    % Make matrix that has x,y coords of each pixel as a row
    rows = 1:image_size(2);
    cols = 1:image_size(1);
    [X,Y] = meshgrid(rows,cols);
    coords = [X(:),Y(:)];
    cones1 = coords;
    cones2 = coords;
else
    % First version took everything from MAT files created by Vimal's ORG
    % code
    cones1=load([dir1 cone_filename]);
    cones2=load([dir2 cone_filename]);
    org_file1=load([dir1 org_filename]);
    org_file2=load([dir2 org_filename]);

    fixed=cones1.avg_MIP_image_COST;
    moving=cones2.avg_MIP_image_COST;

    orgs1=org_file1.phaseangle_IC_cleanup_unwrapcorrected_13;
    orgs2=org_file2.phaseangle_IC_cleanup_unwrapcorrected_13;
end

%if COMPARE % TODO: pull out
%else

% There were some NaNs in the images
fixed(isnan(fixed))=0;
moving(isnan(moving))=0;

[optimizer,metric] = imregconfig("multimodal");
% FROM HELP:
 % Tune the properties of the optimizer to get the problem to converge
    % on a global maxima and to allow for more iterations.
optimizer.InitialRadius = 0.005;
optimizer.Epsilon = 1.5e-4;
optimizer.GrowthFactor = 1.01;
optimizer.MaximumIterations = 300;

tform=imregtform(moving,fixed, 'translation', optimizer,metric);
tform.T

%%
Rmoving = imref2d(size(moving));
Rfixed = imref2d(size(fixed));

 % Transform the moving image using the transform estimate from imregtform.
 % Use the 'OutputView' option to preserve the world limits and the
 % resolution of the fixed image when resampling the moving image.
 [movingReg,Rreg] = imwarp(moving,Rmoving,tform,'OutputView',Rfixed, 'SmoothEdges', false);
 imshowpair(movingReg, fixed )

%%
pad=[100 100];
fixed_padded=padarray(fixed,pad, 'both');
moving_padded=fixed_padded*0;
sz=size(moving);
offsets=tform.T(3,1:2)'+pad;
offsets1=tform.T(3,1:2);
if offsets(2)>0
    moving_padded(offsets(2):offsets(2)+sz(1)-1,offsets(1):offsets(1)+sz(2)-1)=moving;
else
    moving_padded(offsets(1):offsets(1)+sz(2)-1,offsets(2):offsets(2)+sz(1)-1)=moving;
end
f=figure;
imshowpair(moving_padded,fixed_padded);
title('Fixed (#1) is centered (purple)')
%%
close all;  

zoom_ui([],fixed, cones1, cones2, offsets1,orgs1,orgs2,name1,name2);
%imagesc(fixed_padded);
