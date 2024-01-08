function zoom_ui(MainFig,im,cones1, cones2, offsets, orgs1, orgs2,title1,title2)
% Zoom axis:
zoom_initial=[(size(im,2)/2-200/2) 1 100 100];
f_zoom=figure(10);
imshow(im(zoom_initial(2):zoom_initial(2)+zoom_initial(4),...
    zoom_initial(1):zoom_initial(1)+zoom_initial(3)),...
    "InitialMagnification",200);
%set(gca,'YDir','normal'); % reverse the image axis
axis on;
%hold on;
hold off;
ax_zoom=gca;

% Although designed to show two ORGs side-by-side for comparison, it can
% also be used just to show a single ORG. If so, COMPARING will be 0
COMPARING=(title1~=title2);

colors=rand([1 size(orgs1,2)+1 ]);
if COMPARING
    colors2=rand([1 size(orgs2,2)+1 ]);
else
    colors2=colors;
end

cmap_jet=jet(256);

f_orgs=figure(11);
if COMPARING
    subplot(1,2,1)
end
hold on;
org_lines1=[];
for ncurve=1:size(orgs1,2)
    color_index = ceil( 256 * colors(ncurve) );
    lin1=plot(orgs1(:,ncurve), 'Color', cmap_jet(color_index,:));
    org_lines1 = [org_lines1 lin1];
end
if COMPARING
    subplot(1,2,2)
    hold on;
    org_lines2=[];
    for ncurve=1:size(orgs2,2)
        color_index = ceil( 256 * colors2(ncurve) );
        linx=plot(orgs2(:,ncurve), 'Color', cmap_jet(color_index,:));
        org_lines2 = [org_lines2 linx];
    end
end
colormap('jet');
%hold off;
ax_org=gca;

MainFig = figure();
imagesc(im);
colormap('bone');
freezeColors();

%h_slider=uicontrol('style','slider','position',[1 5 200 20]);

zoom_initial=[(size(im,2)/2-200/2) 1 100 100];
handles=guidata(gca);

handles.moving=0;
handles.done=0;
handles.abort=0; % Can skip centroid finding if desired.
handles.zooming=0;
handles.cx=size(im,2)/2.0;
handles.cy=size(im,1)/2.0;
handles.alpha=0.2;
handles.zoom=1.0;
handles.zoom_moving=0;
handles.im=im;
handles.plot_centroids=0;
handles.plot_refs=0;
handles.mags=[10,20,30,75,100,200];

figure(MainFig); % Not sure why necessary

zoom_rect=rectangle('Position',zoom_initial, 'EdgeColor', 'white');
handles.zoom_rect=zoom_rect;

%handles.h_slider=h_slider;
handles.ax2=ax_zoom;
handles.ax_org=ax_org;

cones1_x=cones1.cone_mat_all(:,1)+cones1.ROI(1);
cones1_y=cones1.cone_mat_all(:,2)+cones1.ROI(2);
cones1_x=[cones1_x;NaN];
cones1_y=[cones1_y;NaN]; % don't close polygon

cones=patch(cones1_x,cones1_y,colors,'Marker','.','MarkerEdgeColor', 'flat', 'EdgeColor','none','MarkerSize',1.5); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
colormap('jet');     
handles.cones=cones;

cones2_x=cones2.cone_mat_all(:,1)+cones2.ROI(1)+offsets(1);
cones2_y=cones2.cone_mat_all(:,2)+cones2.ROI(2)+offsets(2);
cones2_x=[cones2_x;NaN];
cones2_y=[cones2_y;NaN]; % don't close polygon

cones2=patch(cones2_x,cones2_y,colors2,'Marker','x','MarkerEdgeColor', 'flat', 'EdgeColor','none','MarkerSize',1.5); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
colormap('jet');     
handles.cones2=cones2;

handles.org_lines1=org_lines1;
if COMPARING
    handles.org_lines2=org_lines2;
else
    handles.org_lines2=org_lines1; % Dummy
end

guidata(gca,handles);

set(gcf, 'windowbuttondownfcn', {@myclick,1});
set(gcf, 'windowbuttonmotionfcn', {@myclick,2});
set(gcf, 'windowbuttonupfcn', {@myclick,3});
set(gcf, 'keypressfcn', {@myclick,4});


    %% Main drawing loop
    while (isempty(handles) || (handles.done==0) )
    
        handles=guidata(gca);
        if isempty(handles)
            figure(MainFig)
            handles=guidata(gca);
            continue;
        end

        % Clear all old shapes
%        delete(findobj('type', 'patch'));
      %  disp(handles);
       

        if 1 %handles.zoom_rect.Visible
            pos=handles.zoom_rect.Position;
            xleft=pos(1);
            ytop=pos(2);
            width=pos(3);
            height=pos(4);

            % Clamp to screen area:
            if xleft<1
                xleft=1;
            end
            if ytop<1
                ytop=1;
            end
            if xleft+pos(3)>=size(im,2)
                xleft=size(im,2)-pos(3);
            end
            if (ytop+pos(4)>=size(im,1))
                ytop=size(im,1)-pos(4);
            end
            handles.mag_left=xleft;
            handles.mag_top=ytop;
    
            im_zoomed=im(ytop:ytop+pos(4),xleft:(xleft+pos(3)));
            imagesc(im_zoomed, 'Parent', handles.ax2);
            colormap(handles.ax2,'bone');
            freezeColors(handles.ax2); % Keep b*w

            xlim(handles.ax2, [0.5,pos(3)+0.5]);
            ylim(handles.ax2, [0.5,pos(3)+0.5]);
    
            % Display meaningful axes labels (pixel values offset by corner)
            scaler=pos(3);
            addMMx=@(x) sprintf('%d',(x+xleft));
            addMMy=@(y) sprintf('%d',(y+ytop));
            xticklabels(handles.ax2,cellfun(addMMx,num2cell(xticks(handles.ax2)'),'UniformOutput',false));
            yticklabels(handles.ax2,cellfun(addMMy,num2cell(yticks(handles.ax2)'),'UniformOutput',false));
    
            % All widgets are just offset by corner
            %newv=[v(:,1)-xleft, v(:,2)-ytop];
            %patch(handles.ax2,'Faces',faces,'Vertices',newv,'EdgeColor','green','EdgeAlpha',handles.alpha,'FaceColor','none','LineWidth',2);
        colormap(handles.ax2,'jet');     
        cones1_zoom=patch(handles.ax2,cones1_x-xleft,cones1_y-ytop,colors,handles.cones.CData,'Marker','.','MarkerEdgeColor', 'flat', 'EdgeColor','none','MarkerSize',4); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
        cones1_zoom.Visible=handles.cones.Visible;
        %hold on;
        
        cones2_zoom=patch(handles.ax2,cones2_x-xleft,cones2_y-ytop,colors2,handles.cones2.CData,'Marker','x','MarkerEdgeColor', 'flat', 'EdgeColor','none','MarkerSize',3); %'EdgeColor','None','Marker','.','MarkerFaceColor','b');
        colormap(handles.ax2,'jet');   
        if COMPARING
            cones2_zoom.Visible=handles.cones2.Visible;
        else
            cones2_zoom.Visible=handles.cones2.Visible*0;
        end
        %hold off;

        end

        in1=all ([cones1_x > xleft,cones1_x<xleft+width,...
            cones1_y>ytop,cones1_y<ytop+height], 2);

        for ncurve=1:size(orgs1,2)
            handles.org_lines1(ncurve).Visible=in1(ncurve);
        end

        in2=all ([cones2_x > xleft,cones2_x<xleft+width,...
            cones2_y>ytop,cones2_y<ytop+height], 2);

        for ncurve=1:size(orgs2,2)
            handles.org_lines2(ncurve).Visible=in2(ncurve);
        end

        titl=sprintf('%s:%d (dots), %s:%d (xs)',title1,sum(in1),title2,sum(in2) );
        title(titl);

        drawnow;
        pause(0.05);
    end

    close all;
end

%% Event handlers (mouse, arrows) for the figure
function myclick(h,event,type)

handles=guidata(gca);

if isempty(handles)
    return
end
  
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

            idx_curr=find(current_mag==handles.mags);
            if idx_curr==size(handles.mags,2) % Clamp so end loops around
                idx_curr=0;
            end
            current_mag=handles.mags(idx_curr+1);
            handles.zoom_rect.Position(3)=current_mag;
            handles.zoom_rect.Position(4)=current_mag;
        case 114 % r
            colors=rand([1 size(handles.cones.CData,1) ]);
            handles.cones.CData=colors;
            %handles.cones.FaceVertexCData=colors;
        case 99 % c
            handles.cones.Visible = ~handles.cones.Visible;
            handles.plot_centroids=~handles.plot_centroids;
        case 122 % 'z'
            handles.zoom_rect.Visible=~handles.zoom_rect.Visible;
        case 49 % 1
            handles.cones.Visible=~handles.cones.Visible;
        case 50 % 2
            handles.cones2.Visible=~handles.cones2.Visible;
        otherwise
            disp(['unknown key: ' num2str(val)]);
    end % switch on key
end
end % keypress event

% update display
%delete(findobj('type', 'text'));
%text(5,30,['x=' num2str(handles.cx) ' y= ' num2str(handles.cy)],'Color','green')

guidata(gca,handles);
end
