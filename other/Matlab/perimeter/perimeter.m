       
function result=perimeter(long,lat,uf,vf,dzdxf,dzdyf,time_now,bound)

% Description of the function

% This function creates the initial matrix of times of ignitions
% given the perimeter and tign at the points of the perimeter and
% is using Wind variable in its calculations
%
%--------------------------------------------------------------------%
% Algorythm
%--------------------------------------------------------------------%
% 1) mark the points that are on the perimeter on the flag matrix
% 2) Go over the points and check if any of 9 around is =0
% 3) If yes, calculate


%  Comments for myself

% 1 ---This function works if the original perimeter is defined on the grid
% points;
% 2) So far I will do the loop until all the flags would be marked
% 2a) Think how to go over only unmarked flags (create a matrix of indexes and updated every time)
%
% 3) So far the coordinates of the matrix are integer indexes, later
% coefficients of the matrix
% 
% 3a) Think what to do if the points of the boundary don't lie on the grid
%
% 4) Will the tign of the points inside be less than the perimeter points
%
% 5) Updating everything but the boundary points
%
% 6) Why max and not a sum over points with weight
%
% 7) if my update (March 8) is correct than we dont set it to inf but just keep the previous tign
% tign(IN()>0)=inf, <0 = 0 thats for the initialization 
% then tign=min(tign, inf) ot max(0,tign)
% 
% 8) When R=0, and it is obstacle

% Tasks

% 1) Correct my writing of the code
% 2) Do the boundary
% 3) Fedir&Oshkiv the case when the points of the perimeter are not on the
%    mesh
% 4) Rewrite the code for longtitude and latitude and add their reading
% 5) Write the function that reads R as a separate function
% 6) reshape to long and lat

% Reading the data

addpath('../../other/Matlab/util1_jan');
addpath('../../other/Matlab/netcdf');

fuels % Needed to create fuel variable

format long
result=1;

bnd_size=size(bound);
n=size(long,1);
m=size(long,2);

tign=zeros(n,m);      % "time of ignition matrix" of the nodes 
A=zeros(n,m);         % A=1 where time of ignition was updated at least once 

data_steps='';
%  IN - matrix, that shows, whether the point is inside (IN(x,y)>0) the burning region
%  or outside (IN(x,y)<0)
%  ON - matrix that, shows whether the point is on the boundary or not
%  Both matrices evaluated using "polygon", coefficients are multiplied by
%  10^6, because the function looses acuracy when it deals with decimals
xv=bound(:,1);
yv=bound(:,2);
xv=xv*100000;
yv=yv*100000;
lat1=lat*100000;
long1=long*100000;
[IN,ON] = inpolygon(long1,lat1,xv,yv);

[ichap,bbb,phiwc,betafl,r_0]=fire_ros_new(fuel);

% Code

% First step, we set everything inside to time_now and update the points
% outside

% Initializing flag matrix A and time of ignition (tign)
% Extending the boundaries, in order to speed up the algorythm
A=zeros(n+2,m+2);
tign=zeros(n+2,m+2);
A(2:n+1,2:m+1)=IN(:,:,1);
tign(2:n+1,2:m+1)=IN(:,:,1)*time_now;

% Stop when the matrix converges
changed=1;
changed_old=2;
for istep=1:max(size(tign)),
    if changed==0, 
        % Writing the data to the file data_out.txt
        data_steps=sprintf('%s\n%s',data_steps,'first part done');
        fid = fopen('output_tign_outside.txt', 'w');
        dlmwrite('output_tign_outside.txt', tign(2:n+1,2:m+1), 'delimiter', '\t','precision', '%.4f');
        fclose(fid);
        'first part done'
        break
    elseif (changed_old==changed)
    fid = fopen('no_fixed_point_outside.txt', 'w'); 
    dlmwrite('no_fixed_point_outside.txt', tign(2:n+1,2:m+1), 'delimiter', '\t','precision', '%.4f');
    fclose(fid);
    data_steps=sprintf('%s\n%s',data_steps,'no_fixed_point_outside');
    end
        
    
tign_last=tign;

% tign_update - updates the tign of the points
[tign,A]=tign_update(long,lat,vf,uf,dzdxf,dzdyf,fuel,tign,A,IN,time_now,ichap,bbb,phiwc,betafl,r_0);

changed=sum(tign(:)~=tign_last(:));
data_steps=sprintf('%s\n step %i outside tign changed at %i points',data_steps,istep,changed);

fid = fopen('data_out_steps.txt', 'w');
fprintf(fid,'%s',data_steps); % It has two rows now.
fclose(fid);
% figure(1),mesh(tign_last(2:n+1,2:m+1)),title(['tign last (outside), step',int2str(istep)])
% figure(2),mesh(tign-tign_last),title(['Difference (outside), step',int2str(istep)])
% figure(3),mesh(tign(2:n+1,2:m+1)),title(['tign new (outside), step',int2str(istep)])
% 
% drawnow

end

if changed~=0,
   data_steps=sprintf('%s\n%s',data_steps,'did not find fixed point outside');
    warning('did not find fixed point')
end
% Second step, we keep the values of the points outside and update the
% points inside

% Initializing flag matrix A and time of ignition (tign)
A(2:n+1,2:m+1)=1-IN(:,:,1);
final_tign=tign;
tign_in=zeros(n+2,m+2);
tign_in(2:n+1,2:m+1)=(1-IN(:,:,1)).*time_now;

changed=1;
for istep=1:max(size(tign)),
    if changed==0, 
    fid = fopen('output_tign.txt', 'w');
    dlmwrite('output_tign.txt', tign(2:n+1,2:m+1), 'delimiter', '\t','precision', '%.4f');
    fclose(fid);
    'printed'
    fid = fopen('data_out_steps.txt', 'w');
    fprintf(fid,'%s',data_steps); % It has two rows now.
    fclose(fid);

   
    break
elseif (changed_old==changed)
	    fid = fopen('no_fixed_point_inside.txt', 'w');
		    dlmwrite('no_fixed_point_inside.txt', tign(2:n+1,2:m+1), 'delimiter', '\t','precision', '%.4f');
			    fclose(fid);
				    'no_fixed_point_inside'
             data_steps=sprintf('%s\n%s',data_steps,'no_fixed_point_inside');   
        result=0;

    end
    
tign_last=tign_in;

% tign_update - updates the tign of the points
[tign_in,A]=tign_update(long,lat,vf,uf,dzdxf,dzdyf,fuel,tign_in,A,IN,time_now,ichap,bbb,phiwc,betafl,r_0);

changed=sum(tign_in(:)~=tign_last(:));
data_steps=sprintf('%s\n step %i inside tign changed at %i points',data_steps,istep,changed);

% Writing the data to the file data_out.txt
fid = fopen('data_out_steps.txt', 'w');
fprintf(fid,'%s',data_steps); % It has two rows now.
fclose(fid);
final_tign(2:n+1,2:m+1)=(IN(:,:,1)>0).*tign_in(2:n+1,2:m+1)+(IN(:,:,1)==0).*tign(2:n+1,2:m+1);
% figure(4),mesh(tign_last(2:n+1,2:m+1)),title(['tign last, step',int2str(istep)])
% figure(5),mesh(tign-tign_last),title(['Difference, step',int2str(istep)])
 figure(6),mesh(final_tign(2:n+1,2:m+1)),title(['tign new, step',int2str(istep)])
% 
 drawnow
result=0;
end

if changed~=0,
    data_steps=sprintf('%s\n%s',data_steps,'did not find fixed point inside');
    warning('did not find fixed point inside')
end

end

function [tign,A]=tign_update(long,lat,vf,uf,dzdxf,dzdyf,fuel,tign,A,IN,time_now,ichap,bbb,phiwc,betafl,r_0)
  
% tign  array same size as A and V: time of ignition at all points
% A,IN flags from above
% V - wind; the first dim = x y coord
% time_now = time of ignition on the perimeter
n=size(tign,1);
m=size(tign,2);
for i=2:n-1
    for j=2:m-1
        % Needed to know what is the amount of points that surrounds (i,j)
        sum_A=sum(sum(A(i-1:i+1,j-1:j+1)));
        % sum_A>0 if tign available at at least one neighbor
        
        if (sum_A~=0)
            if (IN(i-1,j-1)>0) 
                % Points are inside the perimeter
                tign_old=(A(i,j)==1)*tign(i,j);  % previous tign if exists at this point
                    
                for a=i-1:i+1   
                    for b=j-1:j+1  
                    	% loop over all neighbors
                        if (A(a,b)==1) % was already updated 
                            wind=(long(a-1,b-1,1)-long(i-1,j-1, 1))*vf(i-1,j-1,1)+  ... 
                                     (lat(a-1,b-1,1)-lat(i-1,j-1,1))*uf(i-1,j-1,1);
                            angle=(long(a-1,b-1,1)-long(i-1,j-1,1))*dzdxf(i-1,j-1,1)+  ... 
                                     (lat(a-1,b-1,1)-lat(i-1,j-1,1))*dzdyf(i-1,j-1,1);
                            if ~ichap,
                                %       ... if wind is 0 or into fireline, phiw = 0, &this reduces to backing ros.
                                spdms = max(wind,0.);
                                umidm = min(spdms,30.);                    % max input wind spd is 30 m/s   !param!
                                umid = umidm * 196.850;                    % m/s to ft/min
                                %  eqn.: phiw = c * umid**bbb * (betafl/betaop)**(-e) ! wind coef
                                phiw = umid^bbb * phiwc;                   % wind coef
                                phis = 5.275 * betafl^(-0.3) *max(0,angle)^2;   % slope factor
                                ros = r_0*(1. + phiw + phis)  * .00508; % spread rate, m/s
                            else  % chapparal
                                %        .... spread rate has no dependency on fuel character, only windspeed.
                                spdms = max(wind,0.);
                                ros = max(.03333,1.2974 * spdms^1.41);       % spread rate, m/s
                            end
                            ros=min(ros,6);
                        	tign_new=tign(a,b)-sqrt((long(a-1,b-1,1)-long(i-1,j-1,1))^2+   ...
                                     (lat(a-1,b-1,1)-lat(i-1,j-1,1))^2)/ros;                   ...
                                     
                            % update of the tign based on tign and ros
                            % of the neighbour
         
                            if (tign_old<tign_new)&&(tign_new<=time_now);
                            	% Looking for the max tign, which
                                % should be <= than time_now, since the
                                % point is inside of the preimeter
                                tign_old=tign_new;
                                A(i,j)=1;
                            end
                        end
                    end
                end
            
                tign(i,j)=tign_old;
            
            else
                % Points are outside of the perimeter
                % Previous tign if exists at this point, 
                % if not then inf
                if (A(i,j)==1)
                    tign_old=tign(i,j);
                else
                    tign_old=inf;
                end
                    
                for a=i-1:i+1  
                	for b=j-1:j+1  
                    	if (A(a,b)==1)            
                            wind=(long(i-1,j-1,1)-long(a-1,b-1,1))*vf(a-1,b-1,1)+  ... 
                                     (lat(i-1,j-1,1)-lat(a-1,b-1,1))*uf(a-1,b-1,1);
                            angle=(long(i-1,j-1,1)-long(a-1,b-1,1))*dzdxf(a-1,b-1,1)+  ... 
                                     (lat(i-1,j-1,1)-lat(a-1,b-1,1))*dzdyf(a-1,b-1,1);
                            if ~ichap,
                                %       ... if wind is 0 or into fireline, phiw = 0, &this reduces to backing ros.
                                spdms = max(wind,0.);
                                umidm = min(spdms,30.);                    % max input wind spd is 30 m/s   !param!
                                umid = umidm * 196.850;                    % m/s to ft/min
                                %  eqn.: phiw = c * umid**bbb * (betafl/betaop)**(-e) ! wind coef
                                phiw = umid^bbb * phiwc;                   % wind coef
                                phis = 5.275 * betafl^(-0.3) *max(0,angle)^2;   % slope factor
                                ros = r_0*(1. + phiw + phis)  * .00508; % spread rate, m/s
                            else  % chapparal
                                %        .... spread rate has no dependency on fuel character, only windspeed.
                                spdms = max(wind,0.);
                                ros = max(.03333,1.2974 * spdms^1.41);       % spread rate, m/s
                            end
                            ros=min(ros,6);
                            tign_new=tign(a,b)+sqrt((long(a-1,b-1,1)-long(i-1,j-1,1))^2+    ...
                                     (lat(a-1,b-1,1)-lat(i-1,j-1,1))^2)/ros;                    ...
                            % Here the direction of the vector is
                            % opposite, since fire is going from the
                            % inside point towards the point that was
                            % already computed
                            if (tign_old>tign_new)&&(tign_new>=time_now);
                            	tign_old=tign_new;
                            	A(i,j)=1;
                            end
                        end
                    end
                end
                
                tign(i,j)=tign_old;
          
            end
        end
    end
end
end

function [ichap,bbb,phiwc,betafl,r_0]=fire_ros_new(fuel,fmc_g)
% ros=fire_ros(fuel,speed,tanphi)
% ros=fire_ros(fuel,speed,tanphi,fmc_g)
% in
%       fuel    fuel description structure
%       speed   wind speed
%       tanphi  slope
%       fmc_g   optional, overrides fuelmc_g from the fuel description
% out
%       ros     rate of spread

% given fuel params

windrf=fuel.windrf;               % WIND REDUCTION FACTOR
fgi=fuel.fgi;                     % INITIAL TOTAL MASS OF SURFACE FUEL (KG/M**2)
fueldepthm=fuel.fueldepthm;       % FUEL DEPTH (M)
savr=fuel.savr;                   % FUEL PARTICLE SURFACE-AREA-TO-VOLUME RATIO, 1/FT
fuelmce=fuel.fuelmce;             % MOISTURE CONTENT OF EXTINCTION
fueldens=fuel.fueldens;           % OVENDRY PARTICLE DENSITY, LB/FT^3
st=fuel.st;                       % FUEL PARTICLE TOTAL MINERAL CONTENT
se=fuel.se;                       % FUEL PARTICLE EFFECTIVE MINERAL CONTENT
weight=fuel.weight;               % WEIGHTING PARAMETER THAT DETERMINES THE SLOPE OF THE MASS LOSS CURVE
fci_d=fuel.fci_d;                 % INITIAL DRY MASS OF CANOPY FUEL
fct=fuel.fct;                     % BURN OUT TIME FOR CANOPY FUEL, AFTER DRY (S)
ichap=fuel.ichap;                 % 1 if chaparral, 0 if not
fci=fuel.fci;                     % INITIAL TOTAL MASS OF CANOPY FUEL
fcbr=fuel.fcbr;                   % FUEL CANOPY BURN RATE (KG/M**2/S)
hfgl=fuel.hfgl;                   % SURFACE FIRE HEAT FLUX THRESHOLD TO IGNITE CANOPY (W/m^2)
cmbcnst=fuel.cmbcnst;             % JOULES PER KG OF DRY FUEL
fuelheat=fuel.fuelheat;           % FUEL PARTICLE LOW HEAT CONTENT, BTU/LB
fuelmc_g=fuel.fuelmc_g;           % FUEL PARTICLE (SURFACE) MOISTURE CONTENT, jm: 1 by weight?
fuelmc_c=fuel.fuelmc_c;           % FUEL PARTICLE (CANOPY) MOISTURE CONTENT, 1

if exist('fmc_g','var') % override moisture content by given
    fuelmc_g = fmc_g;
end

% computations from CAWFE code: wf2_janice/fire_startup.m4 

bmst     = fuelmc_g/(1+fuelmc_g);          % jm: 1 
fuelheat = cmbcnst * 4.30e-04;             % convert J/kg to BTU/lb
fci      = (1.+fuelmc_c)*fci_d;
fuelloadm= (1.-bmst) * fgi;                % fuelload without moisture
                                           % jm: 1.-bmst = 1/(1+fuelmc_g) so fgi includes moisture? 
fuelload = fuelloadm * (.3048)^2 * 2.205;  % to lb/ft^2
fueldepth= fueldepthm/0.3048;              % to ft
betafl   = fuelload/(fueldepth * fueldens);% packing ratio  jm: lb/ft^2/(ft * lb*ft^3) = 1
betaop   = 3.348 * savr^(-0.8189);         % optimum packing ratio jm: units??  
qig      = 250. + 1116.*fuelmc_g;          % heat of preignition, btu/lb
epsilon  = exp(-138./savr );               % effective heating number
rhob     = fuelload/fueldepth;             % ovendry bulk density, lb/ft^3
c        = 7.47 * exp(-0.133 * savr^0.55); % const in wind coef
bbb      = 0.02526 * savr^0.54;            % const in wind coef
c        = c * windrf^bbb;                 % jm: wind reduction from 20ft per Baughman&Albini(1980)
e        = 0.715 * exp( -3.59e-4 * savr);  % const in wind coef
phiwc    = c * (betafl/betaop)^(-e); 
rtemp2   = savr^1.5;
gammax   = rtemp2/(495. + 0.0594*rtemp2);  % maximum rxn vel, 1/min
a        = 1./(4.774 * savr^0.1 - 7.27);   % coef for optimum rxn vel
ratio    = betafl/betaop;   
gamma    = gammax*(ratio^a)*exp(a*(1.-ratio)); % optimum rxn vel, 1/min
wn       = fuelload/(1 + st);              % net fuel loading, lb/ft^2
rtemp1   = fuelmc_g/fuelmce;
etam     = 1.-2.59*rtemp1 +5.11*rtemp1^2 -3.52*rtemp1^3;  % moist damp coef
etas     = 0.174* se^(-0.19);              % mineral damping coef
ir       = gamma * wn * fuelheat * etam * etas; % rxn intensity,btu/ft^2 min
irm      = ir * 1055./( 0.3048^2 * 60.) * 1.e-6;% for mw/m^2 (set but not used)
xifr     = exp( (0.792 + 0.681*savr^0.5)...
            * (betafl+0.1)) /(192. + 0.2595*savr); % propagating flux ratio
%        ... r_0 is the spread rate for a fire on flat ground with no wind.
r_0      = ir*xifr/(rhob * epsilon *qig);  % default spread rate in ft/min

% computations from CAWFE code: wf2_janice/fire_ros.m4 


end


















 