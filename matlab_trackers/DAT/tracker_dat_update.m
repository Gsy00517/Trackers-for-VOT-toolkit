function [state, location, confidence] = tracker_dat_update(state, I, varargin)
try
  confidence = 1.0; % TODO
  % Configuration parameter
  if nargin < 3
    error('No configuration provided');
  else
    cfg = varargin{1};
  end
  
  tic
  %% Resize & preprocess input image
  [state, img_preprocessed] = state.imgFunc(state, resizeImage(I, state.scale_factor));
  switch cfg.color_space
    case 'rgb'
      img = uint8(255.*img_preprocessed);
    case 'rgchroma'
      img = uint8(255.*rgb2rgchroma(img_preprocessed));
    case 'lab'
      img = lab2uint8(applycform(img_preprocessed, state.lab_transform));
    case 'hsv'
      img = uint8(255.*rgb2hsv(img_preprocessed));
    case 'hs'
      hs = uint8(255.*rgb2hsv(img_preprocessed));
      img = hs(:,:,1:2);
    case 'xyz'
      img = uint8(255.*rgb2xyz(img_preprocessed, 'WhitePoint', 'd50'));
    case 'ycbcr'
      img = uint8(255.*stretchYCbCr(img_preprocessed));
    case 'gray'
      img = uint8(255.*rgb2gray(img_preprocessed));
    otherwise
      error('Color space not supported');
  end
  t_preprocess = toc;
  
  %% Localization
  tic
  % Previous location (in original image size).
  [state, prev_pos, prev_sz] = state.motionPredictionFunc(state);
  
  % Scale to current image dimensions.
  target_pos = prev_pos .* state.scale_factor;
  target_sz = prev_sz .* state.scale_factor;
  
  % Search region
  search_sz = floor(target_sz .* cfg.search_win_factor);
  search_rect = pos2rect(target_pos, search_sz);
  [search_win, search_win_padding] = getSubwindowMasked(img, target_pos, search_sz);
  % Apply probability LUT
  pm_search_bg = getForegroundProb(search_win, state.prob_lut, cfg.bin_mapping);
  pm_search_bg(search_win_padding) = 0;
  pm_search_bg(pm_search_bg < state.adaptive_threshold) = pm_search_bg(pm_search_bg < state.adaptive_threshold) .* 0.5;
  state.vis_pm = pm_search_bg;
  state.vis_offset = search_rect;
  if cfg.distractor_aware
    pm_search_dist = getForegroundProb(search_win, state.prob_lut_distractor, cfg.bin_mapping);
    pm_search_dist(search_win_padding) = 0;
    state.vis_pm_dist = pm_search_dist;
    % Localize via NMS
    [hypotheses, vote_scores, distractor_scores, distance_scores] = getNMSRects(pm_search_bg, pm_search_dist, pos2rect(target_pos - search_rect(1:2) + 1, target_sz), ...
      cfg.nms_overlap, cfg.nms_score_factor, search_win_padding);
    hypotheses_centers = hypotheses(:,1:2) + hypotheses(:,3:4)./2;

    if size(hypotheses,1) > 1  
      % Multiple hypotheses, use distance + distractor score map
      candidate_scores = (distractor_scores + vote_scores).* distance_scores;
      [~, idx] = sort(candidate_scores, 'descend');

      best_hypothesis = idx(1);
      target_pos = hypotheses_centers(best_hypothesis,:);
      distractors = hypotheses(idx(2:end),:);
      distractor_overlap = intersectionOverUnion(pos2rect(target_pos, target_sz), distractors);
      dist_centers = (distractors(:,1:2) + distractors(:,3:4)./2) ./ state.scale_factor;
      dist_dim = distractors(:,3:4) ./ state.scale_factor;
      state.prev_distractors_orig = [dist_centers, dist_dim];
    else
      best_hypothesis = 1;
      target_pos = hypotheses_centers(1,:);
      distractors = [];
      distractor_overlap = [];
      state.prev_distractors_orig = [];
    end
  else
    state.vis_pm_dist = state.vis_pm;
    % Not distractor aware
    [hypotheses, vote_scores, distance_scores] = getNMSRectsNoDAT(pm_search_bg, pos2rect(target_pos - search_rect(1:2) + 1, target_sz), ...
      cfg.nms_overlap, cfg.nms_score_factor, search_win_padding);
    [~, best_hypothesis] = max(vote_scores .* distance_scores);
    hypotheses_centers = hypotheses(:,1:2) + hypotheses(:,3:4)./2;
    target_pos = hypotheses_centers(best_hypothesis,:);
    distractors = [];
    distractor_overlap = [];
  end
   
    
  % Localization visualization
  if cfg.show_figures
    figure(2), clf
    subplot(121), imagesc(pm_search_bg, [0 1]), axis image
    for i = 1:size(hypotheses,1)
      if i == best_hypothesis, color = 'r'; else color = 'y'; end
      rectangle('Position',hypotheses(i,:),'EdgeColor',color,'LineWidth',2);
    end
    
    if cfg.distractor_aware
      subplot(122), imagesc(pm_search_dist, [0 1]), axis image
      title('Search Dist')
      for i = 1:size(hypotheses,1)
        if i == best_hypothesis, color = 'r'; else color = 'y'; end
        rectangle('Position',hypotheses(i,:),'EdgeColor',color,'LineWidth',2);
      end
    end
  end
  t_localize = toc;
  
    
  %% Scale update
  tic
  % Extract surrounding region
  target_pos_img = target_pos + search_rect(1:2)-1;
  surr_sz = floor(cfg.surr_win_factor * target_sz);
  surr_rect = pos2rect(target_pos_img, surr_sz);
  obj_rect_surr = pos2rect(target_pos_img, target_sz) - [surr_rect(1:2)-1, 0, 0];
  [surr_win, surr_win_padded] = getSubwindowMasked(img, target_pos_img, surr_sz);
  max_scale_update_rate = .2;
  switch cfg.scale_update
    case 'regression'
      % Skip scale update if we don't have a reliable model, or if we
      % touched the border/were outside the border previously
      if ~isempty(state.scale_model) && state.is_within_border(end)
        % Extract foreground probabilities.
        surr_prob_map = getForegroundProb(surr_win, state.prob_lut, cfg.bin_mapping);
        surr_prob_map(surr_win_padded) = 0;

        if cfg.scale_adaptive_thresholding
          % Threshold with adaptive threshold.
          threshed = surr_prob_map;
          threshed(threshed < state.adaptive_threshold) = 0;
          spm = threshed;
        else
          spm = surr_prob_map;
        end


        % Refine center location
        [features_horz, features_vert, ft_scl] = extractFeatures(spm, obj_rect_surr, cfg.scale_feature_dimension);
        pred_center = predictCenterRefinement(features_horz, features_vert, state.scale_model.center_refinement);
        pred_center = pred_center .* ft_scl;

        % Extract foreground probabilities from refined location.
        ref_center_img = pred_center + surr_rect(1:2) - 1;

        surr_rect = pos2rect(ref_center_img, surr_sz);
        obj_rect_surr = pos2rect(ref_center_img, target_sz) - [surr_rect(1:2)-1, 0, 0];

        [surr_win, surr_win_padded] = getSubwindowMasked(img, ref_center_img, surr_sz);
        surr_prob_map = getForegroundProb(surr_win, state.prob_lut, cfg.bin_mapping);
        surr_prob_map(surr_win_padded) = 0;

        if cfg.scale_adaptive_thresholding
          % Threshold with adaptive threshold.
          threshed = surr_prob_map;
          threshed(threshed < state.adaptive_threshold) = 0;
          spm = threshed;
        else
          spm = surr_prob_map;
        end

        % Regress scale!
        [features_horz, features_vert, ft_scl] = extractFeatures(spm, obj_rect_surr, cfg.scale_feature_dimension);
        pred_scl = predictScaleEstimate(features_horz, features_vert, state.scale_model.scale_estimate);
        pred_scl = round_base(1000*pred_scl, 25)/1000;

        % in search win coords (pred_center + surr_rect offset) = img pos - search_win offset
        tpos_ref = ref_center_img - search_rect(1:2)-1;
        tsz_ref = target_sz .* pred_scl;
        reg_rect = pos2rect(tpos_ref, tsz_ref);


        target_pos = tpos_ref; %(1-max_scale_update_rate) .* target_pos + max_scale_update_rate .* tpos_ref;
        target_sz = (1-max_scale_update_rate) .* target_sz + max_scale_update_rate .* tsz_ref;

        state.reg_rect = (reg_rect + [search_rect(1:2)-1,0,0]) ./ state.scale_factor;

        if cfg.show_figures
          figure(3),clf
          subplot(221), imagesc(surr_prob_map), axis image
          subplot(222), imagesc(spm), axis image
          rectangle('Position', obj_rect_surr, 'EdgeColor', 'r', 'LineWidth', 2)
          rectangle('Position', reg_rect, 'EdgeColor', 'y', 'LineWidth', 2)

          rectangle('Position', pos2rect(target_pos - surr_rect(1:2) + search_rect(1:2), target_sz), 'EdgeColor', 'm', 'LineWidth', 2)

          subplot(223)
          plot(features_horz, 'b')
          hold on
          plot([1, cfg.scale_feature_dimension], [scl_w scl_w], 'm')
          xlim([1 cfg.scale_feature_dimension]);
          title(sprintf('H dist %.2f', hist_dist))
          subplot(224)
          plot(features_vert, 'b')
          hold on
          plot([1, cfg.scale_feature_dimension], [scl_w scl_w], 'm')
          xlim([1 cfg.scale_feature_dimension]);
          title(sprintf('V weight %.2f', scl_w))
        end
      end

    case 'none'
      % Do nothing

    otherwise
      error('Not supported')
  end
  t_scale = toc;
  
  %% Appearance update
  tic
  % Get current target position within full (possibly downscaled) image coorinates
  target_pos_img = target_pos + search_rect(1:2)-1;
  if cfg.prob_lut_update_rate_bg > 0
    % Extract surrounding region
    surr_sz = floor(cfg.surr_win_factor * target_sz);
    surr_rect = pos2rect(target_pos_img, surr_sz);
    obj_rect_surr = pos2rect(target_pos_img, target_sz) - [surr_rect(1:2)-1, 0, 0];
    [surr_win, padded] = getSubwindowMasked(img, target_pos_img, surr_sz);
    
    [prob_lut_bg, obj_hist] = getForegroundBackgroundProbs(surr_win, obj_rect_surr, cfg.num_bins, cfg.bin_mapping);
    state.obj_histograms{end+1} = obj_hist;
    
    ur_bg = cfg.prob_lut_update_rate_bg;
    
    if cfg.distractor_aware
      distractors(distractor_overlap > cfg.distractor_iou_threshold,:) = [];
      % Handle distractors
      if ~isempty(distractors)
        obj_rect = pos2rect(target_pos, target_sz);
        prob_lut_dist = getForegroundDistractorProbs(search_win, obj_rect, distractors, cfg.num_bins, cfg.bin_mapping);

        ur_dist = cfg.prob_lut_update_rate_dist;
        state.prob_lut_distractor = (1-ur_dist) .* state.prob_lut_distractor + ur_dist .* prob_lut_dist;
      else
        if cfg.distractor_model_decay
          % If there are no distractors, decay the distractor LUT to become
          % obj vs background again, use ur_bg for slower decay
          state.prob_lut_distractor = (1-ur_bg) .* state.prob_lut_distractor + ur_bg .* prob_lut_bg;
        end
      end
      state.prob_lut = (1-ur_bg) .* state.prob_lut + ur_bg .* prob_lut_bg;
    else % No distractor-awareness
      state.prob_lut = (1-ur_bg) .* state.prob_lut + ur_bg .* prob_lut_bg;
    end
    % Update adaptive threshold  
    prob_map = getForegroundProb(surr_win, state.prob_lut, cfg.bin_mapping);
    prob_map(padded) = 0;
    thresh = getAdaptiveThreshold(prob_map, obj_rect_surr, cfg);
    state.adaptive_threshold = thresh;
  end
  t_appearance = toc;
    
  %% Store current location
  % target_pos is within search window
  target_pos = target_pos + search_rect(1:2)-1;
  % Scale to original image dimension
  target_pos_original = target_pos ./ state.scale_factor;
  target_sz_original = target_sz ./ state.scale_factor;
  % Crop rectangle to image boundaries
  target_rect = pos2rect(target_pos_original, target_sz_original);
  is_within_border = isInsideImage(target_rect, [size(I,2), size(I,1)]);
  if state.is_within_border(end) && is_within_border 
    state.last_known_target_sz_within_border = round(target_rect(3:4));
  else
    % Either the current or the previous states touched/were outside the
    % border. So we still have to restore the aspect ratio.
    target_rect = round(pos2rect(target_pos_original, max(target_sz_original, state.last_known_target_sz_within_border), [size(I,2) size(I,1)]));
    if target_rect(3) >= state.last_known_target_sz_within_border(1) && target_rect(4) >= state.last_known_target_sz_within_border(2)
      is_within_border = true;
    else
      is_within_border = false;
    end
  end
  state.is_within_border = [state.is_within_border; is_within_border];
  target_pos_original = target_rect(1:2) + target_rect(3:4) ./ 2 - 1;
  target_sz_original = target_rect(3:4);
  % Stay within reasonable size limits
  min_sz = max(30, 0.02 * max([size(I,1), size(I,2)]));
  max_sz = max(min_sz, 0.8 * min([size(I,1), size(I,2)]));
  if any(target_sz_original < min_sz) || any(target_sz_original > max_sz)
    target_sz_original = state.target_sz_history(end,:);
  end
  % Remember tracked location
  state.target_pos_history = [state.target_pos_history; target_pos_original];
  state.target_sz_history = [state.target_sz_history; target_sz_original];
  
  % Update motion model
  state = state.motionUpdateFunc(state);
  
  % Report current location
  location = pos2rect(state.target_pos_history(end,:), state.target_sz_history(end,:), [size(I,2) size(I,1)]);
  % VOT evaluations are (0,0) based, but MATLAB 1-based:
  location(1:2) = location(1:2) - 1;
  
  if state.report_poly
    location = rect2poly(location);
  end
  
  % Adapt image scale factor
  scl = cfg.img_scale_target_diagonal/sqrt(sum(target_sz_original.^2));
  state.scale_factor = round_base(100*scl,10)/100;
  if cfg.limit_upscale
    state.scale_factor = min(state.scale_factor, 1);
  end
  
  if cfg.display_timings
    fprintf('Timings:\n  Preprocess: %.3f\n  Localize:   %.3f\n  Scale:      %.3f\n  Appearance: %.3f\n', t_preprocess, t_localize, t_scale, t_appearance);
  end
catch MExc
  MExc
  location = [1 1 1 1]; % invalid location
  if state.report_poly
    location = rect2poly(location);
  end
end
end

function inside = isInsideImage(rect, wh)
  inside = rect(1) >= 1 && rect(2) >= 1 && (rect(1)+rect(3)) <= wh(1) && (rect(2)+rect(4)) <= wh(2);
end

% target_rect Single 1x4 rect
function iou = intersectionOverUnion(target_rect, candidates)
  assert(size(target_rect,1) == 1)
  inA = rectint(candidates,target_rect);
  unA = prod(target_rect(3:4)) + prod(candidates(:,3:4),2) - inA;
  iou = inA ./ max(eps,unA);
end

