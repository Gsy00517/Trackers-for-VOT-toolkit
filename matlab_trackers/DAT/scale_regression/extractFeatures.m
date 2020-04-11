function [ features_horz, features_vert, int_scale ] = extractFeatures(surr_prob_map, obj_rect, dimensionality)
%EXTRACT_FEATURES 
% prob map of surrounding area (surr_rect)
% P = imresize(surr_prob_map, [100, 100]);
% features = P(:)';


% Reduce rows
reduced_rows = sum(surr_prob_map,1);
% Interpolate row reduction to uniform size
interp_coords = linspace(1, length(reduced_rows), dimensionality);
features_horz = interp1(reduced_rows, interp_coords);
features_horz = features_horz ./ max(features_horz);

% Reduce columns
reduced_cols = sum(surr_prob_map,2);
% Interpolate column reduction
interp_coords = linspace(1, length(reduced_cols), dimensionality);
features_vert = interp1(reduced_cols, interp_coords);
features_vert = features_vert ./ max(features_vert);

% Standardization
fh = (features_horz - mean(features_horz)) ./ std(features_horz);
features_horz = fh;
fv = (features_vert - mean(features_vert)) ./ std(features_vert);
features_vert = fv;

int_scale = [length(reduced_rows)/dimensionality, length(reduced_cols)/dimensionality];
end

