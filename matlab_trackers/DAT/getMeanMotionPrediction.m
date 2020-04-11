function [pred_pos, pred_sz] = getMeanMotionPrediction(state, max_num_frames)
  if ~exist('max_num_frames','var')
    max_num_frames = 5;
  end
  offset_pos = getMeanOffset(state.target_pos_history, max_num_frames);
  pred_pos = state.target_pos_history(end,:) + offset_pos;
  
  offset_sz = getMeanOffset(state.target_sz_history, max_num_frames);
  pred_sz = state.target_sz_history(end,:) + offset_sz;
end


function pred = getMeanOffset(values, maxNumFrames)
  if isempty(values)
    pred = [0,0];
  else
    if size(values,1) < 3
      pred = [0,0];
    else
      maxNumFrames = maxNumFrames + 2;
     
      A1 = 0.8;
      A2 = -1;
      V = values(max(1,end-maxNumFrames):end,:);
      P = zeros(size(V,1)-2, size(V,2));
      for i = 3:size(V,1)
        P(i-2,:) = A1 .* (V(i,:) - V(i-2,:)) + A2 .* (V(i-1,:) - V(i-2,:));
      end
      
      pred = mean(P,1);
    end
  end
end