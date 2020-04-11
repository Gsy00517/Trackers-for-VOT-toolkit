function [features_horz, features_vert, reg_targets, hypotheses, int_scales, obj_histogram] = extractSamples(img, obj_rect, cfg)
%EXTRACT_SAMPLES Summary of this function goes here
%   Detailed explanation goes here
  w = obj_rect(3);
  h = obj_rect(4);
  cx = obj_rect(1) + (w - 1)/2;
  cy = obj_rect(2) + (h - 1)/2;
  target_pos = round([cx cy]);
  target_sz = round([w h]);
  
  % Compute discriminative object model
  surr_sz = floor(cfg.surr_win_factor * target_sz);
  surr_rect = pos2rect(target_pos, surr_sz); 
  obj_rect_surr = pos2rect(target_pos, target_sz, [size(img,2) size(img,1)]) - [surr_rect(1:2)-1, 0, 0];

  surr_win = getSubwindow(img, target_pos, surr_sz);
  [prob_lut, obj_histogram] = getForegroundBackgroundProbs(surr_win, obj_rect_surr, cfg.num_bins, cfg.bin_mapping);
  surr_prob_map = getForegroundProb(surr_win, prob_lut, cfg.bin_mapping);
  PM = getForegroundProb(img, prob_lut, cfg.bin_mapping);
  if cfg.scale_adaptive_thresholding
    adaptive_threshold = getAdaptiveThreshold(surr_prob_map, obj_rect_surr, cfg);
    PM(PM < adaptive_threshold) = 0;
  end
  img_sz = [size(img,2), size(img,1)];
  [features_horz, features_vert, reg_targets, hypotheses, int_scales] = extractScaled(PM, obj_rect, cfg, img_sz);
end

function [features_horz, features_vert, targets, candidates, int_scales] = extractScaled(I, gt, cfg, img_sz)
  scales = cfg.scale_augment_scales;
  
  gt_sz = gt(3:4);
  gt_pos = gt(1:2) + gt_sz./2;
  
  features_horz = [];
  features_vert = [];
  targets = [];
  candidates = [];
  int_scales = [];
  
  for i = 1:length(scales)
    scale = scales(i);
    hyp_rect = pos2rect(gt_pos, gt_sz .* scale);
    
    [fh, fv, t, c, s] = extractShifted(I, hyp_rect, gt, cfg, img_sz);
    features_horz = [features_horz; fh];
    features_vert = [features_vert; fv];
    targets = [targets; t];
    candidates = [candidates; c];
    int_scales = [int_scales; s];
  end
end

function [features_horz, features_vert, targets, hypotheses, int_scales] = extractShifted(I, hyp, gt, cfg, img_sz)
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
      surr_prob_map = getSubwindow(I, hyp_pos, surr_sz);
      
      gt_rect_surr = gt - [surr_rect(1:2)-1, 0, 0];
     
      [fh, fv, int_scale] = extractFeatures(surr_prob_map, hyp_rect_surr, canonical_sz);
      
      [sp_h, sp_w] = size(surr_prob_map);
      gt_int = canonical_sz .* gt_rect_surr ./ [sp_w sp_h sp_w sp_h];

      if false
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
        title(sprintf('iou: %.2f', overlap_ratios(hyp_rect_surr, gt_rect_surr)))
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

