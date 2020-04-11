function pred_centers = predictCenterRefinement(Xh, Xv, model)
X = [Xh, Xv];
% Predict regression targets
Y = bsxfun(@plus, X*model.Beta(1:end-1, :), model.Beta(end, :));
% Build regressed rectangle (cx, cy, w, h)
Y = [Y(:,1), Y(:,2)];
% Invert whitening transformation
Y = bsxfun(@plus, Y*model.T_inv, model.mu);

pred_centers = Y(:,1:2);
end

