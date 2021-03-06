% TExAS Data Analysis

% This program plots stress/strain curves from calculations of stresses and
% strains from raw data, acquired from an excel file output by the TExAS Device

%Code by Thomas Leahy and Elizabeth Shih

clear all; close all; clc;
%Commit Test
%% Filter Design

%Creating a "taps"-tap averaging filter
taps = 10;
B = 1/taps;
B = repmat(B,1,taps);
A = 1;
% to filter data vector X, use command "y = filter(B,A,X);"


%% User Input
currentFolder = pwd(); %% Stores current folder to restore later

folder_name = uigetdir; %%Gets input folder name from the user (through folder explorer GUI)
allSubFolders = genpath(folder_name); %%File path for all subfolders (including empty ones) of the user input folder


% Construct a questdlg with three options
choice = questdlg('What graphs would you like to plot?', ...
    'TRIAX Data Analysis', ...
    'All graphs!','Only the stress/strain - diff Ext ones','None!','None!');
% Handle response
switch choice
    case 'All graphs!'
        disp('Plotting all graphs...')
        graphs = 2;
    case 'Only the stress/strain - diff Ext ones'
        disp('Plotting only the stress/strain - diff Ext ones....');
        graphs = 1;
    case 'None!'
        disp('Fine then! Have a good freakin day. Thanks for wasting my time.')
        graphs = 0;
        return;
end

% Parse into a cell array.
remain = allSubFolders;
listOfFolderNames = {};
while true
    [singleSubFolder, remain] = strtok(remain, ';');
    if isempty(singleSubFolder)
        break; %Do not add empty folders to this list
    end
    listOfFolderNames = [listOfFolderNames singleSubFolder];
end
numberOfFolders = length(listOfFolderNames);

%This picks out the data by finding the folders that have the second to
%last letter be 'T', as in T1,T2,etc.
%Perhaps there is a better way to do this that won't break as easily.
listOfDataFolders = {};
for i=1:numberOfFolders
    myStr = char(listOfFolderNames(i));
    if strcmp((myStr(length(myStr)-1:length(myStr)-1)), 'T')
        listOfDataFolders = [listOfDataFolders myStr];
    end
end
numberOfDataFolders = length(listOfDataFolders);

%% Simple Stress/Strain Plots

%listOfDataFolders contains an array of strings of all folders containing
%data that needs to be analyzed. Doesn't matter if it is within a protocol
%folder or not, it will be in this array.

%First need to tell if the data is a uniaxial or biaxial test

strArray = char(listOfDataFolders); %%Converts cell array to string array
lastSlash = zeros(1,numberOfDataFolders);
numOfXs = zeros(1,numberOfDataFolders);
unibi_testType = testType.Uniaxial_Tension;
unibi_testType = repmat(unibi_testType,1, numberOfDataFolders);
finalStr = cell(numberOfDataFolders, 1);
for i = 1:numberOfDataFolders
    lastSlash(i) = max(strfind(strArray(i,:), '\'));
    myStr = strArray(i,(lastSlash(i)+1):length(strArray(i,:)));
    finalStr(i) = cellstr(strArray(i,(lastSlash(i)+1):length(strArray(i,:))));
    numOfXs(i) = length(strfind(char(finalStr(i)), 'X'));
    if(numOfXs(i) == 1)
        if((myStr(3) == 'C') || (myStr(3) == 'T'))
            unibi_testType(i) = testType.Uniaxial_Tension;
        else
            unibi_testType(i) = testType.Uniaxial_Shear;
        end
    end
    if(numOfXs(i) == 2)
        unibi_testType(i) = testType.Biaxial;
    end
end

%the array unibi_testType now has whatever type of test occured
%now we can construct specific plotting for that respective test

%Pin area calculation for stress calculation
pinD = .00225; %Pin diameter is 2.25 mm
pinA = 9*(pi*((pinD/2)^2)); %9 pins


for i = 1: numberOfDataFolders
    testName = char(finalStr(i));
    clear cycleString;
    
    cd(strArray(i,:));
    files = dir('*.csv'); %lists all csv files from subdirectory
    outs = cell(1,(numel(files)/2)); %Creates cell matrix for every _SIMP file
    
    y = 1;
    for x = 2:2:numel(files)
        outs{y}=csvread(files(x).name, 1,1);
        y = y + 1;
    end
    %outs is a cell array that contains all csv data from all cycles (the
    %SIMP versions of the data)
    
    %Opens figure titled after the test name
    h(i) = figure('Name', testName);
    
    if unibi_testType(i) == testType.Uniaxial_Tension
        %Plot graphs for uniaxial tension/compression tests
        for x = 1:length(outs)
            cycleData = cell2mat(outs(x)); %Puts cycle data into a matrix
            cycleDataSize = size(cycleData);
            strainData = cycleData(:,2);
            forceData = cycleData(:,min(cycleDataSize));
            stressData = forceData./pinA;
            stressData = stressData./1000;
            
            stressData = filter(B,A,stressData);
            
            
            hold on;
            plot(strainData,stressData, 'LineWidth',2);
            
            cycleString(x,:) = ['Cycle ',num2str(x)];
            
            if(x == length(outs))
                %Plotted everything! Let's format!
                xlabel('Extension Ratio');
                
                ylabel('Tensile Stress (kPa)');
                legend(cycleString, 'Location', 'southeast');
                hold off;
            end
            
            if graphs == 2
                zeroLoad(i,x) = mean(stressData(1:15));
                
                zeroStrainindex = find((stressData(i,:)>-20) && (stressData(i,:)<20), 1);
                zeroStrainPoint(i,x) = strainData(i,zeroStrainindex);
            end
        end
    end
    
    if unibi_testType(i) == testType.Uniaxial_Shear
        %Plot graphs for uniaxial tension/compression tests
        for x = 1:length(outs)
            cycleData = cell2mat(outs(x)); %Puts cycle data into a matrix
            cycleDataSize = size(cycleData);
            strainData = cycleData(:,2);
            strainData = atand(strainData);
            forceData = cycleData(:,min(cycleDataSize));
            stressData = forceData./pinA;
            stressData = stressData./1000;
            
            stressData = filter(B,A,stressData);
            
            hold on;
            plot(strainData,stressData, 'LineWidth',2);
            
            cycleString(x,:) = ['Cycle ',num2str(x)];
            
            if(x == length(outs))
                %Plotted everything! Let's format!
                xlabel('Shear Angle (Degrees)');
                ylabel('Shear Stress (kPa)');
                legend(cycleString, 'Location', 'southeast');
                hold off;
            end
            
            if graphs == 2
                zeroLoad(i,x) = mean(stressData(1:15));
                
                zeroStrainindex = find((stressData(i,:)>-20) && (stressData(i,:)<20), 1);
                zeroStrainPoint(i,x) = strainData(i,zeroStrainindex);
            end
        end
    end
    
    if unibi_testType(i) == testType.Biaxial
        %Plot graphs for uniaxial shear tests
        for x = 1:length(outs)
            cycleData = cell2mat(outs(x)); %Puts cycle data into a matrix
            cycleDataSize = size(cycleData);
            strainData_1 = cycleData(:,2);
            strainData_2 = cycleData(:,3);
            forceData_1 = cycleData(:, min(cycleDataSize) - 1);
            forceData_2 = cycleData(:, min(cycleDataSize));
            
            secondX = max(strfind(testName, 'X'));
            firstlegend = testName(1:3);
            secondlegend = testName(secondX:secondX+2);
            
            cycleString(2*(x-1)+1,:) = [firstlegend,' - Cycle ', num2str(x)];
            cycleString(2*(x-1)+2,:) = [secondlegend, ' - Cycle ', num2str(x)];
            
            stressData_1 = forceData_1./pinA;
            stressData_2 = forceData_2./pinA;
            stressData_1 = stressData_1./1000;
            stressData_2 = stressData_2./1000;
            
            stressData_1 = filter(B,A,stressData_1);
            stressData_2 = filter(B,A,stressData_2);
            
            hold on;
            plot(strainData_1,stressData_1, 'LineWidth',2);
            plot(strainData_2,stressData_2, 'LineWidth',2);
            
            if(x == length(outs)) %Plot legend only on the first graph
                xlabel('Extension Ratio');
                ylabel('Tensile Stress (kPa)');
                legend(cycleString, 'Location', 'southeast');
                hold off;
            end
            
            if graphs == 2
                zeroLoad(i,2*(x-1)+1) = mean(stressData_1(1:15));
                zeroLoad(i,2*(x-1)+2) = mean(stressData_2(1:15));
                
                zeroStrainindex1 = find((stressData_1(i,:)>-20) && (stressData_1(i,:)<20), 1);
                zeroStrainindex2 = find((stressData_2(i,:)>-20) && (stressData_2(i,:)<20), 1);
                
                if isempty(zeroStrainindex1) || isempty(zeroStrainindex2)
                else
                    zeroStrainPoint(i,2*(x-1)+1) = strainData_1(i,zeroStrainindex1);
                    zeroStrainPoint(i,2*(x-1)+2) = strainData_2(i,zeroStrainindex2);
                end
            end
        end
    end
end

%Reset Folder
cd(folder_name);

lastSlash = max(strfind(folder_name, '\'));
desiredFileName = folder_name(lastSlash+1:length(folder_name));
desiredFileName = strcat(folder_name, '/', desiredFileName, '_BasicStressStrainCurves');

savefig(h,desiredFileName);
close all;
%Save stress/strain graphs and close them

%% Now we begin our lowest point, zero load plots

if graphs == 2
    
    for i = 1: numberOfDataFolders
        clear index;
        
        testName = char(finalStr(i));
        testName = [testName, '_StartingStressGraph'];
        h(i) = figure('Name', testName);
        
        if unibi_testType(i) == testType.Uniaxial_Tension
            index = 1:find(zeroLoad(i,:) == 0, 1) - 1;
            scatter(index,zeroLoad(i,1:max(index)));
            
            firstlegend = testName(1:3);
            legend(firstlegend);
            
        end
        
        if unibi_testType(i) == testType.Uniaxial_Shear
            index = 1:find(zeroLoad(i,:) == 0, 1)-1;
            scatter(index,zeroLoad(i,1:max(index)));
            
            firstlegend = testName(1:3);
            legend(firstlegend);
        end
        
        if unibi_testType(i) == testType.Biaxial
            clear zeroLoad1 zeroload2;
            
            ind = 1;
            if isempty(find(zeroLoad(i,1:5) == 0, 1))
                index = 1:length(zeroLoad(i,:))/2;
            else
                index = 1:((find(zeroLoad(i,:) == 0, 1)-1)/2);
            end
            for x = 1:2:length(zeroLoad(i,:))
                zeroLoad1(ind) = zeroLoad(i,x);
                zeroLoad2(ind) = zeroLoad(i,x+1);
                ind = ind + 1;
            end
            scatter(index,zeroLoad1);
            hold on;
            scatter(index,zeroLoad2);
            hold off;
            
            secondX = max(strfind(testName, 'X'));
            firstlegend = testName(1:3);
            secondlegend = testName(secondX:secondX+2);
            legend(firstlegend, secondlegend);
        end
        
        title('Lowest Stress Graph');
        xlabel('Cycle');
        ylabel('Stress (kPa)');
    end
    
    lastSlash = max(strfind(folder_name, '\'));
    desiredFileName = folder_name(lastSlash+1:length(folder_name));
    desiredFileName = strcat(folder_name, '/', desiredFileName, '_LowestStressPlots');
    savefig(h,desiredFileName);
    close all;
    
end
%% Graph point at which stretch equals 0.

if graphs == 2
    
    for i = 1: numberOfDataFolders
        clear index;
        
        testName = char(finalStr(i));
        testName = [testName, '_ZeroStressGraph'];
        h(i) = figure('Name', testName);
        
        if unibi_testType(i) == testType.Uniaxial_Tension
            index = 1:find(zeroStrainPoint(i,:) == 0, 1) - 1;
            scatter(index,zeroStrainPoint(i,1:max(index)));
            
            firstlegend = testName(1:3);
            legend(firstlegend);
            
            ylabel('Extension Ratio');
        end
        
        if unibi_testType(i) == testType.Uniaxial_Shear
            index = 1:find(zeroStrainPoint(i,:) == 0, 1)-1;
            scatter(index,zeroStrainPoint(i,1:max(index)));
            
            firstlegend = testName(1:3);
            legend(firstlegend);
            
            ylabel('Shear Angle (Degrees)');
        end
        
        if unibi_testType(i) == testType.Biaxial
            clear zeroLoad1 zeroload2;
            
            ind = 1;
            if isempty(find(zeroStrainPoint(i,1:5) == 0, 1))
                index = 1:length(zeroLoad(i,:))/2;
            else
                index = 1:((find(zeroStrainPoint(i,:) == 0, 1)-1)/2);
            end
            for x = 1:2:length(zeroLoad(i,:))
                zeroStrainPoint1(ind) = zeroStrainPoint(i,x);
                zeroStrainPoint2(ind) = zeroStrainPoint(i,x+1);
                ind = ind + 1;
            end
            scatter(index,zeroStrainPoint1);
            hold on;
            scatter(index,zeroStrainPoint2);
            hold off;
            
            secondX = max(strfind(testName, 'X'));
            firstlegend = testName(1:3);
            secondlegend = testName(secondX:secondX+2);
            legend(firstlegend, secondlegend);
            
            ylabel('Extension Ratio');
        end
        
        title('Zero Stress Point Graph');
        xlabel('Cycle');
        
    end
    
    lastSlash = max(strfind(folder_name, '\'));
    desiredFileName = folder_name(lastSlash+1:length(folder_name));
    desiredFileName = strcat(folder_name, '/', desiredFileName, '_ZeroStressPlots');
    savefig(h,desiredFileName);
    close all;
    
end

%% Now we begin our same deformation, different extension graphs

%David - Did we only want biax folders for this or all folders with same
%test type?

%First we need to sort folders into their parent folder groupings

i = 1;
x = 1;
pSepFolds = cell(1);
for s=1:numberOfDataFolders
    if s== 1
        pSepFolds(1,1) = listOfDataFolders(1);
    else
        strPrev = listOfDataFolders{s-1};
        strPrev = strPrev(1:strfind(strPrev,finalStr{s-1})-1);
        str = listOfDataFolders{s};
        str = str(1:strfind(str,finalStr{s})-1);
        if ~strcmp(str,strPrev)
            i = i + 1;
            x = 1;
            pSepFolds(i,x) = listOfDataFolders(s);
        else
            x = x + 1;
            pSepFolds(i,x) = listOfDataFolders(s);
        end
    end
end

%Generate True/False Table for all folders

identArray = zeros([size(pSepFolds) 12]);

for s = 1:size(pSepFolds,1)
    for x = 1:size(pSepFolds,2);
        if ~isempty(pSepFolds{s,x})
            thisStr = pSepFolds{s,x};
            if(~isempty(strfind(thisStr,'X1T')))
                identArray(s,x,1) = 1;
            end
            if(~isempty(strfind(thisStr,'X1C')))
                identArray(s,x,2) = 1;
            end
            if(~isempty(strfind(thisStr,'X12S')))
                identArray(s,x,3) = 1;
            end
            if(~isempty(strfind(thisStr,'X13S')))
                identArray(s,x,4) = 1;
            end
            if(~isempty(strfind(thisStr,'X21S')))
                identArray(s,x,5) = 1;
            end
            if(~isempty(strfind(thisStr,'X2T')))
                identArray(s,x,6) = 1;
            end
            if(~isempty(strfind(thisStr,'X2C')))
                identArray(s,x,7) = 1;
            end
            if(~isempty(strfind(thisStr,'X23S')))
                identArray(s,x,8) = 1;
            end
            if(~isempty(strfind(thisStr,'X31S')))
                identArray(s,x,9) = 1;
            end
            if(~isempty(strfind(thisStr,'X32S')))
                identArray(s,x,10) = 1;
            end
            if(~isempty(strfind(thisStr,'X3T')))
                identArray(s,x,11) = 1;
            end
            if(~isempty(strfind(thisStr,'X3C')))
                identArray(s,x,12) = 1;
            end
        end
    end
end

ind = 1;
indArray = [];
for s = 1:size(pSepFolds,1)
    for x = 1:size(pSepFolds,2)
        if ~isempty(pSepFolds{s,x})
            for y = x+1:size(pSepFolds,2)
                if isequal(identArray(s,x,:),identArray(s,y,:))
                    ind2 = (y-x)+ind;
                    indArray = [indArray; [ind ind2]];
                end
            end
            ind = ind + 1;
        end
    end
end

%indArray is a ?-by-2 matrix. Each row represents two graphs that need to
%be plotted on the same one. These indeces are referring to the original
%ones used in part one.

clear h;
for i = 1:size(indArray,1)
    cd(strArray(indArray(i,1),:));
    files1 = dir('*.csv'); %lists all csv files from subdirectory
    outs1 = cell(1,(numel(files)/2)); %Creates cell matrix for every _SIMP file
    
    y = 1;
    for x = 2:2:numel(files)
        outs1{y}=csvread(files1(x).name, 1,1);
        y = y + 1;
    end
    
    cd(strArray(indArray(i,2),:));
    files2 = dir('*.csv'); %lists all csv files from subdirectory
    outs2 = cell(1,(numel(files)/2)); %Creates cell matrix for every _SIMP file
    
    y = 1;
    for x = 2:2:numel(files)
        outs2{y}=csvread(files2(x).name, 1,1);
        y = y + 1;
    end
    
    %outs1 and outs2 is a cell array that contains all csv data from all cycles (the
    %SIMP versions of the data)
    
    figInd = 1;
    if unibi_testType(indArray(i,1)) == testType.Uniaxial_Tension
        %Plot graphs for uniaxial tension/compression tests
        for x = 1:length(outs1)
            cycleData1 = cell2mat(outs1(x)); %Puts cycle data into a matrix
            cycleDataSize1 = size(cycleData1);
            strainData1 = cycleData(:,2);
            forceData1 = cycleData(:,min(cycleDataSize1));
            stressData1 = forceData1./pinA;
            stressData1 = stressData1./1000;
            
            cycleData2 = cell2mat(outs2(x)); %Puts cycle data into a matrix
            cycleDataSize2 = size(cycleData2);
            strainData2 = cycleData(:,2);
            forceData2 = cycleData(:,min(cycleDataSize2));
            stressData2 = forceData2./pinA;
            stressData2 = stressData2./1000;
            
            stressData1 = filter(B,A,stressData1);
            stressData2 = filter(B,A,stressData2);
            
            legendVal1 = strfind(finalStr(indArray(i,1)), '_');
            legendVal1 = legendVal1{1};
            legendVal = finalStr(indArray(i,1));
            legendVal = legendVal{1};
            legendVal1 = legendVal(1:legendVal1(2)-1);
            
            legendVal2 = strfind(finalStr(indArray(i,2)), '_');
            legendVal2 = legendVal2{1};
            legendVal = finalStr(indArray(i,2));
            legendVal = legendVal{1};
            legendVal2 = legendVal(1:legendVal2(2)-1);
            
            legendData = [legendVal1 legendVal2];
            
            undVals = strfind(finalStr(indArray(i,1)), '_');
            undVals = undVals{1};
            name = finalStr(indArray(i,1));
            name = name{1};
            name = [name(1:undVals(1)-1) ' - Trial ' num2str(x)];
            
            h(figInd) = figure('Name', name);
            figInd = figInd + 1;
            
            hold on;
            plot(strainData1,stressData1, 'LineWidth',2);
            plot(strainData2,stressData2, 'LineWidth',2);
            hold off;
            
            xlabel('Extension Ratio');
            ylabel('Tensile Stress (kPa)');
            legend({legendData}, 'Location', 'southeast','Interpreter', 'none');
        end
    end
    
    if unibi_testType(indArray(i,1)) == testType.Uniaxial_Shear
        %Plot graphs for uniaxial tension/compression tests
        for x = 1:length(outs)
            cycleData1 = cell2mat(outs1(x)); %Puts cycle data into a matrix
            cycleDataSize1 = size(cycleData1);
            strainData1 = cycleData1(:,2);
            strainData1 = atand(strainData1);
            forceData1 = cycleData1(:,min(cycleDataSize1));
            stressData1 = forceData1./pinA;
            stressData1 = stressData1./1000;
            
            cycleData2 = cell2mat(outs2(x)); %Puts cycle data into a matrix
            cycleDataSize2 = size(cycleData2);
            strainData2 = cycleData2(:,2);
            strainData2 = atand(strainData2);
            forceData2 = cycleData2(:,min(cycleDataSize2));
            stressData2 = forceData2./pinA;
            stressData2 = stressData2./1000;
            
            stressData1 = filter(B,A,stressData1);
            stressData2 = filter(B,A,stressData2);
            
            legendVal1 = strfind(finalStr(indArray(i,1)), '_');
            legendVal1 = legendVal1{1};
            legendVal = finalStr(indArray(i,1));
            legendVal = legendVal{1};
            legendVal1 = legendVal(1:legendVal1(2)-1);
            
            legendVal2 = strfind(finalStr(indArray(i,2)), '_');
            legendVal2 = legendVal2{1};
            legendVal = finalStr(indArray(i,2));
            legendVal = legendVal{1};
            legendVal2 = legendVal(1:legendVal2(2)-1);
            legendData = [legendVal1 legendVal2];
            
            undVals = strfind(finalStr(indArray(i,1)), '_');
            undVals = undVals{1};
            name = finalStr(indArray(i,1));
            name = name{1};
            name = [name(1:undVals(1)-1) ' - Trial ' num2str(x)];
            
            h(figInd) = figure('Name', name);
            figInd = figInd + 1;
            
            hold on;
            plot(strainData1,stressData1, 'LineWidth',2);
            plot(strainData1,stressData1, 'LineWidth',2);
            hold off;
            
            xlabel('Extension Ratio');
            ylabel('Shear Stress (kPa)');
            legend({legendData}, 'Location', 'southeast','Interpreter', 'none');
            
        end
    end
    
    if unibi_testType(indArray(i,1)) == testType.Biaxial
        %Plot graphs for uniaxial shear tests
        for x = 1:length(outs1)
            
            cycleData1 = cell2mat(outs1(x)); %Puts cycle data into a matrix
            cycleDataSize1 = size(cycleData1);
            strainData1_1 = cycleData1(:,2);
            strainData1_2 = cycleData1(:,3);
            forceData1_1 = cycleData1(:, min(cycleDataSize1) - 1);
            forceData1_2 = cycleData1(:, min(cycleDataSize1));
            stressData1_1 = forceData1_1./pinA;
            stressData1_2 = forceData1_2./pinA;
            stressData1_1 = stressData1_1./1000;
            stressData1_2 = stressData1_2./1000;
            
            cycleData2 = cell2mat(outs2(x)); %Puts cycle data into a matrix
            cycleDataSize2 = size(cycleData2);
            strainData2_1 = cycleData2(:,2);
            strainData2_2 = cycleData2(:,3);
            forceData2_1 = cycleData2(:, min(cycleDataSize2) - 1);
            forceData2_2 = cycleData2(:, min(cycleDataSize2));
            stressData2_1 = forceData2_1./pinA;
            stressData2_2 = forceData2_2./pinA;
            stressData2_1 = stressData2_1./1000;
            stressData2_2 = stressData2_2./1000;
            
            stressData1_1 = filter(B,A,stressData1_1);
            stressData1_2 = filter(B,A,stressData1_2);
            stressData2_1 = filter(B,A,stressData2_1);
            stressData2_2 = filter(B,A,stressData2_2);
            
            
            legendVal1 = strfind(finalStr(indArray(i,1)), '_');
            legendVal1 = legendVal1{1};
            legendVal = finalStr(indArray(i,1));
            legendVal = legendVal{1};
            legendVal1_1 = legendVal(1:legendVal1(2)-1);
            legendVal1_2 = legendVal(legendVal1(2)+1:legendVal1(4)-1);
            
            legendVal2 = strfind(finalStr(indArray(i,2)), '_');
            legendVal2 = legendVal2{1};
            legendVal = finalStr(indArray(i,2));
            legendVal = legendVal{1};
            legendVal2_1 = legendVal(1:legendVal2(2)-1);
            legendVal2_2 = legendVal(legendVal1(2)+1:legendVal1(4)-1);
            
            legendData = [legendVal1_1; legendVal1_2; legendVal2_1; legendVal2_2];
            
            undVals = strfind(finalStr(indArray(i,1)), '_');
            undVals = undVals{1};
            name = finalStr(indArray(i,1));
            name = name{1};
            name = [name(1:undVals(1)) name(undVals(2)+1:undVals(3)-1) ' - Trial ' num2str(x)];
            
            h(figInd) = figure('Name', name);
            figInd = figInd + 1;
            
            hold on;
            plot(strainData1_1,stressData1_1, 'LineWidth',2);
            plot(strainData1_2,stressData1_2, 'LineWidth',2);
            plot(strainData2_1,stressData2_1, 'LineWidth',2);
            plot(strainData2_2,stressData2_2, 'LineWidth',2);
            hold off;
            
            xlabel('Extension Ratio');
            ylabel('Tensile Stress (kPa)');
            legend({legendData}, 'Location', 'southeast','Interpreter', 'none');
            
        end
    end
end

lastSlash = max(strfind(folder_name, '\'));
desiredFileName = folder_name(lastSlash+1:length(folder_name));
desiredFileName = strcat(folder_name, '/', desiredFileName, '_SameDef-DiffExt');
savefig(h,desiredFileName);
close all;


%%Done with program - Let's Clean up!
clc;
cd(currentFolder);
clear all;


