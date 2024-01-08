%% Simple UI for WFS:
%% Draw spot images
%% Draw search boxes. User can move (x,y) with mouse  (dbl click, click drag, or arrow keys)
%% When user hits 'space' compute centroids using simple center of mass
%% Return computed centroids and search box centers
 
function [centroids,searchBoxes,searchBoxes_pixel_coord,displacement_x,displacement_y,references_pixel_coord,center_pixel_coord]=...
    get_centroids(ccd_pixel,focal,pupilDiameter_um,searchBoxSize_um,...
    im,searchBoxes,references,center,automatic) 
%% Rename variables and calc based on parameters
pPupilRadius_um = pupilDiameter_um/2;
pInterLensletDistance_um = searchBoxSize_um;
ri_ratio = pPupilRadius_um/pInterLensletDistance_um;
search_box_size_pixels=searchBoxSize_um/ccd_pixel;

num_search_boxes = size(searchBoxes,1);
s=sprintf([ 'Move Main Window aside to see Magnifier Window behind.\n', ...
    'Move search boxes with arrows (hold CTRL for coarse), and mouse click+drag or mouse double click to set center\n',...
    'Click+drag inside of zoom window to move magnifier. Press "m" to cycle magnification and "z" to disable magnifier.\n',...
    'Press "a" to cycle alpha of boxes. Press "c" to toggle real-time centroid display, "r" real-time reference display.\n',...
    'Click "Space Bar" when ready to find centroids.\n']);
disp(s);

%%
% Zoom axis:
zoom_initial=[(size(im,2)/2-200/2) 1 100 100];
f_zoom=figure();
imshow(im(zoom_initial(2):zoom_initial(2)+zoom_initial(4),...
    zoom_initial(1):zoom_initial(1)+zoom_initial(3)),...
    "InitialMagnification",200);
%set(gca,'YDir','normal'); % reverse the image axis
axis on;
%hold on;
hold off;
ax2=gca;

% Then main axis
MainFig = figure(); %'MenuBar','none');
im = adapthisteq(im);
imshow(im)
axis on;
%set(gca,'YDir','normal'); % reverse the image axis
hold on;

radii = sqrt(searchBoxes(:,1).^2+searchBoxes(:,2).^2 );
im_ratio = ri_ratio * search_box_size_pixels; %size(im,1)/2.0;
im_size= size(im);

width=1/ri_ratio*im_ratio; % in pixels: unused?
height=1/ri_ratio*im_ratio; % in pixels: unused?

%% Initial center position:
if any(-1==center)
    cx=round(size(im,1)/2.0);
    cy=round(size(im,2)/2.0);
elseif any(-2==center)
    % Center of mass
    [XX,YY]=meshgrid(1:size(im,1),size(im,2):-1:1);
    sumX=sum(double(im(:)/max(im(:))).*XX(:));
    sumY=sum(double(im(:)/max(im(:))).*YY(:));
    totl=sum(im(:)/max(im(:)));
    cx=round(sumX/totl);
    cy=round(sumY/totl);
    cy=size(im,1)-cy; % Need to negate since ascending order
else
    cx=center(1);
    cy=center(2);
end
center_pixel_coord=[cx,cy]; % Initial

%% Information for the GUI
handles=guidata(gca);
handles.moving=0;
handles.done=0;
handles.abort=0; % Can skip centroid finding if desired.
handles.zooming=0;
handles.cx=cx;
handles.cy=cy;
handles.alpha=0.2;
handles.zoom=1.0;
handles.zoom_moving=0;
handles.im=im;
handles.plot_centroids=0;
handles.plot_refs=0;

handles.f_zoom=f_zoom;
handles.f_main=MainFig;
handles.ax1=gca;
handles.ax2=ax2;

figure(MainFig); % Not sure why necessary

zoom_rect=rectangle('Position',zoom_initial, 'EdgeColor', 'white');
handles.zoom_rect=zoom_rect;

guidata(gca,handles);

set(gcf, 'windowbuttondownfcn', {@myclick,1});
set(gcf, 'windowbuttonmotionfcn', {@myclick,2});
set(gcf, 'windowbuttonupfcn', {@myclick,3});
set(gcf, 'keypressfcn', {@myclick,4});

imsize_x=size(im,1);
imsize_y=size(im,2);

%% Main drawing loop
while (isempty(handles) || (handles.done==0) )

    handles=guidata(gca);
    if isempty(handles)
        figure(MainFig)
        handles=guidata(gca);
    end

    % Recompute searchbox and reference info each time based on center
    % For y, all pixel numbers are increasing from top to bottom (array order)
    searchBoxes_pixel_coord(:,1)=(   searchBoxes(:,1)*im_ratio) + handles.cx;
    searchBoxes_pixel_coord(:,2)=( -(searchBoxes(:,2)*im_ratio ) ) + handles.cy;
    upperleftx=round( searchBoxes_pixel_coord(:,1)-search_box_size_pixels/2.0 );
    upperlefty=round( searchBoxes_pixel_coord(:,2)-search_box_size_pixels/2.0 );

    center_pixel_coord=[handles.cx, handles.cy];
    center_offset=[imsize_x/2,imsize_y/2]-center_pixel_coord;
    
    % Offset the references by the chosen center
    references_pixel_coord(:,1)=  (references(:,1)*im_ratio ) + handles.cx;
    references_pixel_coord(:,2)= -(references(:,2)*im_ratio ) + handles.cy;

    totalVert=size(searchBoxes,1)*4;

    % Each corner of each rectangle gets an entry in these arrays
    allBox_XVert = reshape(repmat( upperleftx,[1 4])',1,[]); % Left
    allBox_XVert(3:4:totalVert)=allBox_XVert(1:4:totalVert)+round(width);
    allBox_XVert(4:4:totalVert)=allBox_XVert(1:4:totalVert)+round(width);
    allBox_YVert = reshape(repmat( upperlefty,[1 4])',1,[]); % Upper
    allBox_YVert(2:4:totalVert)=allBox_YVert(1:4:totalVert)+round(height);
    allBox_YVert(3:4:totalVert)=allBox_YVert(1:4:totalVert)+round(height);    
    faces=reshape(1:totalVert,[4 totalVert/4])';
    v=[allBox_XVert; allBox_YVert]';

    % Clear all old shapes
    delete(findobj('type', 'patch'));

    patch('Faces',faces,'Vertices',v,'EdgeColor','green','EdgeAlpha',handles.alpha,'FaceColor','none','LineWidth',1);

    if handles.plot_centroids
        centroids=find_centroids(num_search_boxes,im,upperleftx, upperlefty,im_ratio,handles,search_box_size_pixels,references);

        x_cen=centroids(:,1);
        y_cen=centroids(:,2);
        x_cen=[x_cen;NaN];
        y_cen=[y_cen;NaN]; % don't close polygon

        patch(x_cen,y_cen,'b','Marker','.','MarkerEdgeColor','b','MarkerSize',1); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
    end

    if handles.plot_refs
        x_ref=references_pixel_coord(:,1);
        y_ref=references_pixel_coord(:,2);
        x_ref=[x_ref;NaN];
        y_ref=[y_ref;NaN]; % don't close polygon

        patch(x_ref,y_ref,'r','Marker','.','MarkerEdgeColor','r','MarkerSize',1); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
    end

    if handles.zoom_rect.Visible
        pos=handles.zoom_rect.Position;
        xleft=pos(1);
        ytop=pos(2);

        % Clamp to screen area:
        if xleft<1
            xleft=1;
        end
        if ytop<1
            ytop=1;
        end
        if xleft+pos(3)>=size(im,1)
            xleft=size(im,1)-pos(3);
        end
        if (ytop+pos(4)>=size(im,2))
            ytop=size(im,2)-pos(4);
        end
        handles.mag_left=xleft;
        handles.mag_top=ytop;

        im_zoomed=im(ytop:ytop+pos(4),xleft:(xleft+pos(3)));
        imshow(im_zoomed, 'Parent', handles.ax2);
        xlim(handles.ax2, [0.5,pos(3)+0.5]);
        ylim(handles.ax2, [0.5,pos(3)+0.5]);

        % Display meaningful axes labels (pixel values offset by corner)
        scaler=pos(3);
        addMMx=@(x) sprintf('%d',(x+xleft));
        addMMy=@(y) sprintf('%d',(y+ytop));
        xticklabels(handles.ax2,cellfun(addMMx,num2cell(xticks(handles.ax2)'),'UniformOutput',false));
        yticklabels(handles.ax2,cellfun(addMMy,num2cell(yticks(handles.ax2)'),'UniformOutput',false));

        % All widgets are just offset by corner
        newv=[v(:,1)-xleft, v(:,2)-ytop];
        patch(handles.ax2,'Faces',faces,'Vertices',newv,'EdgeColor','green','EdgeAlpha',handles.alpha,'FaceColor','none','LineWidth',2);

        %figure(handles.f_main)
        if handles.plot_centroids
           patch(handles.ax2,x_cen-xleft,y_cen-ytop,'b','Marker','.','MarkerEdgeColor','b','MarkerSize',4); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
        end

        if handles.plot_refs
           patch(handles.ax2,x_ref-xleft,y_ref-ytop,'r','Marker','.','MarkerEdgeColor','r','MarkerSize',4); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
        end

    end

    drawnow;

    % If automatic mode, draw once, but then exit as if space was hit
    % immediately.
    if automatic
        handles.done=1;
    end
end 

if ~handles.abort

%% Find Centroids
hold on;

centroids=find_centroids(num_search_boxes,im,upperleftx, upperlefty,im_ratio,handles,search_box_size_pixels,references);

% Convert to displacements (based on references)
displacement_x=  references_pixel_coord(:,1)-centroids(:,1); % + 0.5; Possibly need to shift by 0.5 to make each pixel centered on its middle, rather than its corner
displacement_y=-(references_pixel_coord(:,2)-centroids(:,2)); %  + 0.5;

if 1 % Normal ref vs. centroid dots plot.
    plot(references_pixel_coord(:,1),references_pixel_coord(:,2),'.r');
    plot(centroids(:,1),centroids(:,2),'.b');

else % Quiver plot
    quiver(references_pixel_coord(:,1),references_pixel_coord(:,2), ...
        -displacement_x, displacement_y,0 ); % ,0=no automatic scaling
    % Negating is strange because the displacement value is relative to the
    % centroid (- means centroid is greater than reference)
end

%displacement_x=displacement_x-mean(displacement_x); % Must correct tip and tilt before Zernikes
%displacement_y=displacement_y-mean(displacement_y); % Must correct tip and tilt before Zernikes

else % User chose "abort"
    centroids=[];
    searchBoxes=[];
    searchBoxes_pixel_coord=[];
    displacement_x=[];
    displacement_y=[];
    references_pixel_coord=[];
    center_pixel_coord=[];
end

% Remove handlers when done.
clear_handlers();

end

%% Event handlers (mouse, arrows) for the figure
function myclick(h,event,type)

handles=guidata(gca);

if isempty(handles)
    return
end
  handles=guidata(gca);
if type==1 % Button down
    pos=get(gca,'CurrentPoint');
   
    switch get(h,'SelectionType')
    case 'normal'       
        xpos=round( pos(1,1) );%--store initial position x
        ypos=round( pos(1,2) );%--store initial position y

        if (xpos>handles.zoom_rect.Position(1)) && (xpos<= (handles.zoom_rect.Position(1)+handles.zoom_rect.Position(3))) && ...
            (ypos > handles.zoom_rect.Position(2)) && (ypos <= (handles.zoom_rect.Position(2)+handles.zoom_rect.Position(4) ))
            % Dragging mag window
            handles.zoom_moving=1;
        else
            handles.xpos0=xpos;%--store initial position x
            handles.ypos0=ypos;%--store initial position y
            handles.moving=1;
        end
    case 'open'
        handles.moving=0;
        handles.cx=round( pos(1,1) );
        handles.cy=round( pos(1,2) );
    end
end

if type==2 % Button motion
    pos=get(gca,'CurrentPoint');
    xpos=round(pos(1,1));
    ypos=round(pos(1,2));
    if handles.moving
       handles.cx=round( handles.cx - (handles.xpos0-xpos)/15.0 );
       handles.cy=round( handles.cy - (handles.ypos0-ypos)/15.0 );
    elseif handles.zoom_moving
        pos_current=get(handles.zoom_rect,'Position');
        handles.zoom_rect.Position=[xpos-pos_current(3)/2.0,...
            ypos-pos_current(4)/2.0,pos_current(3),pos_current(4)];
    end
end

if type==3 % Button up
    handles.moving=0;
    handles.zoom_moving=0;
end

if type==4 % keypress
    amount=1;
    if (size(event.Modifier,2)>0)
        if (strcmp(event.Modifier{1},'control') )
            amount=20;
        end
    end

    val = int16(get(gcf,'CurrentCharacter'));
    if size(val,1)>0
    switch val
        case 29
            handles.cx=handles.cx+amount;
        case 31
            handles.cy=handles.cy+amount;
        case 32
            handles.done=1;
        case 30
            handles.cy=handles.cy-amount;
        case 28
            handles.cx=handles.cx-amount;
        case 27 % escape
            handles.done=1;
            handles.abort=1;
        case 97 % 'a' cycle through alphas
            if handles.alpha==0.1
                handles.alpha=0.2;
            elseif handles.alpha==0.2
                handles.alpha=0.5;
            elseif handles.alpha==0.5
                handles.alpha=0.8;
            elseif handles.alpha==0.8
                handles.alpha=0.1;
            end
        case 109 % 'm': magnification
            current_mag=handles.zoom_rect.Position(3);
            if current_mag==200
                current_mag=50;
            elseif current_mag==50
                current_mag=100;
            elseif current_mag==100
                current_mag=200;
            end
            handles.zoom_rect.Position(3)=current_mag;
            handles.zoom_rect.Position(4)=current_mag;
        case 114 % r
            handles.plot_refs=~handles.plot_refs;
        case 99 % c
            handles.plot_centroids=~handles.plot_centroids;
        case 122 % 'z'
            handles.zoom_rect.Visible=~handles.zoom_rect.Visible;
        otherwise
            disp(['unknown key: ' num2str(val)]);
    end % switch on key
end
end % keypress event

% update display
delete(findobj('type', 'text'));
text(5,30,['x=' num2str(handles.cx) ' y= ' num2str(handles.cy)],'Color','green')

guidata(gca,handles);
end

function clear_handlers()
    set(gcf, 'keypressfcn', []);
    clear_mouse_handlers()
end

function clear_mouse_handlers()
    set(gcf, 'windowbuttondownfcn', []);
    set(gcf, 'windowbuttonmotionfcn', []);
    set(gcf, 'windowbuttonupfcn', []);
    set(gcf, 'keypressfcn', []);
end

%%
function centroids=find_centroids(num_search_boxes,im,upperleftx,upperlefty,im_ratio,handles,search_box_size_pixels,references)
centroids=zeros(num_search_boxes,2);

for i=1:num_search_boxes

    pixel_range_x=upperleftx(i):upperleftx(i)+round(search_box_size_pixels)-1;
    pixel_range_y=upperlefty(i):upperlefty(i)+round(search_box_size_pixels)-1;
    [search_box_x,search_box_y]=meshgrid(pixel_range_x,pixel_range_y); % indices for mass center

    % Extract pixels in each box, find center of mass
    search_pixels=im(pixel_range_y,pixel_range_x);
    search_pixels=search_pixels / max(search_pixels(:));
    total_mean=double(sum(search_pixels(:)));
    weighted_x=sum(double(search_pixels(:)).*search_box_x(:) );
    weighted_y=sum(double(search_pixels(:)).*search_box_y(:) );

%     disp( [ num2str(search_box_x(1,1)),' ', ...
%         num2str(search_box_y(1,1) ), ' ', ...
%         num2str(total),' ',num2str(a),' ',num2str(b),...
%         ' ',num2]);
   % s=sprintf('%d | %d %d | %d %d | %d %d | %d %d\n',...
   %        total_mean, search_box_x(1,1), search_box_y(1,1), a,b, search_box_x(a,b), search_box_y(a,b));
   % disp(s);

    centroid=[weighted_x/total_mean,weighted_y/total_mean];
    centroids(i,:)=[centroid(1) centroid(2)];
end
end
