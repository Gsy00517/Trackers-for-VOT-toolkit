function pred_boxes = predictModel(Xh, Xv, ex_boxes, model)

% Predict regression targets
Yh = bsxfun(@plus, Xh*model.BetaH(1:end-1, :), model.BetaH(end, :));
Yv = bsxfun(@plus, Xv*model.BetaV(1:end-1, :), model.BetaV(end, :));
% Build regressed rectangle (cx, cy, w, h)
Y = [Yh(:,1), Yv(:,1), Yh(:,2), Yv(:,2)];
% Invert whitening transformation
Y = bsxfun(@plus, Y*model.T_inv, model.mu);

switch model.regression_type
    
  case 'plain'
    % Regression target is [cx, cy, w, h]
    centers = Y(:,1:2);
    dim = Y(:,3:4);
    pred_boxes = [centers - dim./2, dim];
    
  case 'change'
    % Regression target is [cx, cy, fw, fh]
    centers = Y(:,1:2);
    chg = Y(:,3:4);
    dim = ex_boxes(:,3:4) .* chg;
    pred_boxes = [centers - dim./2, dim];
      
  otherwise
    error('Regression target not supported')
end

