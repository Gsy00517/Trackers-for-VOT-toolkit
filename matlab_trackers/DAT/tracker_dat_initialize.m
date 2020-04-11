function [state, location] = tracker_dat_initialize(I, region, varargin)
  if nargin < 3 
    % No tracker configuration provided, use default values
    cfg = default_parameters_dat();
  else
    assert(isstruct(varargin{1}));
    cfg = varargin{1};
  end
  
  state = struct('show_figures', cfg.show_figures);

 %% Prepare init region (axis-aligned bbox)
  % If the provided region is a polygon ...
  if numel(region) > 4
    state.report_poly = true;
    % Init with an axis aligned bounding box with correct area and center
    cx = mean(region(1:2:end));
    cy = mean(region(2:2:end));
    x1 = min(region(1:2:end));
    x2 = max(region(1:2:end));
    y1 = min(region(2:2:end));
    y2 = max(region(2:2:end));
    A1 = norm(region(1:2) - region(3:4)) * norm(region(3:4) - region(5:6));
    A2 = (x2 - x1) * (y2 - y1);
    s = sqrt(A1/A2);
    w = s * (x2 - x1) + 1;
    h = s * (y2 - y1) + 1;
  else
    state.report_poly = false;
    cx = region(1) + (region(3) - 1)/2;
    cy = region(2) + (region(4) - 1)/2;
    w = region(3);
    h = region(4);
  end
  target_pos = round([cx cy]);
  target_sz = round([w h]);
  
  % Store current location (original image scale).
  state.target_pos_history = target_pos;
  state.target_sz_history = target_sz;
  
  % Do we need to scale the image?
  scl = cfg.img_scale_target_diagonal/sqrt(sum(target_sz.^2));
  state.scale_factor = round_base(100*scl,10)/100;
  if cfg.limit_upscale
    state.scale_factor = min(state.scale_factor, 1);
  end
  target_pos = target_pos .* state.scale_factor;
  target_sz = target_sz .* state.scale_factor;
  
  % Resize/preprocess input image
  if cfg.preprocess_equalize
    state.imgFunc = @preprocessEqualize;
  else
    state.imgFunc = @(st, I) deal(st, im2double(I));
  end
  [state, img] = state.imgFunc(state, imresize(I, state.scale_factor, 'nearest'));
  switch cfg.color_space
    case 'rgb'
      img = uint8(255.*img);
    case 'rgchroma'
      img = uint8(255.*rgb2rgchroma(img));
    case 'lab'
      state.lab_transform = makecform('srgb2lab');
      img = lab2uint8(applycform(img, state.lab_transform));
    case 'hsv'
      img = uint8(255.*rgb2hsv(img));
    case 'hs'
      hs = uint8(255.*rgb2hsv(img));
      img = hs(:,:,1:2);
    case 'xyz'
      img = uint8(255.*rgb2xyz(img, 'WhitePoint', 'd50'));
    case 'ycbcr'
      img = uint8(255.*stretchYCbCr(img));
    case 'gray'
      img = uint8(255.*rgb2gray(img));
    otherwise
      error('Not supported');
  end
  
  % Motion prediction
  state.motionUpdateFunc = @(st) st;
  switch cfg.motion_prediction
    case 'none'
      state.motionPredictionFunc = @(st) deal(st, st.target_pos_history(end,:), st.target_sz_history(end,:));
    case 'mean'
      state.motion_estimation_history_size = cfg.motion_estimation_history_size;
      state.motionPredictionFunc = @(st) deal(st, getMeanMotionPrediction(st, st.motion_estimation_history_size));
    case 'kalman'
      % Init Kalman filter.
      pos = state.target_pos_history(end,:);
      sz = state.target_sz_history(end,:);
      state.kalman_filter = struct('position', configureKalmanFilter('ConstantVelocity', pos, ...
          .01 .* sz, [.05 * max(sz), .01 * max(sz)], .01 * max(sz)),...
          'size', configureKalmanFilter('ConstantVelocity', sz, ...
          .01 .* sz, .05 .* sz, max(.05 .* sz)));
      state.motionPredictionFunc = @motionPredictionKalman;
      state.motionUpdateFunc = @motionUpdateKalman;
    otherwise
      error('Not supported')
  end
  
  % Object vs surrounding
  surr_sz = floor(cfg.surr_win_factor * target_sz);
  surr_rect = pos2rect(target_pos, surr_sz); %, [size(img,2) size(img,1)]);
  obj_rect_surr = pos2rect(target_pos, target_sz, [size(img,2) size(img,1)]) - [surr_rect(1:2)-1, 0, 0];% or replace -1 by extra + [1,1,0,0];
  surr_win = getSubwindow(img, target_pos, surr_sz);
  [state.prob_lut, obj_hist] = getForegroundBackgroundProbs(surr_win, obj_rect_surr, cfg.num_bins, cfg.bin_mapping);
  state.obj_histograms = {};
  state.obj_histograms{end+1} = obj_hist;
  prob_map = getForegroundProb(surr_win, state.prob_lut, cfg.bin_mapping);
  
  % Copy initial discriminative model
  state.prob_lut_distractor = state.prob_lut; 
  state.adaptive_threshold = getAdaptiveThreshold(prob_map, obj_rect_surr, cfg);
  
  state.prev_distractors = [];
  if cfg.distractor_aware
    search_sz = floor(target_sz .* cfg.search_win_factor);
    search_rect = pos2rect(target_pos, search_sz);
    [search_win, search_win_padding] = getSubwindowMasked(img, target_pos, search_sz);
  
    pm_search = getForegroundProb(search_win, state.prob_lut, cfg.bin_mapping);
    
    % Localize
    [hypotheses, ~, ~] = getNMSRects(pm_search, pm_search, pos2rect(target_pos - search_rect(1:2) + 1, target_sz), ...
      cfg.nms_overlap, cfg.nms_score_factor, search_win_padding);
    % During init, we know the ground-truth - choose the closest hypothesis:
    centers = hypotheses(:,1:2) + hypotheses(:,3:4)./2 - 1;
    curr_ctr = target_pos - search_rect(1:2)-1;
    dist = sqrt(sum((centers - repmat(curr_ctr, [size(centers,1), 1])).^2, 2));
    [~, best] = min(dist);
    idx = 1:size(centers,1);
    idx(best) = [];
    state.prev_distractors = hypotheses(idx,:);
  end
   
  if state.show_figures
    figure(2), clf
    subplot(121);
    if size(img,3) ~= 2, imshow(img), else imagesc(prob_map,[0 1]), end
    rectangle('Position', pos2rect(target_pos, target_sz, [size(img,2) size(img,1)]),'EdgeColor','y','LineWidth',2);
  end
  
  % Init scale adaption method
  switch cfg.scale_update
    case 'none'
      % Do nothing
    case 'prob_sum'
      % Do nothing
    case 'connected_components'
      % do nothing
    case 'integral_scale'
      % Do nothing
    case 'regression'
      state.scale_model = trainInstanceSpecificScaleRegressor(img, pos2rect(target_pos, target_sz), cfg); 
    otherwise
      error('Not supported')
  end
    
  % Report current location
  location = pos2rect(state.target_pos_history(end,:), state.target_sz_history(end,:), [size(I,2) size(I,1)]);
  
  % Compatibility for VOT evaluation
  if state.report_poly
    location = rect2poly(location);
  end
  
  state.last_known_target_sz_within_border = state.target_sz_history(end,:);
  state.is_within_border = true;
  state.vis_pm = prob_map;
  state.vis_pm_dist = state.vis_pm;
end
