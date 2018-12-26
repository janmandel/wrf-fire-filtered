% set matlab path to include files in wrf/other/Matlab
format compact
d={ [pwd,'/../../../other/Matlab/vis'],...
    [pwd,'/../../../other/Matlab/ROS'],...
    [pwd,'/../../../other/Matlab/util1_jan'],...
    [pwd,'/../../../other/Matlab/netcdf'],...
    [pwd,'/../../../other/Matlab/vis3d'],...
    [pwd,'/../../../other/Matlab/debug'],...
    [pwd,'/../../../other/Matlab/perimeter'],...
    [pwd,'/../../../other/Matlab/detection'],...
    [pwd,'/../../../other/Matlab/detect_ignition'],...
    [pwd,'/../../../other/Matlab/chem'],...
    [pwd,'/../../../other/Matlab/impact'],...
    [pwd,'/../../../other/Matlab/fft']...
};
for i=1:length(d),
    s=d{i};
    addpath(s)
    disp(s)
    ls(s)
end
clear d i s
