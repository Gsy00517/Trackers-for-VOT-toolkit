% Compile libraries, download network modles and demo sequences for GFS-DCF
[path_root, name, ext] = fileparts(mfilename('fullpath'));

% mtimesx
if exist('tracker_exter/mtimesx', 'dir') == 7
    cd tracker_exter/mtimesx
    mtimesx_build;
    cd(path_root)
end

% PDollar toolbox
if exist('tracker_exter/pdollar_toolbox/external', 'dir') == 7
    cd tracker_exter/pdollar_toolbox/external
    toolboxCompile;
    cd(path_root)
end

% matconvnet
if exist('tracker_exter/matconvnet/matlab', 'dir') == 7
    cd tracker_exter/matconvnet/matlab
    vl_compilenn; % enable/disable GPU based on your hardware
    cd(path_root)
    
    % donwload network
    cd tracker_featu
    mkdir offline_models
    cd offline_models
    if ~(exist('imagenet-resnet-50-dag.mat', 'file') == 2)
        disp('Downloading the network "imagenet-resnet-50-dag.mat" from "http://www.vlfeat.org/matconvnet/models/imagenet-resnet-50-dag.mat"...')
        urlwrite('http://www.vlfeat.org/matconvnet/models/imagenet-resnet-50-dag.mat', 'imagenet-resnet-50-dag.mat');
        disp('Done!')
    end
    cd(path_root)
else
    error('GFS-DCF : Matconvnet not found.')
end

cd(path_root)
    
