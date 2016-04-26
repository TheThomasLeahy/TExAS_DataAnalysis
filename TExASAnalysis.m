% TExAS Data Analysis

% This program plots stress/strain curves from calculations of stresses and
% strains from raw data, acquired from an excel file output by the TExAS Device

%Code by Thomas Leahy and Elizabeth Shih

clear all; close all; clc;

% User Input
currentFolder = pwd(); %% Stores current folder to restore later

folder_name = uigetdir; %%Gets input folder name from the user (through folder explorer GUI)
allSubFolders = genpath(folder_name); %%File path for all subfolders (including empty ones) of the user input folder

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

%%Data Analysis

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
            
            hold on;
            stressData = stressData./1000;
            plot(strainData,stressData, 'LineWidth',2);
            
            cycleString(x,:) = ['Cycle ',num2str(x)];
            
            if(x == length(outs)) 
                %Plotted everything! Let's format!
                xlabel('Extension Ratio');
                ylabel('Stress (kPa)');
                legend(cycleString, 'Location', 'southeast');
                hold off;
            end
            
            zeroLoad(i,x) = stressData(1);
            
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
            
            hold on;
            plot(strainData,stressData, 'LineWidth',2);
            
            cycleString(x,:) = ['Cycle ',num2str(x)];
            
            if(x == length(outs)) 
                %Plotted everything! Let's format!
                xlabel('Shear Angle (Degrees)');
                ylabel('Stress (kPa)');
                legend(cycleString, 'Location', 'southeast');
                hold off;
            end
            
            zeroLoad(i,x) = stressData(1);
            
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
 
            hold on;
            plot(strainData_1,stressData_1, 'LineWidth',2);
            plot(strainData_2,stressData_2, 'LineWidth',2);
            
            if(x == length(outs)) %Plot legend only on the first graph
                xlabel('Extension Ratio');
                ylabel('Stress (kPa)');
                legend(cycleString, 'Location', 'southeast');
                hold off;
            end 
            
            zeroLoad(i,2*(x-1)+1) = stressData_1(1);
            zeroLoad(i,2*(x-1)+2) = stressData_2(1);
            
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

for i = 1: numberOfDataFolders
    clear index;
    
    testName = char(finalStr(i));
    testName = [testName, '_LowestPointGraph'];
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
desiredFileName = strcat(folder_name, '/', desiredFileName, '_ZeroPointLowestStressPlots');
savefig(h,desiredFileName);
close all;

%% Now we begin our same deformation, different extension graphs

%{

listOfBiaxFolders = [];
for s = 1:numberOfDataFolders
    if(length(strfind(finalStr(s), 'X')) > 1)
        listOfBiaxFolders = [listOfBiaxFolders listOfDataFolders(s)];
    end
end

xVals = zeros(length(listOfBiaxFolders,6));
for  s = 1:length(listOfBiaxFolders)
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,1) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1C'))))
        xVals(s,2) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X2T'))))
        xVals(s,3) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X2C'))))
        xVals(s,4) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X3T'))))
        xVals(s,5) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X3C'))))
        xVals(s,6) = true;
    end
end

%Assemble list of same tests for all tests in the same folder
%For example, we only want to plot the graphs on the same plot if they were
%a part of the same protocol

initFoldString = strArray(1, 1:lastslash(1));
initIndex = 1;
for  s = 2:length(listOfBiaxFolders)
    if strArray(s, 1:lastSlash(s)) == initFoldString
        if xVals(initIndex) == xVals(s)
            sameTestAs(s) = initIndex;
        end
    else
        initFoldString = strArray(s, 1:lastslash(s));
        initIndex = s;
    end
end

%close all; 
clc;
cd(currentFolder);

%}
