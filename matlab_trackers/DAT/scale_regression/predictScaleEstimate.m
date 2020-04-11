function scale = predictScaleEstimate(Xh, Xv, model)
X = [Xh, Xv];
% Predict regression targets
Y = bsxfun(@plus, X*model.Beta(1:end-1, :), model.Beta(end, :));

% Invert whitening transformation
Y = bsxfun(@plus, Y*model.T_inv, model.mu);

% pred_centers = Y(:,1:2);
scale = Y;
end

