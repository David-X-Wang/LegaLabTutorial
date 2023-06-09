
function [n,m] = month2(d)
%MONTH  Month of date. 
%       [N,M] = MONTH(D) returns the month in numeric and string form given
%       a serial date number or a date string, D.
%       
%       For example, [n,m] = month(728647) or [n,m] = month('19-Dec-1994')
%       returns n = 12 and m = Dec.
%
%       See also DATEVEC, DAY, YEAR.

if nargin < 1
  error('Please enter D.')
end
if isstr(d)
  d = datenum(d);
end

c = datevec(d(:));           % Generate date vectors

mths = ['Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';
        'Aug';'Sep';'Oct';'Nov';'Dec'];
n = c(:,2);              % Extract months
m = mths(c(:,2)+(c(:,2)==0),:);      % Month strings
if ~isstr(d)
  n = reshape(n,size(d));
end