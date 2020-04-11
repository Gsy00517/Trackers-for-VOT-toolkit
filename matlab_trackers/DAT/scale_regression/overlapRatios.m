function [ r ] = overlapRatios( rect1, rect2 )
%OVERLAP_RATIOS Summary of this function goes here
%   Detailed explanation goes here

inter_area = diag(rectint(rect1,rect2));
union_area = rect1(:,3).*rect1(:,4) + rect2(:,3).*rect2(:,4) - inter_area;
r = inter_area./union_area;
end

