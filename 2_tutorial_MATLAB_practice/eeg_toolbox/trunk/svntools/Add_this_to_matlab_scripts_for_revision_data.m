
function Add_this_to_matlab_scripts_for_revision_data

%
%
% This function sets keyword properties for all m-files in the path
% and returns instructions on how to automatically include 
% revision data in scripts managed by subversion.
%
% See also Add_this_to_matlab_scripts_for_revision_data.readme
%

%  C Kovach 2011
%
% ----------- SVN REVISION INFO ------------------
% $URL$     
% $Revision$
% $Date$
% $Author$
% ------------------------------------------------
%


!svn propset svn:keywords "Author Date Revision URL Id" *.m

com = sprintf('!svn propset svn:keywords "" %s.readme',mfilename);
eval(com)

fid = fopen(sprintf('%s.readme',mfilename),'r');

str = char(fread(fid)');
tok = regexp(str,'%\n% -.*-\n%','match');
fprintf('\n\nAdd the following block of comment to your script(s):\n\n%s\n\n',tok{1});


