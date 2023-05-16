function [views,viewpos,origins,scales,xcol,ycol,xsign,ysign,XY,hgridlinesx,hgridlinesy,vgridlinesx,vgridlinesy,viewimages]=get_tal_params(layoutnum);
% [views,viewpos,origins,scales,xcol,ycol,xsign,ysign,XY,hgridlinesx,hgridlinesy,vgridlinesx,vgridlinesy,viewimages]=get_tal_params(layoutnum);
if(nargin<1) layoutnum=0; end;

% The standardised Talairach constants
Tal_inf_sup=75; % mm
Tal_sup=Tal_inf_sup; Tal_inf=Tal_inf_sup/(1.7);
Tal_ant=70; % mm
Tal_post=103; % mm
Tal_axial_half=61; % mm

TP=get_tal_par;

% ***** Here is where everything is set up for the views *****

views={'inf','lsag','rsag','interlsag','interrsag','hipp'};
% Note: The origins for the interhemispherics are opposite to the L/R
% lateral sagittals, because the views flips when looking fromm the
% inside-out
origins={TP.inf_trace_AC,TP.L_sag_trace_AC,TP.R_sag_trace_AC,TP.R_sag_trace_AC,TP.L_sag_trace_AC,TP.inf_trace_AC};
% scales in pixels/mm:
scales=[TP.inf_trace_scale,TP.sag_trace_scale,TP.sag_trace_scale,...
	TP.sag_trace_scale,TP.sag_trace_scale TP.inf_trace_scale]/10;
xcol=[2 3 3 3 3 2]; % which column contains the x values
ycol=[3 4 4 4 4 3]; % which column contains the y values
xsign=[-1 -1 +1 +1 -1 -1]; % whether or not this coord. needs to be negated
ysign=[+1 +1 +1 +1 +1 +1]; % whether or not this coord. needs to be negated


switch(layoutnum)
 % the old talmaphorizontal style
 case 0, viewpos={[0 135],[750 250],[-900 250],[0 0 ],[0 0],[-9999 -9999]};
 % the old three-view style from the Nature paper
 case 1, viewpos={[-200 135],[150 1000],[-730 1000],[0 0],[0 0],[-9999 -9999]};
 % horizontal, including the interhemispherics
 case 2, viewpos={[0 0],[800 500],[-1000 500],[800 -300],[-1000 -300],[-9999 -9999]};
 % six views. It's like layout 2, but with the hippocampal view as well
 case 3, viewpos={[0 500],[800 500],[-1000 500],[800 -300],[-1000 -300],[0 -500]};
 % four views: lsag, rsag, inf and hipp, in a square arrangement
 case 4, viewpos={[-330 -450],[400 440],[-550 440],[0 0],[0 0],[370 -450]};
end % switch(layoutnum)

for V=1:length(views)
  XY{V}=origins{V}+viewpos{V};
end
viewimages={'inf_view','L_sag_view','R_sag_view','L_sag_inter_view','R_sag_inter_view','hipp_view'};

glspc=20; % mm spacing between gridlines

vgridlinesx={[XY{1}(1)-scales(1)*Tal_axial_half ...
	      XY{1}(1)+scales(1)*(-(10*floor(Tal_axial_half/10))+...
		    glspc:+glspc:+Tal_axial_half)]   , ...
	     ...
	     [XY{2}(1)-scales(2)*Tal_ant ...
	      XY{2}(1)+scales(2)*...
	      ((glspc*ceil(Tal_post/glspc)-glspc:-glspc:-Tal_ant))]   , ...
	     ...
	     [XY{3}(1)+scales(3)*...
	      (-(glspc*ceil(Tal_post/glspc))+glspc:+glspc:Tal_ant) ...
	      XY{3}(1)+scales(3)*Tal_ant]   , ...
	     ...
	     [XY{4}(1)+scales(4)*...
	      (-(glspc*ceil(Tal_post/glspc))+glspc:+glspc:Tal_ant) ...
	      XY{4}(1)+scales(4)*Tal_ant] ...
	     ...
	     [XY{5}(1)-scales(5)*Tal_ant ...
	      XY{5}(1)+scales(5)*...
	      ((glspc*ceil(Tal_post/glspc)-glspc:-glspc:-Tal_ant))]   , ...
	     ...
	     [XY{6}(1)-scales(1)*Tal_axial_half ...
	      XY{6}(1)+scales(1)*(-(10*floor(Tal_axial_half/10))+...
		    glspc:+glspc:+Tal_axial_half)]
	    };
vgridlinesy={[XY{1}(2)+scales(1)*(-glspc*floor(Tal_post/glspc)) ...
	      XY{1}(2)+scales(1)*Tal_ant]   , ...
	     ...
	     [XY{2}(2)+scales(2)*(-glspc*floor(Tal_inf/20)) ...
	      XY{2}(2)+scales(2)*Tal_sup]   , ...
	     ...
	     [XY{3}(2)+scales(3)*(-glspc*floor(Tal_inf/20)) ...
	      XY{3}(2)+scales(3)*Tal_sup]   , ...
	     ...
	     [XY{4}(2)+scales(4)*(-glspc*floor(Tal_inf/20)) ...
	      XY{4}(2)+scales(4)*Tal_sup] ...
	     ...
	     [XY{5}(2)+scales(5)*(-glspc*floor(Tal_inf/20)) ...
	      XY{5}(2)+scales(5)*Tal_sup]   , ...
	     ...
	     [XY{6}(2)+scales(1)*(-glspc*floor(Tal_post/glspc)) ...
	      XY{6}(2)+scales(1)*Tal_ant]
	    };

hgridlinesx={[XY{1}(1)+scales(1)*10*floor(Tal_axial_half/10) ...
	      XY{1}(1)-scales(1)*Tal_axial_half]   , ...
	     ...
	     [XY{2}(1)+scales(2)*glspc*floor(Tal_post/glspc) ...
	     XY{2}(1)-scales(2)*Tal_ant],   ...
	     ...
	     [XY{3}(1)+scales(3)*Tal_ant ...
	      XY{3}(1)-scales(3)*glspc*floor(Tal_post/glspc)]   , ...
	     ...
	     [XY{4}(1)+scales(4)*Tal_ant ...
	      XY{4}(1)-scales(4)*glspc*floor(Tal_post/glspc)] ...
	     ...
	     [XY{5}(1)+scales(5)*glspc*floor(Tal_post/glspc) ...
	     XY{5}(1)-scales(5)*Tal_ant],   ...
	     ...
	     [XY{6}(1)+scales(1)*10*floor(Tal_axial_half/10) ...
	      XY{6}(1)-scales(1)*Tal_axial_half]
	    };
hgridlinesy={[XY{1}(2)+scales(1)*(-glspc*floor(Tal_post/glspc):glspc:Tal_ant) ...
	      XY{1}(2)+scales(1)*Tal_ant]   , ...
	     ...
	     [XY{2}(2)+scales(2)*(-glspc*floor(Tal_inf/glspc):glspc:Tal_sup) ...
	      XY{2}(2)+scales(2)*Tal_sup],   ...
	     ...
	     [XY{3}(2)+scales(3)*(-glspc*floor(Tal_inf/glspc):glspc:Tal_sup) ...
	       XY{3}(2)+scales(3)*Tal_sup]   , ...
	     ...
	     [XY{4}(2)+scales(4)*(-glspc*floor(Tal_inf/glspc):glspc:Tal_sup) ...
	       XY{4}(2)+scales(4)*Tal_sup] ...
	     ...
	     [XY{5}(2)+scales(5)*(-glspc*floor(Tal_inf/glspc):glspc:Tal_sup) ...
	      XY{5}(2)+scales(5)*Tal_sup],   ...
	     ...
	     [XY{6}(2)+scales(1)*(-glspc*floor(Tal_post/glspc):glspc:Tal_ant) ...
	      XY{6}(2)+scales(1)*Tal_ant]
	    };
