function [state, pos, sz] = motionPredictionKalman(state)
%MOTIONPREDICTIONKALMAN 
pos = predict(state.kalman_filter.position);
% sz = predict(state.kalman_filter.size);
sz = state.target_sz_history(end,:);
end

