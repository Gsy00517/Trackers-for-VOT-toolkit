function initial_net()
% INITIAL_NET: Loading VGG-Net-19

global net;
net = load(fullfile('abs_path/imagenet-vgg-verydeep-19.mat'));
% Remove the fully connected layers and classification layer
net.layers(37+1:end) = [];

end
