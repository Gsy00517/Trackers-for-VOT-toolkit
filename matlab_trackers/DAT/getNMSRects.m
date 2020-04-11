function [top_rects, top_vote_scores, top_distractor_scores, top_distance_scores] = getNMSRects(prob_map_bg, prob_map_dist, obj_rect, overlap, score_frac, padded)
%GETNMSRECTS Perform NMS on given probability map
% Parameters:
%   prob_map      Object likelihood within search region
%   obj_sz        Currently estimated object size
%   scale         Optionally scale hypotheses (e.g. search smaller rects)
%   overlap       Overlap percentage of hypotheses
%   score_frac    return all boxes with score >= score_frac * highest-score
%   dist_map      Distance prior (e.g. cosine/hanning window)
%   include_inner Add extra inner rect scores to favor hypotheses with 
%                 highly confident center regions
% 
% Returns:
% top_rects       Rectangles
% top_vote_scores Scores based on the likelihood map
% top_dist_scores Scores based on the distance prior
  [height, width] = size(prob_map_bg);

  if ~exist('overlap','var'), overlap = .5; end
  if ~exist('score_frac','var'), score_frac = .25; end
  
  obj_sz = obj_rect(3:4);
  obj_ctr = obj_rect(1:2) + obj_sz ./ 2;

  % Integer sizes/offset for outer region
  prect_sz = floor(obj_sz);
  o_x = round(max([1, prect_sz(1)*0.2]));
  o_y = round(max([1, prect_sz(2)*0.2]));
  
  % Step size between rectangles
  stepx = max([1, round(prect_sz(1) .* (1-overlap))]);
  stepy = max([1, round(prect_sz(2) .* (1-overlap))]);

  % Positions (start with offset as we need to subtract the surrounding
  % region)
  posx = 1+o_x:stepx:width-prect_sz(1)-o_x;
  posy = 1+o_y:stepy:height-prect_sz(2)-o_y;

  % Position of the rectangles we will report (the "inner" rect)
  [x,y] = meshgrid(posx, posy);
  l = x(:);
  t = y(:);
  r = l + prect_sz(1);
  b = t + prect_sz(2);
  r(r > width) = width;
  b(b > height) = height;
  % Discard rects within padded region
  box_ctr = round([l+r, t+b]./2);
  is_padded = padded(fastSub2Ind([height, width],box_ctr(:,2), box_ctr(:,1)));
  l(is_padded) = [];
  r(is_padded) = [];
  t(is_padded) = [];
  b(is_padded) = [];
  box_ctr(is_padded,:) = [];
  boxes = [l, t, r-l, b-t];
  % Linear indices for integral image lookup
  l = boxes(:,1); t = boxes(:,2);
  h = height+1;
  w = width+1;
  bl = fastSub2Ind([h w],b,l);
  br = fastSub2Ind([h w],b,r);
  tl = fastSub2Ind([h w],t,l);
  tr = fastSub2Ind([h w],t,r);

  % Surrounding rectangles
  ls = l-o_x;
  ts = t-o_y;
  rs = r+o_x;
  bs = b+o_y;
  % Linear indices
  bl_surrounding = fastSub2Ind([h w],bs,ls);
  br_surrounding = fastSub2Ind([h w],bs,rs);
  tl_surrounding = fastSub2Ind([h w],ts,ls);
  tr_surrounding = fastSub2Ind([h w],ts,rs);
  
  % Inner box (center where we expect high likelihoods)
  li = l+o_x;
  ti = t+o_y;
  ri = r-o_x;
  bi = b-o_y;
  boxes_inner = [li, ti, ri-li, bi-ti];
  % Linear indices
  bl_inner = fastSub2Ind([h w],bi,li);
  br_inner = fastSub2Ind([h w],bi,ri);
  tl_inner = fastSub2Ind([h w],ti,li);
  tr_inner = fastSub2Ind([h w],ti,ri);
  
  num_px = prod(prect_sz);
  num_px_inner = prod(boxes_inner(1,3:4));

  % Integral image
  intProbMap = integralImage(prob_map_bg);
  intDistMap = integralImage(prob_map_dist);
  % "inner prob map scores"
  ip_scores = intProbMap(br) - intProbMap(bl) - intProbMap(tr) + intProbMap(tl);
  ipi_scores = intProbMap(br_inner) - intProbMap(bl_inner) - intProbMap(tr_inner) + intProbMap(tl_inner);
  idi_scores = intDistMap(br_inner) - intDistMap(bl_inner) - intDistMap(tr_inner) + intDistMap(tl_inner);
  sp_scores = intProbMap(br_surrounding) - intProbMap(bl_surrounding) - intProbMap(tr_surrounding) + intProbMap(tl_surrounding);
  vp_scores = (2.*ip_scores - sp_scores) ./ num_px + ipi_scores ./ num_px_inner;
  vd_scores = idi_scores ./ num_px_inner; %id_scores;
  
  % Distance of boxes to predicted location
  dist = sqrt(sum(bsxfun(@minus, box_ctr, obj_ctr).^2, 2));
  distance_scores = exp(-dist.^2 ./ (2 * (sqrt(sum(obj_sz.^2)))^2));
  
  rank_scores = vp_scores .* distance_scores;

  top_rects = [];
  top_vote_scores = [];
  top_distractor_scores = [];
  top_distance_scores = [];
  [ms, midx] = max(rank_scores);
  best_score = ms;
  while ms > score_frac*best_score
    % Discard all highly overlapping boxes
    ious = intersectionOverUnion(boxes(midx,:), boxes);
    discard = ious > 0.1;
    top_rects = [top_rects; boxes(midx,:)];                            %#ok
    top_vote_scores = [top_vote_scores; vp_scores(midx)];              %#ok
    top_distractor_scores = [top_distractor_scores; vd_scores(midx)];  %#ok
    top_distance_scores = [top_distance_scores; distance_scores(midx)];%#ok
    % Remove overlapping boxes...
    boxes(discard,:) = [];
    vp_scores(discard) = [];
    vd_scores(discard) = [];
    distance_scores(discard) = [];
    rank_scores(discard) = [];

    [ms, midx] = max(rank_scores);
  end
end

function [Integral] = integralImage(probMap)
  outputSize = size(probMap) + 1;
  Integral = zeros(outputSize);
  Integral(2:end, 2:end) = cumsum(cumsum(double(probMap),1),2);
end

% target_rect Single 1x4 rect
function iou = intersectionOverUnion(target_rect, candidates)
%   assert(size(target_rect,1) == 1)
  iou = zeros(size(candidates,1),1);
  
  % Matlab's rectint uses repmat and takes usually twice as long
  % 300 rects vs 1 rect: rectint: 0.003 vs fast: 0.0015
%   inA = rectint(candidates,target_rect);
  inA = fastRectInt(candidates, target_rect);
  
  
  % Explicit multiplication only takes 0.5-0.9 of the runtime of using prod
  unA = candidates(:,3).*candidates(:,4) + target_rect(3)*target_rect(4) - inA;
%   unA = prod(target_rect(3:4)) + prod(candidates(:,3:4),2) - inA;
  valid = unA > 0;
  iou(valid) = inA(valid) ./ unA(valid);
end

