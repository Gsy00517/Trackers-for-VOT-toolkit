function [ area ] = fastRectInt(A, B)
%FASTRECTINT Summary of this function goes here
%   Detailed explanation goes here
leftA = A(:,1);
bottomA = A(:,2);
rightA = leftA + A(:,3);
topA = bottomA + A(:,4);

leftB = B(:,1);
bottomB = B(:,2);
rightB = leftB + B(:,3);
topB = bottomB + B(:,4);


leftI = max(leftA, leftB);
rightI = min(rightA, rightB);
topI = min(topA, topB);
bottomI = max(bottomA, bottomB);
width = max(0, rightI - leftI);
height = max(0, topI - bottomI);
area = width .* height;

end

