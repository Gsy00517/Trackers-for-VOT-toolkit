function model = trainInstanceSpecificScaleRegressor(I, bbox, cfg)
  try
    [PMorig, PM] = getProbMap(I, bbox, cfg);

    [features_horz, features_vert, targets_loc, hypotheses_loc, int_scales_loc] = getShifted(PM, bbox, bbox, cfg);
    % GT scaled to canonical size
    gt_scaled = [targets_loc(:,1:2), targets_loc(:,3:4)-targets_loc(:,1:2)];
    % GT in image region (no scale variation)
    gtc = [targets_loc(:,1:2) .* int_scales_loc, targets_loc(:,3:4) .* int_scales_loc];
    gt_boxes = [gtc(:,1:2), gtc(:,3:4) - gtc(:,1:2)];
    centers = gt_scaled(:,1:2) + gt_scaled(:,3:4)./2;

    overlap = overlapRatios(hypotheses_loc, gt_boxes);
    % Filter augmentations by overlap with groundtruth
    valid_aug = overlap >= cfg.scale_train_min_overlap;
    Xh = features_horz(valid_aug,:);
    Xv = features_vert(valid_aug,:);
    Y = centers(valid_aug,:);

    fprintf('Valid %d/%d\n', size(Xh,1), size(features_horz,1)); %TODO remove

    % Train center refinement
    lambda = .01;
    quantile = 0.25;
    model_center_refine = train_center_refinement(Xh, Xv, Y, lambda, quantile);

    [features_horz, features_vert, targets_rs, overlaps, int_scales_rs] = getRotatedScaled(PMorig, bbox, bbox, cfg);
    valid_aug = overlaps >= cfg.scale_train_min_overlap;
    Xh = features_horz(valid_aug,:);
    Xv = features_vert(valid_aug,:);
    Y = targets_rs(valid_aug);
    fprintf('Valid %d/%d\n', size(Xh,1), size(features_horz,1)); %TODO remove

    model_scale_estimate = train_scale_estimate(Xh, Xv, Y, lambda, quantile);

    model = struct('center_refinement', model_center_refine, 'scale_estimate', model_scale_estimate);
 
  catch MExc
    MExc
    warning('Disable scale update due to numerical instabilities');
    model = [];
  end
end

function [PMorig, PM] = getProbMap(img, obj_rect, cfg)
  w = obj_rect(3);
  h = obj_rect(4);
  cx = obj_rect(1) + (w - 1)/2;
  cy = obj_rect(2) + (h - 1)/2;
  target_pos = round([cx cy]);
  target_sz = round([w h]);
  
  % Compute discriminative object model
  surr_sz = floor(cfg.surr_win_factor * target_sz);
  surr_rect = pos2rect(target_pos, surr_sz);
  obj_rect_surr = pos2rect(target_pos, target_sz, [size(img,2) size(img,1)]) - [surr_rect(1:2)-1, 0, 0];% or replace -1 by extra + [1,1,0,0];
%   [surr_win, padding_mask] = getSubwindowMasked(img, target_pos, surr_sz);
  surr_win = getSubwindow(img, target_pos, surr_sz);
  [prob_lut, ~] = getForegroundBackgroundProbs(surr_win, obj_rect_surr, cfg.num_bins, cfg.bin_mapping);
  surr_prob_map = getForegroundProb(surr_win, prob_lut, cfg.bin_mapping);
  PMorig = getForegroundProb(img, prob_lut, cfg.bin_mapping);
  PM = PMorig;
  if cfg.scale_adaptive_thresholding
    adaptive_threshold = getAdaptiveThreshold(surr_prob_map, obj_rect_surr, cfg);
    PM(PM < adaptive_threshold) = 0;
  end
end

function [features_horz, features_vert, targets, overlaps, int_scales] = getRotatedScaled(PM, hyp, gt, cfg)
  features_horz = [];
  features_vert = [];
  targets = [];
  overlaps = [];
  int_scales = [];
  for rot_deg = cfg.scale_augment_rotations
    [RPM, rotated_gt] = rotateSample(PM, gt, rot_deg);
    rcenter = rotated_gt(1:2) + rotated_gt(3:4)./2;
    for scl = cfg.scale_augment_scales
      scaled_sz = rotated_gt(3:4) .* scl;
      scaled_surr_sz = floor(cfg.surr_win_factor * scaled_sz);
      rgt = pos2rect(rcenter, scaled_sz);
      surr_rect = pos2rect(rcenter, scaled_surr_sz);
      hyp_rect_surr = rgt - [surr_rect(1:2)-1, 0, 0];
      surr_prob_map = getSubwindow(RPM, rcenter, scaled_surr_sz);
      
      if cfg.scale_adaptive_thresholding
        adaptive_threshold = getAdaptiveThreshold(surr_prob_map, hyp_rect_surr, cfg);
        surr_prob_map(surr_prob_map < adaptive_threshold) = 0;
      end
      
      [fh, fv, int_scale] = extractFeatures(surr_prob_map, hyp_rect_surr, cfg.scale_feature_dimension);
      features_horz = [features_horz; fh];
      features_vert = [features_vert; fv];
      targets = [targets; 1/scl];
      overlaps = [overlaps; overlapRatios(rotated_gt, rgt)];
      int_scales = [int_scales; int_scale];
    end
  end
end

function [features_horz, features_vert, targets, hypotheses, int_scales] = getShifted(PM, hyp, gt, cfg)
  hyp_sz = hyp(3:4);
  surr_sz = floor(cfg.surr_win_factor * hyp_sz);
  
  canonical_sz = cfg.scale_feature_dimension;
  y_offset = max(2, fix(.1 * hyp_sz(2)));
  y_shifts = [-2*y_offset; -y_offset; 0; y_offset; 2*y_offset];
  
  x_offset = max(2, fix(.1 * hyp_sz(1)));
  x_shifts = [-2*x_offset; -x_offset; 0; x_offset; 2*x_offset];
  
  features_horz = [];
  features_vert = [];
  targets = [];
  hypotheses = [];
  int_scales = [];
  for j = 1:length(y_shifts)
    hyp_center = hyp(1:2) + hyp_sz./2;
    hyp_pos = hyp_center;
    y_shift = y_shifts(j);
    hyp_pos(2) = hyp_center(2) + y_shift;
    
    for i = 1:length(x_shifts)
      x_shift = x_shifts(i);

      hyp_pos(1) = hyp_center(1) + x_shift;
      surr_rect = pos2rect(hyp_pos, surr_sz);
      hyp_rect_surr = pos2rect(hyp_pos, hyp_sz) - [surr_rect(1:2)-1, 0, 0];
      surr_prob_map = getSubwindow(PM, hyp_pos, surr_sz);
      
      gt_rect_surr = gt - [surr_rect(1:2)-1, 0, 0];
     
      [fh, fv, int_scale] = extractFeatures(surr_prob_map, hyp_rect_surr, canonical_sz);
      
      [sp_h, sp_w] = size(surr_prob_map);
      gt_int = canonical_sz .* gt_rect_surr ./ [sp_w sp_h sp_w sp_h];

      if false
        hyp_int = canonical_sz .* hyp_rect_surr ./ [sp_w sp_h sp_w sp_h];
        interpolated_rows = fh;
        interpolated_cols = fv;
        [sp_h, sp_w] = size(surr_prob_map);
        gt_int = canonical_sz .* gt_rect_surr ./ [sp_w sp_h sp_w sp_h];
        figure(2)
        clf
        subplot(131)
        plot(interpolated_rows)
        hold on
        plot([gt_int(1), gt_int(1)], [0 1], 'g')
        plot([gt_int(1), gt_int(1)] + [gt_int(3),gt_int(3)], [0 1], 'g')
        plot([hyp_int(1), hyp_int(1)], [0 1], 'r')
        plot([hyp_int(1), hyp_int(1)] + [hyp_int(3),hyp_int(3)], [0 1], 'r')
        hold off
        title('Rows/Horz')
        subplot(132)
        plot(interpolated_cols)
        hold on
        plot([gt_int(2), gt_int(2)], [0 1], 'g')
        plot([gt_int(2), gt_int(2)] + [gt_int(4),gt_int(4)], [0 1], 'g')
        plot([hyp_int(2), hyp_int(2)], [0 1], 'r')
        plot([hyp_int(2), hyp_int(2)] + [hyp_int(4),hyp_int(4)], [0 1], 'r')
        hold off
        title('Cols/Vert')
        subplot(133)
        imagesc(surr_prob_map),axis image
        rectangle('position', hyp_rect_surr, 'Edgecolor', 'r', 'LineWidth', 2)
        rectangle('position', gt_rect_surr, 'Edgecolor', 'g', 'LineWidth', 2)
        title(sprintf('iou: %.2f', overlapRatios(hyp_rect_surr, gt_rect_surr)))
        drawnow
      end

      features_horz = [features_horz; fh];
      features_vert = [features_vert; fv];
      targets = [targets; gt_int(1:2), gt_int(1:2) + gt_int(3:4)];
      hypotheses = [hypotheses; hyp_rect_surr];
      int_scales = [int_scales; int_scale];
    end
  end
end

function model = train_center_refinement(Xh, Xv, Y, lambda, quantile)
  % Center and decorrelate targets
  mu = mean(Y);
  Y = bsxfun(@minus, Y, mu);
  S = Y'*Y / size(Y,1);
  [V, D] = eig(S);
  D = diag(D);
  T = V*diag(1./sqrt(D+0.001))*V';
  T_inv = V*diag(sqrt(D+0.001))*V';
  Y = Y * T;

  % Add bias feature
  X = cat(2, [Xh, Xv], ones(size(Xh,1), 1, class(Xh)));
%   Xh = cat(2, Xh, ones(size(Xh,1), 1, class(Xh)));
%   Xv = cat(2, Xv, ones(size(Xv,1), 1, class(Xv)));

  % use ridge regression solved by cholesky factorization
  method = 'ridge_reg_chol';
  
  model.mu = mu;
  model.T = T;
  model.T_inv = T_inv;

  fprintf('Lambda: %f, qtile: %f\n', lambda, quantile);
  % Center X and width
  model.Beta = [ ...
    solveRobust(X, Y(:,1), lambda, method, quantile) ...
    solveRobust(X, Y(:,2), lambda, method, quantile) ...
    ];
end

function model = train_scale_estimate(Xh, Xv, Y, lambda, quantile)
  % Center and decorrelate targets
  mu = mean(Y);
  Y = bsxfun(@minus, Y, mu);
  S = Y'*Y / size(Y,1);
  [V, D] = eig(S);
  D = diag(D);
  T = V*diag(1./sqrt(D+0.001))*V';
  T_inv = V*diag(sqrt(D+0.001))*V';
  Y = Y * T;

  % Add bias feature
  X = cat(2, [Xh, Xv], ones(size(Xh,1), 1, 'like', Xh));

  % use ridge regression solved by cholesky factorization
  method = 'ridge_reg_chol';
  
  model.mu = mu;
  model.T = T;
  model.T_inv = T_inv;

  fprintf('Lambda: %f, qtile: %f\n', lambda, quantile);
  % Center X and width
  model.Beta = solveRobust(X, Y(:,1), lambda, method, quantile);
end

function model = train(Xh, Xv, Y, lambda, quantile)
  % Center and decorrelate targets
  mu = mean(Y);
  Y = bsxfun(@minus, Y, mu);
  S = Y'*Y / size(Y,1);
  [V, D] = eig(S);
  D = diag(D);
  T = V*diag(1./sqrt(D+0.001))*V';
  T_inv = V*diag(sqrt(D+0.001))*V';
  Y = Y * T;

  % Add bias feature
  Xh = cat(2, Xh, ones(size(Xh,1), 1, class(Xh)));
  Xv = cat(2, Xv, ones(size(Xv,1), 1, class(Xv)));

  % use ridge regression solved by cholesky factorization
  method = 'ridge_reg_chol';
  
  model.mu = mu;
  model.T = T;
  model.T_inv = T_inv;

  fprintf('Lambda: %f, qtile: %f\n', lambda, quantile);
  % Center X and width
  model.BetaH = [ ...
    solveRobust(Xh, Y(:,1), lambda, method, quantile) ...
    solveRobust(Xh, Y(:,3), lambda, method, quantile) ...
    ];
  % Center Y and height
  model.BetaV = [ ...
    solveRobust(Xv, Y(:,2), lambda, method, quantile) ...
    solveRobust(Xv, Y(:,4), lambda, method, quantile) ...
    ];
end

% Rotate image I and the annotation by the angle (deg) counterclockwise.
function [R, rbox] = rotateSample(I, box, angle)
  [h,w,~] = size(I);
  R = imrotate(I, angle, 'crop');
  rbox = rotateAlignedBox(box, deg2rad(angle), [w,h]);
end

function [rbox] = rotateAlignedBox(box, theta, img_size)
  half_sz = box(3:4)./2;
  cb = box(1:2) + half_sz;
  ci = img_size./2;
  
  vec = cb - ci;
  rvec = rotateVec(vec, theta);
  
  cbr = ci + rvec;
  rbox = [cbr - half_sz, 2.*half_sz];
end

function [rvec] = rotateVec(vec, theta)
  cs = cos(theta);
  sn = sin(theta);
  % Inverse/transpose of Rotation matrix as we have a left-handed Cartesian
  % coordinate system (x to the right, y down). The standard rotation
  % matrix would thus rotate clockwise!
  R = [cs, -sn;...
    sn, cs]';
  rvec = reshape(R * reshape(vec, [2,1]), size(vec));
end


