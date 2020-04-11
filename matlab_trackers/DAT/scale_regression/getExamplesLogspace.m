function [ Y,O ] = getExamplesLogspace(bbox, gt)
%GET_EXAMPLES Summary of this function goes here
%   Detailed explanation goes here

n = size(bbox,1);

% target values
Y = zeros(n, 4, 'single');

% overlap amounts
O = overlap_ratios(bbox, gt);

for i = 1:n
%   Y(i,:) = gt(i,:);
  ex_box = bbox(i,:);
  gt_box = gt(i,:);

  src_w = ex_box(3);
  src_h = ex_box(4);
  src_ctr_x = ex_box(1) + 0.5*src_w;
  src_ctr_y = ex_box(2) + 0.5*src_h;

  gt_w = gt_box(3);
  gt_h = gt_box(4);
  gt_ctr_x = gt_box(1) + 0.5*gt_w;
  gt_ctr_y = gt_box(2) + 0.5*gt_h;

  dst_ctr_x = (gt_ctr_x - src_ctr_x) * 1/src_w;
  dst_ctr_y = (gt_ctr_y - src_ctr_y) * 1/src_h;
  dst_scl_w = log(gt_w / src_w);
  dst_scl_h = log(gt_h / src_h);

  Y(i, :) = [dst_ctr_x dst_ctr_y dst_scl_w dst_scl_h];
end

end

