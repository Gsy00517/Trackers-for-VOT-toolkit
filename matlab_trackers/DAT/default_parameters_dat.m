function [ cfg ] = default_parameters_dat()
%DEFAULT_PARAMETERS_DAT Default parametrization
  cfg = struct('show_figures', false);
  cfg.display_timings = false; % Print timing information to identify bottlenecks
  
  % Image scaling
  cfg.img_scale_target_diagonal = 100; % Length of object hypothesis diagonal (Used to downscale image).
  cfg.limit_upscale = true; % If true, we don't upscale the input image to fit the expected target diagonal (yields speed up)
  cfg.preprocess_equalize = false; % Histogram equalization, makes results significantly worse (changing the input color isn't too good for color based models ;)
  
  % Search (localization) and surrounding (model update) regions.
  cfg.surr_win_factor = 2;   % Surrounding win = X * hypothesis size
  cfg.search_win_factor = 4; % X * hypothesis size
  
  % Appearance model
  cfg.color_space = 'rgb';                % 'rgb', 'hsv', 'lab', 'xyz', 'ycbcr', 'hs'
  cfg.num_bins = 16;                      % Number of bins per channel
  cfg.bin_mapping = getBinMapping(cfg.num_bins); % Maps pixel values from [0, 255] to the corresponding bins
  cfg.prob_lut_update_rate_bg = .015;         % Update rate for LUT obj vs background
  cfg.prob_lut_update_rate_dist = .2;        % Update rate for LUT obj vs distractors
  cfg.distractor_aware = true;           % Toggle distractor-awareness
  cfg.adapt_thresh_prob_bins = 0:0.05:1;  % Bins for adaptive threshold. 
  cfg.distractor_iou_threshold = 0.05; % Only update distractor model for hypotheses which overlap less than X with the current hypothesis
  cfg.distractor_model_decay = false; % Should we decay the distractor model? Makes no difference at all on vot13 (w/o scale)
  
  % Motion prediction
  cfg.motion_prediction = 'kalman'; % kalman causes degration of size
  
  % NMS-based localization
  cfg.nms_overlap = .9;               % Overlap between candidate rectangles for NMS
  cfg.nms_score_factor = .5;          % Report all rectangles with score >= X * best_score
  
  % Scale adaption
  cfg.scale_update = 'regression';
  cfg.scale_adaptive_thresholding = true; % Use adaptive binning or not?
  if strcmp(cfg.scale_update, 'regression') == 1
    cfg.scale_feature_dimension = 100;
    cfg.scale_augment_rotations = [-40, -20, 0, 20, 40];
    cfg.scale_augment_scales = 0.9:0.025:1.1;
    cfg.scale_train_min_overlap = 0.6; % Discard augmentations with IOU < x.
    cfg.scale_regression_target = 'plain';
  end
end

