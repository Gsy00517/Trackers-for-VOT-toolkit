function prob_map = getForegroundProb(frame, prob_lut, bin_mapping)
%GETFOREGROUNDPROB Compute probability map via lookup tables
% Parameters:
%   frame       Input (color) image
%   prob_lut    Probability lookup table 
%   bin_mapping Mapping from pixel intensities to bins
  [rows, cols, layers] = size(frame);
  prob_map = zeros(rows, cols);

  if layers == 3
    [x,y] = meshgrid(1:cols, 1:rows);
    x = x(:);
    y = y(:);
    o = ones(numel(x), 1);
    idx1 = fastSub2Ind([rows, cols], y, x);
    idx2 = fastSub2Ind([rows, cols, layers], y, x, 2.*o);
    idx3 = fastSub2Ind([rows, cols, layers], y, x, 3.*o);

    bin1 = bin_mapping(frame(idx1)+1);
    bin2 = bin_mapping(frame(idx2)+1);
    bin3 = bin_mapping(frame(idx3)+1);

    ihf = fastSub2Ind(size(prob_lut), bin1, bin2, bin3);

    prob_map(idx1) = prob_lut(ihf);
    
  elseif layers == 2
    [x,y] = meshgrid(1:cols, 1:rows);
    x = x(:);
    y = y(:);
    o = ones(numel(x), 1);
    idx1 = fastSub2Ind([rows, cols], y, x);
    idx2 = fastSub2Ind([rows, cols, layers], y, x, 2.*o);

    bin1 = bin_mapping(frame(idx1)+1);
    bin2 = bin_mapping(frame(idx2)+1);

    ihf = fastSub2Ind(size(prob_lut), bin1, bin2);

    prob_map(idx1) = prob_lut(ihf);
    
  elseif layers == 1
    [x,y] = meshgrid(1:cols, 1:rows);
    idx_map = fastSub2Ind([rows, cols], y(:), x(:));
    bin = bin_mapping(frame(idx_map)+1);
    prob_map(idx_map) = prob_lut(bin);
  else
    error('Color space not supported');
  end
end




 



