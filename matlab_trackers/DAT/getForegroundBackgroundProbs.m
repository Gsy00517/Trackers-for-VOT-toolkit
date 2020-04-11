function [prob_lut, obj_hist] = getForegroundBackgroundProbs(frame, obj_rect, num_bins, bin_mapping)
%GETFOREGROUNDBACKGROUNDPROBS Computes the probability lookup table for the
%object vs surrounding region model.
% Parameters:
%   frame       Input (color) image cropped to contain only the surrounding
%               region
%   obj_rect    Rectangular object region
%   num_bins    Number of bins per channel (scalar)
%   bin_mapping Maps intensity values to num_bins bins


[rows, cols, layers] = size(frame);
obj_row = round(obj_rect(2));
obj_col = round(obj_rect(1));
obj_width = round(obj_rect(3));
obj_height = round(obj_rect(4));

if obj_row + obj_height > rows, obj_height = rows - obj_row; end
if obj_col + obj_width > cols, obj_width = cols - obj_col; end

if layers == 3
  % Color image
  obj_hist = zeros(num_bins, num_bins, num_bins, 'double');
  surr_hist = zeros(num_bins, num_bins, num_bins, 'double');

  % Histogram over full image
  [x,y] = meshgrid(1:cols, 1:rows);
  x = x(:);
  y = y(:);
  o = ones(numel(x),1);
  idx_1 = fastSub2Ind([rows, cols], y, x);
  idx_2 = fastSub2Ind([rows, cols, layers], y, x, 2.*o);
  idx_3 = fastSub2Ind([rows, cols, layers], y, x, 3.*o);
  
  bin_1 = bin_mapping(frame(idx_1)+1);
  bin_2 = bin_mapping(frame(idx_2)+1);
  bin_3 = bin_mapping(frame(idx_3)+1);

  idx_hist_full = fastSub2Ind(size(surr_hist), bin_1, bin_2, bin_3);
  sorted_idx = sort(idx_hist_full(:));
  chg = find([true; diff(sorted_idx)~=0; true]);
  f_bins = sorted_idx(chg(1:end-1));
  f_cnt = diff(chg);
  surr_hist(f_bins) = f_cnt;

  % Histogram over object region
  [x,y] = meshgrid(max(1,obj_col):(obj_col+obj_width), max(1,obj_row):(obj_row+obj_height));
  x = x(:);
  y = y(:);
  o = ones(numel(x),1);
  idx_1 = fastSub2Ind([rows, cols], y, x);
  idx_2 = fastSub2Ind([rows, cols, layers], y, x, 2.*o);
  idx_3 = fastSub2Ind([rows, cols, layers], y, x, 3.*o);

  bin_1o = bin_mapping(frame(idx_1)+1);
  bin_2o = bin_mapping(frame(idx_2)+1);
  bin_3o = bin_mapping(frame(idx_3)+1);


  idx_hist_obj = fastSub2Ind(size(obj_hist), bin_1o, bin_2o, bin_3o);
  sorted_idx = sort(idx_hist_obj(:));
  chg = find([true; diff(sorted_idx)~=0; true]);
  f_bins = sorted_idx(chg(1:end-1));
  f_cnt = diff(chg);
  obj_hist(f_bins) = f_cnt;
   
  prob_lut = (obj_hist + 1) ./ (surr_hist + 2);
  
elseif layers == 2
  % Color image
  obj_hist = zeros(num_bins, num_bins, 'double');
  surr_hist = zeros(num_bins, num_bins, 'double');

  % Histogram over full image
  [x,y] = meshgrid(1:cols, 1:rows);
  x = x(:);
  y = y(:);
  o = ones(numel(x), 1);
  idx_1 = fastSub2Ind([rows, cols], y, x);
  idx_2 = fastSub2Ind([rows, cols, layers], y, x, 2.*o);

  bin_1 = bin_mapping(frame(idx_1)+1);
  bin_2 = bin_mapping(frame(idx_2)+1);

  idx_hist_full = fastSub2Ind(size(surr_hist), bin_1, bin_2);
  sorted_idx = sort(idx_hist_full(:));
  chg = find([true; diff(sorted_idx)~=0; true]);
  f_bins = sorted_idx(chg(1:end-1));
  f_cnt = diff(chg);
  surr_hist(f_bins) = f_cnt;
   

  % Histogram over object region
  [x,y] = meshgrid(max(1,obj_col):(obj_col+obj_width), max(1,obj_row):(obj_row+obj_height));
  x = x(:);
  y = y(:);
  o = ones(numel(x),1);
  idx_1 = fastSub2Ind([rows, cols], y, x);
  idx_2 = fastSub2Ind([rows, cols, layers], y, x, 2.*o);
  
  bin_1o = bin_mapping(frame(idx_1)+1);
  bin_2o = bin_mapping(frame(idx_2)+1);

  idx_hist_obj = fastSub2Ind(size(obj_hist), bin_1o, bin_2o);
  sorted_idx = sort(idx_hist_obj(:));
  chg = find([true; diff(sorted_idx)~=0; true]);
  f_bins = sorted_idx(chg(1:end-1));
  f_cnt = diff(chg);
  obj_hist(f_bins) = f_cnt;
   
  
  prob_lut = (obj_hist + 1) ./ (surr_hist + 2);
  
elseif layers == 1
  % Gray image
  obj_hist = zeros(num_bins, 1, 'double');
  surr_hist = zeros(num_bins, 1, 'double');

  % Histogram over full image
  [x,y] = meshgrid(1:cols, 1:rows);
    %   idx_map = sub2ind([rows, cols], y(:), x(:));
  idx_map = fastSub2Ind([rows, cols], y(:), x(:));

  bin = bin_mapping(frame(idx_map)+1);

  idx_hist_full = fastSub2Ind(size(surr_hist), bin);
  sorted_idx = sort(idx_hist_full(:));
  chg = find([true; diff(sorted_idx)~=0; true]);
  f_bins = sorted_idx(chg(1:end-1));
  f_cnt = diff(chg);
  surr_hist(f_bins) = f_cnt;
   

  % Histogram over object region
  [x,y] = meshgrid(max(1,obj_col):(obj_col+obj_width), max(1,obj_row):(obj_row+obj_height));
  idx = fastSub2Ind([rows, cols], y(:), x(:));

  bin_1o = bin_mapping(frame(idx)+1);

  idx_hist_obj = fastSub2Ind(size(obj_hist), bin_1o);
  sorted_idx = sort(idx_hist_obj(:));
  chg = find([true; diff(sorted_idx)~=0; true]);
  f_bins = sorted_idx(chg(1:end-1));
  f_cnt = diff(chg);
  obj_hist(f_bins) = f_cnt;
  
  
  prob_lut = (obj_hist + 1) ./ (surr_hist + 2);
else
  error('Not supported\n');
end

end

