function rounded = round_base(num, base)
%ROUND_BASE Round num to the given base, e.g. 5: 6=>5, 9=>10
rounded = fix(base*round(num/base));
end

