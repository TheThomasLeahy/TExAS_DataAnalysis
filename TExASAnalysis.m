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
        
    cd(strArray(i,:));
    files = dir('*.csv'); %lists all csv files from subdirectory
    outs = cell(1,(numel(files)/2)); %Creates cell matrix for every _SIMP file
    
    y = 1;
    for x = 2:2:numel(files)
        outs{y}=csvread(files(x).name, 1,1); %out is a cell that holds csv data from all cycles
        y = y + 1;
    end
    %outs now contains all csv data

    %Opens figure titled after the test name
    h(i) = figure('Name', testName);
    
    for x = 1:length(outs)
        cycleData = cell2mat(outs(x));
        cycleDataSize = size(cycleData);
        area = 0;
    
        if unibi_testType(i) == testType.Uniaxial_Tension %Plot graphs for uniaxial tension/compression tests
        
            strainData = cycleData(:,2) - 1;
            forceData = cycleData(:,min(cycleDataSize));
            
            if(testName(2) == '1')
                area = cycleData(:, min(cycleDataSize)-2).*cycleData(:, min(cycleDataSize)-1);
            elseif(testName(2) == '2')
                area = cycleData(:, min(cycleDataSize)-3).*cycleData(:, min(cycleDataSize)-1);
            elseif(testName(2) == '3')
                area = cycleData(:, min(cycleDataSize)-2).*cycleData(:, min(cycleDataSize)-3);
            end
            area = area/1000000;
            stressData = forceData./area;
            
            subplot(length(outs),1,x);
            plot(strainData,stressData);
            xlabel(['Stress (%) \n Plot for cycle number', num2str(x)]);
            ylabel('Stress (Pa)');
            
            if(x ==1) %Plot legend only on the first graph
                firstlegend = testName(1:3);
                legend(firstlegend);
                title(testName);
            end 
            
            %{
            [~,Mod(x),~]=regression(strainData,stressData, 'one');
            modStringArray(x) = cellstr(strcat('The modulus along the ', testName(1:2), ' axis for cycle number ', num2str(x), ' is ' ,num2str(Mod(x))));
            
            if(x == length(outs))
                meanMod = mean(Mod);
                modStringArray(x+1) = cellstr(strcat('The average modulus along the ', testName(1:2), ' axis is ' ,num2str(meanMod)));
            end
            %}
            
        elseif unibi_testType(i) == testType.Uniaxial_Shear %Plot graphs for uniaxial shear tests
        
            strainData = cycleData(:,2);
            forceData = cycleData(:,min(cycleDataSize));
            
            if(strcmp(testName(2:3), '12')) %Either X12 or X13
                area = cycleData(:, min(cycleDataSize)-2).*cycleData(:, min(cycleDataSize)-4);
            elseif(strcmp(testName(2:3), '13'))
                area = cycleData(:, min(cycleDataSize)-2).*cycleData(:, min(cycleDataSize)-4);
            elseif(strcmp(testName(2:3), '21'))
                area = cycleData(:, min(cycleDataSize)-2).*cycleData(:, min(cycleDataSize)-1);
            elseif(strcmp(testName(2:3), '23'))
                area = cycleData(:, min(cycleDataSize)-4).*cycleData(:, min(cycleDataSize)-3);
            elseif(strcmp(testName(2:3), '31'))
                area = cycleData(:, min(cycleDataSize)-3).*cycleData(:, min(cycleDataSize)-1);
            elseif(strcmp(testName(2:3), '32'))
                area = cycleData(:, min(cycleDataSize)-4).*cycleData(:, min(cycleDataSize)-1);
            end
            
            area = area/1000000;
            stressData = forceData./area;
            
            subplot(length(outs),1,x);
            plot(strainData,stressData);
            xlabel(['Stress (%) \n Plot for cycle number', num2str(x)]);
            ylabel('Stress (Pa)');
            if(x ==1) %Plot legend only on the first graph
                firstlegend = testName(1:3);
                legend(firstlegend);
                title(testName);
            end 
            
            %{
            [~,Mod(x),~]=regression(strainData,stressData,'one');
            modStringArray(x) = cellstr(strcat('The modulus along the ', testName(1:2), ' axis for cycle number ', num2str(x), ' is ' ,num2str(Mod(x))));
            
            if(x == length(outs))
                meanMod = mean(Mod);
                modStringArray(x+1) = cellstr(strcat('The average modulus along the ', testName(1:2), ' axis is ' ,num2str(meanMod)));
            end
            %}
            
        elseif unibi_testType(i) == testType.Biaxial %Plot graphs for biaxial tests
        
            strainData_1 = cycleData(:,2) - 1;
            strainData_2 = cycleData(:,3) - 1;
            forceData_1 = cycleData(:, min(cycleDataSize) - 1);
            forceData_2 = cycleData(:, min(cycleDataSize));
            
            secondX = max(strfind(testName, 'X'));
            
            if(~(testName(2) == '1')) %%We know this test was an x2x3 biaxial test
                area1 = cycleData(:,min(cycleDataSize) - 4) .* cycleData(:,min(cycleDataSize) - 2);
                area2 = cycleData(:,min(cycleDataSize) - 4) .* cycleData(:,min(cycleDataSize) - 3);
            elseif(testName(secondX+1) == '2') %We know this was an x1x2 biaxial test
                area1 = cycleData(:,min(cycleDataSize) - 4) .* cycleData(:,min(cycleDataSize) - 3);
                area2 = cycleData(:,min(cycleDataSize) - 4) .* cycleData(:,min(cycleDataSize) - 2);
            elseif(testName(secondX+1) == '3') %We know this was an x1x3 biaxial test
                area1 = cycleData(:,min(cycleDataSize) - 4) .* cycleData(:,min(cycleDataSize) - 3);
                area2 = cycleData(:,min(cycleDataSize) - 3) .* cycleData(:,min(cycleDataSize) - 2);
            end
            
            area1 = area1/1000000;
            area2 = area2/1000000;
            stressData_1 = forceData_1./area1;
            stressData_2 = forceData_2./area2;
 
            subplot(length(outs),1,x);
            plot(strainData_1,stressData_1);
            xlabel(['Stress (%) \n Plot for cycle number', num2str(x)]);
            ylabel('Stress (Pa)');
            hold on;
            plot(strainData_2,stressData_2);
            
            if(x ==1) %Plot legend only on the first graph
                firstlegend = testName(1:3);
                secondlegend = testName(secondX:secondX+2);
                legend(firstlegend, secondlegend);
                title(testName);
            end 

            %{
            [~,Mod1(x),~]=regression(strainData_1,stressData_1,'one');
            [~,Mod2(x),~]=regression(strainData_2,stressData_2,'one');
            modStringArray((2*(x-1))+1) = cellstr(strcat('The modulus along the', testName(1:2), ' axis for cycle number ', num2str(x), ' is ' ,num2str(Mod1(x)), ' Pa.'));
            modStringArray((2*(x-1))+2) = cellstr(strcat('The modulus along the ',' ', testName(secondX:secondX+2), ' axis for cycle number ', num2str(x), ' is ' ,num2str(Mod2(x)), ' Pa.'));
            
            if(x == length(outs))
                meanMod1 = mean(Mod1);
                meanMod2 = mean(Mod2);
                modStringArray((2*x)+1) = cellstr(strcat('The average modulus along the ', testName(1:2), ' axis is ' ,num2str(meanMod1), ' Pa.'));
                modStringArray((2*x)+2) = cellstr(strcat('The average modulus along the ', testName(secondX:secondX+2), ' axis is ' ,num2str(meanMod2), ' Pa.'));
            end
            %}
        end
    end
    
end

%Reset Folder
cd(folder_name);

lastSlash = max(strfind(folder_name, '\'));
desiredFileName = folder_name(lastSlash+1:length(folder_name));
desiredFileName = strcat(folder_name, '/', desiredFileName, '_BasicStrainCurves');

savefig(h,desiredFileName);

%{
outputfilename = cell(1,numberOfDataFolders);
modfile = cell(1,numberOfDataFolders);

for i = 1: numberOfDataFolders
    outputfilename(i) = cellstr(strcat('myfile', num2str(i)));
    print(h(i),char(outputfilename(i)),'-dpdf');
    outputfilename(i) = strcat(folder_name, '/', outputfilename(i), '.pdf');
end

desiredFileName = strcat(desiredFileName,'.pdf');

delete(desiredFileName);
for i = 1:numberOfDataFolders
    append_pdfs(desiredFileName, char(outputfilename(i)));
    delete(char(outputfilename(i)));
end
%}


%listOfDataFolders contains an array of strings of all files containing
%data that needs to be analyzed. Doesn't matter if it is within a protocol
%folder or not, it will be in this array.

xVals = zeros(numberOfDataFolders,3);


%Plot over degree instead of strain

listOfBiaxFolders = [];
for s = 1:numberOfDataFolders
    if(length(strfind(listOfDataFolders(s), 'X')) > 1)
        listOfBiaxFolders = [listOfBiaxFolders listOfDataFolders(i)];
    end
end

xVals = zeros(length(listOfBiaxFolders,6));
for  s = 1:length(listOfBiaxFolders)
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,1) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,2) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,3) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,4) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,5) = true;
    end
    if(~isEmpty(length(strfind(listOfBiaxFolder(s),'X1T'))))
        xVals(s,6) = true;
    end
end

%Assemble list of same tests






close all; clc;
cd(currentFolder);


%Need to label charts/pages
%Need to output mod data to excel spreadsheet and figures





