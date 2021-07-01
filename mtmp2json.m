%% Function to convert *.mtmp or *.etmp file to JSON encoded data
%
% author: Alexander MacLaren
% revised: 30/06/2021
%
% Usage:
%   J = mtmp2json() - a file open dialog is provided to open *.mtmp file
%       and to save *.json file. To be used at the command line or as a
%       standalone script.
%   J = mtmp2json(infileloc, outfileloc) - the strings or character vectors
%       infileloc and outfileloc respectively contain the locations of the
%       desired input (mtmp) and output (JSON) files.
% 
% Return value:
%   J is a MATLAB data structure containing the contents of the mtmp file
%   as received by jsonencode()
%
% Notes:
%   ETM profile files are also supported
%


function [J] = mtmp2json(varargin)

if (nargin==0)
    
    % open input file
    [flnm,pth,~] = uigetfile({'*.mtmp','MTM Profile Files (*.mtmp)';'*.etmp','ETM Profile Files (*.etmp)';'*.*','All Files (*.*)'});
    f = fopen([pth,flnm]);

elseif (nargin>2)
    error("Too many arguments (%d given)",nargin);

else 
    flnm = varargin{1};
    f = fopen(flnm);
end

mtm_etm = flnm(length(flnm)-3);
raw = fread(f, inf, 'uint8=>uint8');
data = raw';
fclose(f);

disp("Parsing file "+flnm+" ...");

c = uint64(length(data));
k = uint64(1);
i = 0;
ECRoptions = {'10','100','1k','10k','none'};

if (c>=39)
    if (all([1 0 0 0 0 0 0 0]==data(1:8))) % 3/4" ball
        J.Type = "3/4in ball";
        k = k + 8;
        if (mtm_etm == 'm') % MTM
            dmtm = [zeros(1,12), typecast(4.0, 'uint8'), typecast(20.0, 'uint8'), 0x01, 0x35]==data(k:k+30-1);
            dmtmold = zeros(1,29)==data(k:k+29-1);
            if (~all(dmtm)) % if doesn't conform to mtm format
                if (all(dmtmold)) % try old mtm format
                    k = k - 1;
                else % if also doesn't conform to old mtm format
                    e = find(~dmtm);
                    warning("Unexpected pattern in header at byte "+num2str(k+e(1)-1));
                end
            end
            k = k + 30;
        elseif (mtm_etm == 'e') % ETM
            detm = zeros(1,8)==data(k:k+8-1);
            if (~all(detm))
                e = find(~detm);
                warning("Unexpected pattern in header at byte "+num2str(k+e(1)-1));
            end
            k = k + 8;
        else
            error("File format of %s unsupported, supported formats are *.mtmp and *.etmp",flnm);
        end
    else
        error("File type unsupported - this version only supports 3/4"" ball profiles");
    end
    if (bitand(data(k),0x80)~=0)
        if (data(k+1)==0x01)
            data(k+1) = data(k); k = k + 1; % if more than 127 chars in descriptor, account for extra byte
        else
            warning("Unexpected description string header bytes 0x%x 0x%x at byte %d",data(k),data(k+1),k);
        end
    end
    if (c>=k+uint64(data(k)))
        J.Name = char(data(k+1:k+uint64(data(k))));
        k = k + 1 + uint64(data(k));
        numsteps = typecast(data(k:k+4-1),'uint32'); k = k + 4;
    else
        error("File shorter than expected string");
    end
else
    error("File shorter than expected header");
end

while (k<c)
    stephead = typecast(data(k:k+8-1),'uint64');
    k = k + 8;
    i = i + 1;
    switch (stephead)
        case 0x0000000100000000 % Traction
            disp ("Traction step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 8;
            J.Steps{i}.stepType = 'Traction';
            J.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            if (mtm_etm=='e') % ETM has no ECR
                d = [0x01, zeros(1,7)]==data(k:k+8-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after unloadAtEnd at byte "+num2str(k+e(1)-1)); end
                k = k + 8;
            else
                J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
                d = [zeros(1,3), 0x01, zeros(1,7)]==data(k:k+11-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
                k = k + 11;
            end
            J.Steps{i}.measDiscTrackRadBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.stepLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.stepSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected SRRstep header at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            ns = typecast(data(k:k+4-1),'uint32'); k = k + 4;
            for j = 1:ns
                d = [1, 0, 0, 0]==data(k:k+4-1);
                if (~all(d)); e = find(~d); warning("Unexpected SRRstep flag at byte "+num2str(k+e(1)-1)); end
                k = k + 4;
                J.Steps{i}.SRRsteps{j}.startSRR = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.SRRsteps{j}.endSRR = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.SRRsteps{j}.incrementSRR = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.SRRsteps{j}.numSteps = data(k); k = k + 1;
                loglin = typecast(data(k:k+8-1),'uint64');
                switch (loglin)
                    case 0x0000000000000000 % linear specifying size increments
                        J.Steps{i}.SRRsteps{j}.type = 'linear increments';
                    case 0x0000000100000000 % linear specifying number of steps
                        J.Steps{i}.SRRsteps{j}.type = 'linear # steps';
                    case 0x0000000101000000 % logarithmic
                        J.Steps{i}.SRRsteps{j}.type = 'logarithmic';
                    otherwise
                        error("Unable to interpret log/lin sequence at byte "+num2str(k))
                end
                disp([char(9),J.Steps{i}.SRRsteps{j}.type] + " SRR step "+num2str(j)+" of "+num2str(ns))
                k = k + 8;
            end
            
        case 0x0000000100000001 % Stribeck
            disp ("Stribeck step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 8;
            J.Steps{i}.stepType = 'Stribeck';
            J.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            if (mtm_etm=='e') % ETM has no ECR
                d = [0x01, zeros(1,7)]==data(k:k+8-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after unloadAtEnd at byte "+num2str(k+e(1)-1)); end
                k = k + 8;
            else
                J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
                d = [zeros(1,3), 0x01, zeros(1,7)]==data(k:k+11-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
                k = k + 11;
            end
            J.Steps{i}.measDiscTrackRadBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.stepLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.stepSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected speedStep header at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            ns = typecast(data(k:k+4-1),'uint32'); k = k + 4;
            for j = 1:ns
                d = [1, 0, 0, 0]==data(k:k+4-1);
                if (~all(d)); e = find(~d); warning("Unexpected speedStep flag at byte "+num2str(k+e(1)-1)); end
                k = k + 4;
                J.Steps{i}.speedSteps{j}.startSpeed = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.speedSteps{j}.endSpeed = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.speedSteps{j}.incrementSpeed = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.speedSteps{j}.numSteps = data(k); k = k + 1;
                loglin = typecast(data(k:k+8-1),'uint64');
                switch (loglin)
                    case 0x0000000000000000 % linear specifying size increments
                        J.Steps{i}.speedSteps{j}.type = 'linear increments';
                    case 0x0000000100000000 % linear specifying number of steps
                        J.Steps{i}.speedSteps{j}.type = 'linear # steps';
                    case 0x0000000101000000 % logarithmic
                        J.Steps{i}.speedSteps{j}.type = 'logarithmic';
                    otherwise
                        error("Unable to interpret log/lin sequence at byte "+num2str(k))
                end
                disp([char(9),J.Steps{i}.speedSteps{j}.type] + " speed step "+num2str(j)+" of "+num2str(ns))
                k = k + 8;
            end
            
        case 0x0000000100000002 % Timed
            disp ("Timed step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 8;
            J.Steps{i}.stepType = 'Timed';
            J.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            if (mtm_etm=='e') % ETM has no ECR
                d = [0x01, zeros(1,7)]==data(k:k+8-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after unloadAtEnd at byte "+num2str(k+e(1)-1)); end
                k = k + 8;
            else
                J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
                d = [zeros(1,3), 0x01, zeros(1,7)]==data(k:k+11-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
                k = k + 11;
            end
            J.Steps{i}.stepDurationSeconds = double(typecast(data(k:k+8-1),'uint64'))/10^7; k = k + 8;
            J.Steps{i}.logData = data(k)==0x01; k = k + 1;
            J.Steps{i}.logDataIntervalSeconds = double(typecast(data(k:k+8-1),'uint64'))/10^7; k = k + 8;
            J.Steps{i}.startTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.endTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.startLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.endLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.startSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.endSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.startSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.endSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            
        case {0x0000000100000003, 0x0000000100000008} % Mapper
            disp("Mapper step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 8;
            J.Steps{i}.stepType = 'Mapper';
            J.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            if (mtm_etm=='e') % ETM has no ECR
                d = [0x01, zeros(1,3)]==data(k:k+4-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after unloadAtEnd at byte "+num2str(k+e(1)-1)); end
                k = k + 4;
            else
                J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
                d = [zeros(1,3), 0x01, zeros(1,3)]==data(k:k+7-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
                k = k + 7;
            end
            J.Steps{i}.windowLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            
        case {0x0000000100000004, 0x0000000100000009} % Suspend
            disp("Suspend step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 9;
            J.Steps{i}.stepType = 'Suspend';
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            if (mtm_etm=='e') % ETM has no ECR
                d = [0x01, zeros(1,3)]==data(k:k+4-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after unloadAtEnd at byte "+num2str(k+e(1)-1)); end
                k = k + 4;
            else
                J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
                d = [zeros(1,3), 0x01, zeros(1,3)]==data(k:k+7-1);
                if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
                k = k + 7;
            end
            J.Steps{i}.stepText = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            
        case 0x000000010000000A % Bidirectional Traction
            disp ("Bidirectional Traction step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 8;
            J.Steps{i}.stepType = 'Bidirectional Traction';
            J.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
            d = [zeros(1,3), 0x01, zeros(1,7)]==data(k:k+11-1);
            if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
            k = k + 11;
            % J.Steps{i}.measDiscTrackRadBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.stepLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.stepSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected SRRstep header at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            ns = typecast(data(k:k+4-1),'uint32'); k = k + 4;
            for j = 1:ns
                d = [1, 0, 0, 0]==data(k:k+4-1);
                if (~all(d)); e = find(~d); warning("Unexpected SRRstep flag at byte "+num2str(k+e(1)-1)); end
                k = k + 4;
                J.Steps{i}.SRRsteps{j}.startSRR = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.SRRsteps{j}.endSRR = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.SRRsteps{j}.incrementSRR = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.SRRsteps{j}.numSteps = data(k); k = k + 1;
                loglin = typecast(data(k:k+8-1),'uint64');
                switch (loglin)
                    case 0x0000000000000000 % linear specifying size increments
                        J.Steps{i}.SRRsteps{j}.type = 'linear increments';
                    case 0x0000000100000000 % linear specifying number of steps
                        J.Steps{i}.SRRsteps{j}.type = 'linear # steps';
                    case 0x0000000101000000 % logarithmic
                        J.Steps{i}.SRRsteps{j}.type = 'logarithmic';
                    otherwise
                        error("Unable to interpret log/lin sequence at byte "+num2str(k))
                end
                disp([char(9),J.Steps{i}.SRRsteps{j}.type] + " SRR step "+num2str(j)+" of "+num2str(ns))
                k = k + 8;
            end
            
        case 0x000000010000000B % Bidirectional Stribeck
            disp ("Bidirectional Stribeck step "+num2str(typecast(data(k:k+4-1),'uint32'))+" of "+num2str(typecast(data(k+4:k+8-1),'uint32')));
            k = k + 8;
            J.Steps{i}.stepType = 'Bidirectional Stribeck';
            J.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            J.Steps{i}.tempCtrlEn = data(k)==0x01;
            if (data(k+1)==0x01); J.Steps{i}.tempCtrlProbe='lube'; else; J.Steps{i}.tempCtrlProbe='pot'; end
            k = k + 5;
            J.Steps{i}.tempCtrlTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.waitForTempBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.unloadAtEnd = data(k)==0x01; k = k + 1;
            J.Steps{i}.ECRoption = ECRoptions{1+data(k)}; k = k + 1;
            d = [zeros(1,3), 0x01, zeros(1,7)]==data(k:k+11-1);
            if (~all(d)); e = find(~d); warning("Unexpected pattern after ECRoption at byte "+num2str(k+e(1)-1)); end
            k = k + 11;
            % J.Steps{i}.measDiscTrackRadBeforeStep = data(k)==0x01; k = k + 1;
            J.Steps{i}.stepLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            J.Steps{i}.stepSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected speedStep header at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            ns = typecast(data(k:k+4-1),'uint32'); k = k + 4;
            for j = 1:ns
                d = [1, 0, 0, 0]==data(k:k+4-1);
                if (~all(d)); e = find(~d); warning("Unexpected speedStep flag at byte "+num2str(k+e(1)-1)); end
                k = k + 4;
                J.Steps{i}.speedSteps{j}.startSpeed = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.speedSteps{j}.endSpeed = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.speedSteps{j}.incrementSpeed = double(typecast(data(k:k+8-1),'uint64'))/(10^double(typecast(data(k+14:k+16-1),'uint16'))); k = k + 16;
                J.Steps{i}.speedSteps{j}.numSteps = data(k); k = k + 1;
                loglin = typecast(data(k:k+8-1),'uint64');
                switch (loglin)
                    case 0x0000000000000000 % linear specifying size increments
                        J.Steps{i}.speedSteps{j}.type = 'linear increments';
                    case 0x0000000100000000 % linear specifying number of steps
                        J.Steps{i}.speedSteps{j}.type = 'linear # steps';
                    case 0x0000000101000000 % logarithmic
                        J.Steps{i}.speedSteps{j}.type = 'logarithmic';
                    otherwise
                        error("Unable to interpret log/lin sequence at byte "+num2str(k))
                end
                disp([char(9),J.Steps{i}.speedSteps{j}.type] + " speed step "+num2str(j)+" of "+num2str(ns))
                k = k + 8;
            end
            
        otherwise
            error("Step header "+num2str(typecast(data(k-8:k-1),'uint32'))+" at byte "+num2str(k-8)+" unrecognised")
    end
end

str = jsonencode(J);
% PrettyPrint option not working until R2021a so this is the poor man's JSON beautifier (no indentation)
str = strrep(str, ',"', sprintf(',\n"'));
str = strrep(str, ':', ': ');
str = strrep(str, '{', sprintf('\n{\n'));
str = strrep(str, '}', sprintf('\n}\n'));
str = strrep(str, sprintf('}\n,'), '},');

if (nargin==2)
    flnm = varargin{2};
    f = fopen(flnm,'w');
else
    [flnm,pth,~] = uiputfile({'*.json','JavaScript Object Notation Files (*.json)';'*.*','All Files (*.*)'},'Save File',flnm(1:length(flnm)-5));
    f = fopen([pth,flnm],'w');
end

% write JSON string to file
fwrite(f, str(2:end));
fclose(f);
