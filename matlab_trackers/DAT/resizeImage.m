function [ J ] = resizeImage(I, scale)
%RESIZEIMAGE Summary of this function goes here
%   Detailed explanation goes here

% We round the scale factor to closest 10th prevent unnecessary scalings
if abs(1 - scale) < 1e-2
  J = I;
else
  J = imresize(I, scale, 'nearest');
end
end

