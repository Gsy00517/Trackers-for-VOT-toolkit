function [ index ] = fastSub2Ind(sz, varargin)
%FASTSUB2IND Summary of this function goes here
%   Detailed explanation goes here
% after profiling, based on http://tipstrickshowtos.blogspot.co.at/2010/02/fast-replacement-for-sub2ind.html
% dim = length(sz);
dim = nargin - 1;
switch dim
  case 1
    index = varargin{1};
  case 2
    index = varargin{1} + (varargin{2}-1) .* sz(1);
  case 3
    index = varargin{1} + (varargin{2}-1) .* sz(1) + (varargin{3}-1) .* (sz(1) * sz(2));
  otherwise
    error('Not yet implemented');
end
end

