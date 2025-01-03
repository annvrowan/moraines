
%A script to collect sample data from ICE–D version 2, calibrate the ages using
%cosmo calculator and format the results into a table for further analysis


%Before running this script, some prep is needed:

%Download the Java driver from https://dev.mysql.com/downloads/connector/j/
%(select 'platform independent' for OS X and mysql-connector-j-8.2.0.jar, or latest version)
%Copy/paste your driver jar file to a local directory, and note the
%address.

%Install MATLAB Database Explorer.

%Make an ssh tunnel connection to the database, on OS X using Terminal:
%>> ssh -f iced@stoneage.ice-d.org -L 12345:34.73.248.9:3306 -N
% and wait a few seconds for it to return done.


%To get started use one of these two options to make a connection to
%the database:

%1. Open MATLAB Database Explorer:
% Select 'Configure Data Source' and 'Configure JDBC Data Source'.
% Populate the fields in pop-up menu:
% Give the source a name (e.g., "iced_connect")
% Driver Location: <local address>/mysql-connector-j-8.2.0.jar
% Vendor = MySQL
% Database = "iced"
% PortNumber = "12345"
% Test the connection: reader/beryllium-10
% Save the connection and close Database Explorer
% Update the name of the connection (e.g., "iced_connect") in the
% 'database'
% function call below (about line 60). Then you can run this script to access the database.


%2. As an alternative to option 1, you can instead put the connection info into the
%'database' function below (about line 68). The java path needs to match the location of the downloaded driver.


%for more info on connecting to ICED, see: https://wiki.ice-d.org/applications:connect_matlab_mac
%for more info on writing good queries, see: https://wiki.ice-d.org/pluginto:useful_sql_queries

% Notes:
%Version 1 took 500 s to run 830 NZ sample ages
%Version 2 took 200 s to run 934 NZ sample ages

%Created by Greg Balco
%Last modifed by Ann Rowan on 10/01/24
%Last modified by Karlijn Ploeg on 12/12/2024

clear all
close all
tic
%% Connect to the database
%Both options assume that there is a connection to the database server, so an SSH tunnel needs to be open to the database.
%Note use of read-only login: reader/beryllium-10

%Option 1;
%dbc = database('iced_connect','reader','beryllium-10');

%Option 2;
[sys1,sys2] = system('ps aux | grep 3306');
portindex = strfind(sys2,':34.73.248.9:');
portstr = sys2((portindex(1)-5):(portindex(1)-1));
javaaddpath([matlabroot,'/java/jarext/mysql-connector-j-8.2.0.jar'])
configureJDBCDataSource("Vendor",'MySQL');
dbc = database('iced','reader','beryllium-10','Vendor','MySQL','Server','localhost','port',str2num(portstr));

%% Query ICED to return a list of sample names
%Make a MySQL query to return a list of all samples from moraines in the Southern Alps

q1 = ['SELECT DISTINCT base_region.name, base_site.name, base_site.what, base_sample.name, base_sample.what, base_sample.lat_DD, base_sample.lon_DD, base_sample.elv_m,base_sample.shielding, base_publication.short_name, base_publication.doi ' ...
    'FROM base_sample ' ...
    'JOIN base_site ON base_site.id = base_sample.site_id ' ...
    'JOIN base_region ON base_site.region_id = base_region.id ' ...
    'LEFT JOIN base_samplepublicationsmatch ON base_samplepublicationsmatch.sample_id = base_sample.id ' ...
    'LEFT JOIN base_publication ON base_publication.id = base_samplepublicationsmatch.publication_id ' ...
    'JOIN base_application_sites ON base_application_sites.site_id = base_site.id ' ...
    'JOIN base_application ON base_application.id = base_application_sites.application_id ' ...
    'WHERE base_application.id = 2 ' ...
    'AND (base_sample.lat_DD < -40 AND base_sample.lat_DD > -48) ' ...
    'AND (base_sample.lon_DD < 175 AND base_sample.lon_DD > 166)'];

d.sites = fetch(dbc,q1);

%% Overview of sample and site data

%Put the returned sample names into a cell array called name_list. This is
%useful to double check for duplicates or missing values.

%Samples
name_list(:,1) = d.sites.name_2; %sample name
[unique_samples, unique_indices] = unique(name_list, 'stable'); % Get unique samples and their indices
no_samples = length(unique_samples);

% Remove duplicates
d.sites = d.sites(unique_indices, :);
name_list = unique_samples;

%Sites 
site_list(:,1) = d.sites.name_1;
unique_sites = unique(site_list,'stable');
no_sites = length(unique_sites);

%Regions
region_list(:,1) = d.sites.name;
unique_regions = unique(region_list,'stable');
no_regions = length(unique_regions);

%Print number of samples found
disp(strcat("Number of unique samples = ",num2str(no_samples)))
disp(strcat("Number of sites = ",num2str(no_sites)))
disp(strcat("Number of regions = ",num2str(no_regions)))

% Create sample and site data arrays to collect exposure age results
sample_data = cell(no_samples,20);
site_data = cell(no_sites,11);

%% Collect sample data for all samples indentified and put into a cell array
% Sample name needs to have this format to query the database: '"Barr2007-A-WH-01B"'

%Populate the table with the site name in col1, sample name in col2 and the string for cosmo
%calculator in col3
for i = 1:no_samples
    name = cat(2,'"',name_list{i,1},'"');
    %Make the query to send to ICE-D to return input for cosmo calculator
    q2 = cat(2,['select  concat_ws(":",base_sample.name,base_sample.lat_DD,base_sample.lon_DD,base_sample.elv_m,"std",base_sample.thick_cm,base_sample.density,base_sample.shielding,"0 2010;",base_sample.name,"Be-10 quartz",_be10_al26_quartz.N10_atoms_g,_be10_al26_quartz.delN10_atoms_g,_be10_al26_quartz.Be10_std,";") from base_sample join _be10_al26_quartz on base_sample.id = _be10_al26_quartz.sample_id where base_sample.name ='],name);
    sample_data{i,1} = site_list{i,1};
    sample_data{i,2} = name;
    sample_data{i,3} = fetch(dbc,q2,'DataReturnFormat','cellarray');
end
%Now close the database connection
close(dbc);
toc

%% Create extra rows for samples with multiple measurements

% New cell arrays to store data
duplicate_samples = {};
new_rows = {};

% Input sample data
data=sample_data;

% Input sites data
sites = d.sites;

% Loops through 3rd column to check for multiple entries for cosmo input
for i = size(data, 1):-1:1
    if iscell(data{i, 3}) && numel(data{i, 3}) > 1 %Filter our multiple measurements on 1 sample
       
       duplicate_samples = [duplicate_samples;data{i, 2}];
       
       % Initialize variables to store unique and merged parts of the
       % strings
       
       strings = {};
       new_entries = {}; % To store new rows
       new_sites_entries = {}; % To store new rows for sites

       for j = 1:numel(data{i, 3}) %select cosmocal input

            if j ==1 %first measurement
               strings{j} = data{i, 3}{j};
           
            else %multiple measurements
               parts = strsplit(data{i, 3}{j}, ';');
               strings{j} = [parts{2}, ';'];
               new_entries = [new_entries; {data{i, 1}, data{i, 2}, strings{2},data{i, 4:end}}]; % Create new row
               new_sites_entries = [new_sites_entries; d.sites(i, :)]; 
            end
       end
       

       % Update the original data with the first measurement
       data{i, 3} = strings{1};

       % Insert new rows directly after the current row
       data = [data(1:i, :); new_entries; data(i+1:end, :)];
       % Insert new rows directly after the current row in d.sites
       sites = [sites(1:i, :); new_sites_entries; sites(i+1:end, :)];
        
    else        
        str = char(data{i, 3});
        elements = strsplit(str, ':'); % Split the string at each ':'
        if length(elements) < 13
           data(i, :) = []; % Remove the entire row
           sites(i, :) = []; % Remove the corresponding row in sites
        end
    end
end

sample_data = data;
d.sites = sites;

%% Choose calibration dataset for local production rate calculations

% Select calibration dataset from the calibration page of ICE-D
cal_page_html = webread('https://version2.ice-d.org/production%20rate%20calibration%20data/site/MACAULAY/');

% Scrape the formatted text block out of the HTML
startindex = strfind(cal_page_html,'<!-- begin v3 --><pre>') + length('<!-- begin v3 --><pre>');
endindex = strfind(cal_page_html,'</pre><!-- end v3 -->') - 1;
cal_input_text = cal_page_html(startindex:endindex);

% Make sure to only have one nuclide in the input text, in this case 10Be!
lines = splitlines(cal_input_text);
filtered_lines = lines(~contains(lines, 'C-14')); % Filter C-14 out 
filtered_text = strjoin(filtered_lines, '\n');

%% Calculate calibration parameters

%Send dataset to calibration calculator
url = "http://hess.ess.washington.edu/cgi-bin/matweb";
cal_result = webread(url,'mlmfile','cal_input_v3','reportType','XML','plotFlag','no','text_block',filtered_text);

% Fix the XML string by replacing <br> with <br/> (somehow otherwise not
% working somehow)
fixed_string= strrep(cal_result, '<br>', '<br/>');

%Load the parser and parse string from data returned from cosmo calculator
import matlab.io.xml.dom.*
xDoc = parseString(Parser,fixed_string);

% Define the parameters to extract
tags = {'nuclide', 'summary_value_St', 'summary_uncert_St', 'summary_value_Lm', 'summary_uncert_Lm', 'summary_value_LSDn', 'summary_uncert_LSDn'};
fields = {'nuclide', 'value_St', 'uncert_St', 'value_Lm', 'uncert_Lm', 'value_LSDn', 'uncert_LSDn'};
parameters = struct();

% Loop through each tag and extract the text content
for i = 1:length(tags)
    parameters.(fields{i}) = getElementsByTagName(xDoc, tags{i}).item(0).getTextContent();
end

disp("Returned calibrated production rate parameters")

%% Send sample data to cosmo calculator and return age and age errors
%This part of the script calls a different script; cosmo_calculator

%The script returns the sample names into col3 of the table so they can be
%checked against the original names in col1 as q quick check that the data
%is collected as expected. If the sample is missing, col3 has an error
%message instead.


for i  = 1:no_sites
    site = unique_sites{i}; %select site
    select = strcmp(sample_data(:, 1), site); %select corresponding site
    site_samples = sample_data(select, :); %select data rows matching site

    no_site_samples = size(site_samples,1); %select number of samples within site
    strings = cell(size(site_samples, 1), 1); %empty cell to collect strings for cosmocalinput   
    
    %select cosmocalinput per sample
    for a = 1:no_site_samples
        strings{a} = site_samples{a, 3};
    end
   
    % Join strings of samples together
    strings = cellfun(@char, strings, 'UniformOutput', false);
    input = strjoin(strings,' '); %join strings cosmocal input
    
    
    % Send data to cosmo_calculator
    [ages_global,ages_local] = cosmo_calculator(input,parameters);
    
    %metadata
    d2.sites = d.sites(select, :); %select metadata for rows matching site
    rowIndices = find(select); % Find all row indices matching the site
    
    
       for j = 1:no_site_samples
        sample_data{rowIndices(j), 4} = d2.sites.name(j);   %region
        sample_data{rowIndices(j), 5} = site; %site name
        sample_data{rowIndices(j), 6} = d2.sites.what(j); %landform
        sample_data{rowIndices(j), 7} = site_samples{j, 2}; %sample name
        sample_data{rowIndices(j), 8} = d2.sites.what_1(j); %type of sample
        sample_data{rowIndices(j), 9} = d2.sites.lat_DD(j); %latitude
        sample_data{rowIndices(j), 10} = d2.sites.lon_DD(j); %longitude
        sample_data{rowIndices(j), 11} = d2.sites.elv_m(j); %elevation
        sample_data{rowIndices(j), 12} = d2.sites.shielding(j);%topographic shielding
        sample_data{rowIndices(j), 13} = ages_global.sample_ages(j).LSDn_age;
        sample_data{rowIndices(j), 14} = ages_global.sample_ages(j).LSDn_int;
        sample_data{rowIndices(j), 15} = ages_global.sample_ages(j).LSDn_ext;
        sample_data{rowIndices(j), 16} = ages_local.sample_ages(j).LSDn_age;
        sample_data{rowIndices(j), 17} = ages_local.sample_ages(j).LSDn_int;
        sample_data{rowIndices(j), 18} = ages_local.sample_ages(j).LSDn_ext;
        sample_data{rowIndices(j), 19} = d2.sites.short_name(j); %short citation
        sample_data{rowIndices(j), 20} = d2.sites.doi(j); %doi
        pause(0.1)
        disp(strcat("Sample", num2str(j)))
       end

    site_data{i,1} = d2.sites.name(1,1); %region
    site_data{i,2} = site; %site name
    site_data{i,3} = d2.sites.what(1,1); %landform context
    site_data{i,4} = no_site_samples; %number of samples

    % Extract the sample names from the structure
    names = site_samples(:,2); % This will create a cell array of names
    concatenated_names = strjoin(names, ', '); % Join the names with a comma and space

    site_data{i,5} = concatenated_names; %sample IDs used for landform calculation
    site_data{i,6} = ages_global.sum_val;
    site_data{i,7} = ages_global.sum_int;
    site_data{i,8} = ages_global.sum_ext;
    site_data{i,9} = ages_local.sum_val;
    site_data{i,10} = ages_local.sum_int;
    site_data{i,11} = ages_local.sum_ext;
    site_data{i,12} = d2.sites.short_name(1,1); %short citation
    site_data{i,13} = d2.sites.doi(1,1); %doi

    disp(strcat("Site", num2str(i)))
end

disp("Calculated exposure ages")

%% Save sample and site data in table type

sample_data = cell2table(sample_data,'VariableNames',{'site1','sample','cosmocalcinput','region','site2','landform','sample_ID','type','lat_dd','lon_dd','elv_m','topo_shielding','LSDn_age_glob','LSDn_int_glob','LSDn_ext_glob','LSDn_age_loc','LSDn_int_loc','LSDn_ext_loc','short_citation','doi'});
site_data = cell2table(site_data,'VariableNames',{'region','site','landform','no_samples','sample_IDs','LSDn_age_glob','LSDn_int_glob','LSDn_ext_glob','LSDn_age_loc','LSDn_int_loc','LSDn_ext_loc','short_citation','doi'});
save('sample_data','sample_data');
save('site_data','site_data');


