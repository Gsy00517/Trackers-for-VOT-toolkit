function prob_lut = getForegroundDistractorProbs(frame, obj_rect, distractors, num_bins, bin_mapping)
%GETFOREGROUNDDISTRACTORPROBS Computes the probability lookup table 
%for the object vs distractor model.
% Parameters:
%   frame       Input (color) image 
%   obj_rect    Rectangular object region
%   distractors Nx4 matrix where each row corresponds to a rectangular
%               distractor region
%   num_bins    Number of bins per channel (scalar)
%   bin_mapping Maps intensity values to num_bins bins

  [rows,cols,layers] = size(frame);
  obj_rect = round(obj_rect);

  num_distr = size(distractors,1);

  if layers == 3 % Color image
    obj_hist = zeros(num_bins, num_bins, num_bins, 'double');
    distr_hist = zeros(num_bins, num_bins, num_bins, 'double');

    % Mask object and distracting regions
    Md = false(size(frame,1),size(frame,2));
    Mo = false(size(frame,1),size(frame,2));
    Mo(obj_rect(2):obj_rect(2)+obj_rect(4),obj_rect(1):obj_rect(1)+obj_rect(3)) = true;
    for i = 1:num_distr
      Md(distractors(i,2):distractors(i,2)+distractors(i,4),distractors(i,1):distractors(i,1)+distractors(i,3)) = true;
    end
    
    [x,y] = meshgrid(1:cols, 1:rows);
    xo = x(Mo);
    yo = y(Mo);
    xd = x(Md);
    yd = y(Md);
    od = ones(numel(xd),1);
    oo = ones(numel(xo),1);

    % Distractor histogram
    idx1 = fastSub2Ind([rows, cols], yd, xd);
    idx2 = fastSub2Ind([rows, cols, layers], yd, xd, 2.*od);
    idx3 = fastSub2Ind([rows, cols, layers], yd, xd, 3.*od);

    bin1 = bin_mapping(frame(idx1)+1);
    bin2 = bin_mapping(frame(idx2)+1);
    bin3 = bin_mapping(frame(idx3)+1);


    idx_hist_dist = fastSub2Ind(size(distr_hist), bin1, bin2, bin3);
    sorted_idx = sort(idx_hist_dist(:));
    chg = find([true; diff(sorted_idx)~=0; true]);
    dist_bins = sorted_idx(chg(1:end-1));
    dist_cnt = diff(chg);
    distr_hist(dist_bins) = dist_cnt;

    % Object histogram
    idx1 = fastSub2Ind([rows, cols], yo, xo);
    idx2 = fastSub2Ind([rows, cols, layers], yo, xo, 2.*oo);
    idx3 = fastSub2Ind([rows, cols, layers], yo, xo, 3.*oo);

    bin1 = bin_mapping(frame(idx1)+1);
    bin2 = bin_mapping(frame(idx2)+1);
    bin3 = bin_mapping(frame(idx3)+1);

    idx_hist_obj = fastSub2Ind(size(obj_hist), bin1, bin2, bin3);
    sorted_idx = sort(idx_hist_obj(:));
    chg = find([true; diff(sorted_idx)~=0; true]);
    obj_bins = sorted_idx(chg(1:end-1));
    obj_cnt = diff(chg);
    obj_hist(obj_bins) = obj_cnt;
    distr_hist(obj_bins) = distr_hist(obj_bins) + obj_cnt;
    prob_lut = (obj_hist + 1) ./ (distr_hist + 2);

  elseif layers == 2 % Color image
    obj_hist = zeros(num_bins, num_bins, 'double');
    distr_hist = zeros(num_bins, num_bins, 'double');

    % Mask object and distracting regions
    Md = false(size(frame,1),size(frame,2));
    Mo = false(size(frame,1),size(frame,2));
    Mo(obj_rect(2):obj_rect(2)+obj_rect(4),obj_rect(1):obj_rect(1)+obj_rect(3)) = true;
    for i = 1:num_distr
      Md(distractors(i,2):distractors(i,2)+distractors(i,4),distractors(i,1):distractors(i,1)+distractors(i,3)) = true;
    end

    [x,y] = meshgrid(1:cols, 1:rows);
    xo = x(Mo);
    yo = y(Mo);
    xd = x(Md);
    yd = y(Md);
    oo = ones(numel(xo),1);
    od = ones(numel(xd),1);

    % Distractor histogram
    idx1 = fastSub2Ind([rows, cols], yd, xd);
    idx2 = fastSub2Ind([rows, cols, layers], yd, xd, 2.*od);

    bin1 = bin_mapping(frame(idx1)+1);
    bin2 = bin_mapping(frame(idx2)+1);

    idx_hist_dist = fastSub2Ind(size(distr_hist), bin1, bin2);
    sorted_idx = sort(idx_hist_dist(:));
    chg = find([true; diff(sorted_idx)~=0; true]);
    dist_bins = sorted_idx(chg(1:end-1));
    dist_cnt = diff(chg);
    distr_hist(dist_bins) = dist_cnt;

    % Object histogram
    idx1 = fastSub2Ind([rows, cols], yo, xo);
    idx2 = fastSub2Ind([rows, cols, layers], yo, xo, 2.*oo);

    bin1 = bin_mapping(frame(idx1)+1);
    bin2 = bin_mapping(frame(idx2)+1);

    idx_hist_obj = fastSub2Ind(size(obj_hist), bin1, bin2);
    sorted_idx = sort(idx_hist_obj(:));
    chg = find([true; diff(sorted_idx)~=0; true]);
    obj_bins = sorted_idx(chg(1:end-1));
    obj_cnt = diff(chg);
    obj_hist(obj_bins) = obj_cnt;
    distr_hist(obj_bins) = distr_hist(obj_bins) + obj_cnt;

    prob_lut = (obj_hist + 1) ./ (distr_hist + 2);
    
  elseif layers == 1
    obj_hist = zeros(num_bins, 1, 'double');
    distr_hist = zeros(num_bins, 1, 'double');

    % Mask object and distracting regions
    Md = false(size(frame,1),size(frame,2));
    Mo = false(size(frame,1),size(frame,2));
    Mo(obj_rect(2):obj_rect(2)+obj_rect(4),obj_rect(1):obj_rect(1)+obj_rect(3)) = true;
    for i = 1:num_distr
      Md(distractors(i,2):distractors(i,2)+distractors(i,4),distractors(i,1):distractors(i,1)+distractors(i,3)) = true;
    end

    [x,y] = meshgrid(1:cols, 1:rows);
    xo = x(Mo);
    yo = y(Mo);
    xd = x(Md);
    yd = y(Md);

    % Distractor histogram
    idx1 = fastSub2Ind([rows, cols], yd, xd);

    bin1 = bin_mapping(frame(idx1)+1);

    idx_hist_dist = fastSub2Ind(size(distr_hist), bin1);
    sorted_idx = sort(idx_hist_dist(:));
    chg = find([true; diff(sorted_idx)~=0; true]);
    dist_bins = sorted_idx(chg(1:end-1));
    dist_cnt = diff(chg);
    distr_hist(dist_bins) = dist_cnt;

    % Object histogram
    idx1 = fastSub2Ind([rows, cols], yo, xo);

    bin1 = bin_mapping(frame(idx1)+1);

    idx_hist_obj = fastSub2Ind(size(obj_hist), bin1);
    sorted_idx = sort(idx_hist_obj(:));
    chg = find([true; diff(sorted_idx)~=0; true]);
    obj_bins = sorted_idx(chg(1:end-1));
    obj_cnt = diff(chg);
    obj_hist(obj_bins) = obj_cnt;
    distr_hist(obj_bins) = distr_hist(obj_bins) + obj_cnt;

    prob_lut = (obj_hist + 1) ./ (distr_hist + 2);
  else
    error('Color space not supported');
  end
end




 



