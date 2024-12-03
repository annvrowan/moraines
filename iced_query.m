
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
%Last modified by Karlijn Ploeg on 08/02/2024

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
q1 = ['select base_site.short_name, base_sample.name, base_sample.lon_DD,base_sample.lat_DD,base_sample.elv_m,base_sample.shielding,base_continent.name, base_site.what, base_sample.what ' ...
    'from base_sample join base_site on base_site.id = base_sample.site_id join base_continent on base_site.continent_id = base_continent.id ' ...
    'WHERE (base_sample.lat_DD < -40 AND base_sample.lat_DD > -48)'... 
    'AND (base_sample.lon_DD < 175 AND base_sample.lon_DD > 166)'... 
    'and base_site.what like "%oraine%"'];
d.sites = fetch(dbc,q1);

%Put the returned sample names into a cell array called name_list. This is
%useful to double check for duplicates or missing values.
name_list(:,1) = d.sites.name;
no_samples = length(name_list);
%Print number of samples found
disp(strcat("Number of samples = ",num2str(no_samples)))

%% Collect sample data for all samples indentified and put into a cell array
% Sample name needs to have this format to query the database: '"Barr2007-A-WH-01B"'
sample_data = cell(no_samples,16);
%Populate the table with the sample name in col1 and the string for cosmo
%calculator in col2
for i = 1:no_samples
    name = cat(2,'"',name_list{i,1},'"');
    %Make the query to send to ICE-D to return input for cosmo calculator
    q2 = cat(2,['select  concat_ws(":",base_sample.name,base_sample.lat_DD,base_sample.lon_DD,base_sample.elv_m,"std",base_sample.thick_cm,base_sample.density,base_sample.shielding,"0 2010;",base_sample.name,"Be-10 quartz",_be10_al26_quartz.N10_atoms_g,_be10_al26_quartz.delN10_atoms_g,_be10_al26_quartz.Be10_std,";") from base_sample join _be10_al26_quartz on base_sample.id = _be10_al26_quartz.sample_id where base_sample.name ='],name);
    sample_data{i,1} = name;
    sample_data{i,2} = fetch(dbc,q2,'DataReturnFormat','cellarray');
end
%Now close the database connection
close(dbc);
toc


%% Send sample data to cosmo calculator and return age and age errors
%This part of the script calls a different script; cosmo_calculator
%The script returns the sample names into col3 of the table so they can be
%checked against the original names in col1 as q quick check that the data
%is collected as expected. If the sample is missing, col3 has an error
%message instead.

% Calculate with global production rate (default)
for i  = 1:1
    if isempty(sample_data{i,2}); sample_data{i,3} = 'database did not return sample data';
    else
        [name,LSDn_age,LSDn_int,LSDn_ext] = cosmo_calculator(sample_data{i,2});
        sample_data{i,3} = name;
        sample_data{i,4} = d.sites.lat_DD(i);
        sample_data{i,5} = d.sites.lon_DD(i);
        sample_data{i,6} = d.sites.elv_m(i);
        sample_data{i,7} = LSDn_age;
        sample_data{i,8} = LSDn_int;
        sample_data{i,9} = LSDn_ext;
        sample_data{i,10} = d.sites.short_name(i);
        sample_data{i,11} = d.sites.what(i);
        sample_data{i,12} = d.sites.what_1(i);
        sample_data{i,13} = d.sites.shielding(i);
        pause(0.1)
        disp(strcat("Sample", num2str(i)))
    end
end
toc

disp("Exposure ages using global production rate calculated")

%% Local production rate

% Get calibration dataset from the calibration website
cal_page_html = webread('https://version2.ice-d.org/production%20rate%20calibration%20data/site/MACAULAY/');

% Scrape the formatted text block out of the HTML
startindex = strfind(cal_page_html,'<!-- begin v3 --><pre>') + length('<!-- begin v3 --><pre>');
endindex = strfind(cal_page_html,'</pre><!-- end v3 -->') - 1;
cal_input_text = cal_page_html(startindex:endindex);

%Make sure to only have one nuclide in the input text!
lines = splitlines(cal_input_text);
filtered_lines = lines(~contains(lines, 'C-14')); % Filter C-14 out 
filtered_text = strjoin(filtered_lines, '\n');

%Calibration calculator
url = "http://hess.ess.washington.edu/cgi-bin/matweb";
cal_xml_result = webread(url,'mlmfile','cal_input_v3','reportType','XML','plotFlag','no','text_block',filtered_text);

temp = regexp(cal_xml_result,['<nuclide>(.*?)</nuclide>'],'tokens');
nuclide_string = temp{1}{1};

% Get calibrated production rate parameters for LSDn scaling method
temp = regexp(cal_xml_result,['<summary_value_LSDn>(.*?)</summary_value_LSDn>'],'tokens');
value_LSDn_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_uncert_LSDn>(.*?)</summary_uncert_LSDn>'],'tokens');
uncert_LSDn_string = temp{1}{1};

disp("Returned calibrated production rate parameters")

%% Calculate exposure ages using local production rate parameters

%load sample_data_global.mat;
%sample_data = table2cell(sample_data);

%%
for i  = 1:length(sample_data)
    if isempty(sample_data{i,2}); sample_data{i,3} = 'database did not return sample data';
    else
        [name,LSDn_age,LSDn_int,LSDn_ext] = calibration_calculator(sample_data{i,2},nuclide_string,value_St_string,uncert_St_string,value_Lm_string,uncert_Lm_string,value_LSDn_string,uncert_LSDn_string);
        sample_data{i,14} = LSDn_age;
        sample_data{i,15} = LSDn_int;
        sample_data{i,16} = LSDn_ext;
        pause(0.1)
        disp(strcat("Sample", num2str(i)))
    end
end

disp("Exposure ages using local production rate calculated")
%%

%format the results into a Matlab table and save
sample_data = cell2table(sample_data,'VariableNames',{'name','cosmocalcinput','name2','lat_dd','lon_dd','elv_m','LSDn_age_glob','LSDn_int_glob','LSDn_ext_glob','site','what_site','what_sample','shielding','LSDn_age_loc','LSDn_int_loc','LSDn_ext_loc'});
save('sample_data','sample_data')



