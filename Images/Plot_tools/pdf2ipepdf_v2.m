%PDF2IPEPDF   Converts .pdf to IPE-editable .pdf.
%
%   PDF2IPEPDF(PathName) Converts all .pdf files in directory PathName to
%   IPE-editable .pdf-files. If PathName is omitted, a dialog box is
%   opened for selecting the files.
%
% Author: Jurgen van Zundert
% Date:   September 2016
%
%
%  v2:  Enable string replacement
%       (Michiel Beijen, 2017)
%

function [] = pdf2ipepdf_v2(PathName, stringOld, stringNew)

switch nargin
    case 0
        [FileNames,PathName] = uigetfile('*.pdf','MultiSelect','on');
        if isequal(FileNames,0)
            disp('No files were selected.');
            return
        end
        FileNames = cellstr(FileNames);
    otherwise
        % Check for missing delimiter.
        if ~strcmp(PathName(end),'\')
            PathName(end+1) = '\';
        end
        % Find all .pdf-files in pathName.
        files = dir([PathName,'*.pdf']);
        if isempty(files)
            disp('No files were converted.');
            return
        end
        FileNames = cell(1,length(files));
        for n = 1:length(files)
            FileNames{n} = files(n).name;
        end
end

% Conversion options.
% mergelevel = questdlg('Enter text merging level, 0 = none, 2 = aggressive:','Merging text','0','1','2','1');
% if strcmp(mergelevel,'')
%     return
% end
mergelevel = '1';

% Check IPE path.
IpePath = 'C:\Users\wout7\OneDrive - student.utwente.nl\ME - Master\Thesis\Ipe\ipe-7.2.10\bin';
if ~exist(IpePath,'dir')
    disp(IpePath);
    error('Incorrect path to IPE');
end

% Loop through files.
for n = 1:length(FileNames)
    FileName = FileNames{n};
    [~,name] = fileparts(FileName);
    
    % Convert PDF to IPE.
%     dos(['(cd /d ',IpePath,' && pdftoipe -merge ',mergelevel,' -math "',PathName,FileName,'")']);  %-literal or -math
    dos(['(cd /d ',IpePath,' && pdftoipe -merge ',mergelevel,' -literal "',PathName,FileName,'")']);  %-literal or -math
    
    % Replace user-defined strings (e.g. greek letters in math mode)
    for ii=1:length(stringOld)
        fileID = fopen([PathName,name,'.ipe'],'r');
        f = fread(fileID,'*char');
        fclose(fileID);
        f = strrep(f',stringOld{ii},stringNew{ii});
        fileID = fopen([PathName,name,'.ipe'],'w');
        fprintf(fileID,'%s',f);
        fclose(fileID);
    end
       
    %Remove white background fill
    if(1)
        fileID = fopen([PathName,name,'.ipe'],'r');
        f = fread(fileID,'*char');
        fclose(fileID);
        fill_begin = strfind(f','<path fill="1 1 1" fillrule="wind">'); %find fills
        Nfill = length(fill_begin);
        path_end = strfind(f','</path>');
        fill_end = zeros(Nfill,1);
        for ii=1:Nfill
            %Forward search for <path>...</path> blocks
            path_end_index = find(path_end>fill_begin(ii),1);
            fill_end(ii) = path_end(path_end_index);
        end
        fnew = f;
        try
            for ii=length(fill_begin)-2:length(fill_begin) %ii=1:length(fill_begin)
                %Backward removement of <path>...</path> blocks
                fnew = fnew([1:fill_begin(end-(ii-1))-1,fill_end(end-(ii-1))+7:end]);
            end
        catch
            %Insufficient background fills found
        end
        f = fnew;
        fileID = fopen([PathName,name,'.ipe'],'w');
        fprintf(fileID,'%s',f);
        fclose(fileID);
    end
    
    %Add stylesheet BASIC
    fileID = fopen([PathName,name,'.ipe'],'r');
    f = fread(fileID,'*char');
    fclose(fileID);
    f = strrep(f','<ipestyle>','<ipestyle name="basic">');
    fileID = fopen([PathName,name,'.ipe'],'w');
    fprintf(fileID,'%s',f);
    fclose(fileID);
    
    %Read layout line (papersize in IPE)
    fileID = fopen([PathName,name,'.ipe'],'r');
    fgets(fileID); fgets(fileID); fgets(fileID); fgets(fileID); 
    f_layout = fgets(fileID);
    fclose(fileID);
        
    %Update stylesheets
    dos(['(cd /d ',IpePath,' && ipescript update-styles "',PathName,name,'.ipe" >nul)']); 
    
    %Re-add layout line (papersize in IPE, removed after update stylesheet)
    fileID = fopen([PathName,name,'.ipe'],'r');
    f = fread(fileID,'*char');
    fclose(fileID);
    f = strrep(f','<ipestyle name="basic">',['<ipestyle name="basic">' f_layout]);
    fileID = fopen([PathName,name,'.ipe'],'w');
    fprintf(fileID,'%s',f);
    fclose(fileID);
        
    % Convert IPE to PDF.
    dos(['(cd /d ',IpePath,' && ipetoipe -pdf "',PathName,name,'.ipe" >nul)']);
    
    % Delete IPE-files
    delete([PathName,name,'.ipe']);
    delete([PathName,name,'.ipe.bak']);
    
end