function threshold = getAdaptiveThreshold(prob_map, obj_coords, cfg)
%GETADAPTIVETHRESHOLD Returns the threshold to separate foreground from
%background/surroundings based on cumulative histograms
% Parameters:
%   prob_map   [MxNx1] probability map
%   obj_coords Object rectangle defined as a 4 element vector: [x,y,w,h]
%   cfg        DAT configuration

% Object region
obj_prob_map = imcrop(prob_map, obj_coords);
H_obj =  hist(obj_prob_map(:), cfg.adapt_thresh_prob_bins);
H_obj = H_obj./sum(H_obj);
cum_H_obj = cumsum(H_obj);

% Surroundings
H_dist = hist(prob_map(:), cfg.adapt_thresh_prob_bins);
% Remove object information
H_dist = H_dist - H_obj;
H_dist = H_dist./sum(H_dist);
cum_H_dist = cumsum(H_dist);

x = cum_H_obj - (1 - cum_H_dist);
x(x<=0) = 1;
[~,i] = min(x);


target_min_obj_percentage = 0.3;
diff = cum_H_obj - (1-target_min_obj_percentage);
diff(diff > 0) = 1;
[~,max_target_bin] = min(abs(diff));
% % Always ensure, that at least x % of foreground pixels are kept:
threshold = cfg.adapt_thresh_prob_bins(min(i, max_target_bin)) + 0.025;


 
    

