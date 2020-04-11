function state = motionUpdateKalman(state)
%MOTIONUPDATEKALMAN There's no easy way to have a anonymous function
%invoking correct without returning a value.
pos = correct(state.kalman_filter.position, state.target_pos_history(end,:));
% sz = correct(state.kalman_filter.size, state.target_sz_history(end,:));
state.target_pos_history(end,:) = pos;
% state.target_sz_history(end,:) = sz;
end

