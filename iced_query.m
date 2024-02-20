
%A script to collect sample data from ICE–D version 2, calibrate the ages using
%cosmo calculator and format the results into a table for further analysis


%Before running this script, some prep is needed:

%Download the Java driver from https://dev.mysql.com/downloads/connector/j/
%(select 'platform independent' for OS X and mysql-connector-j-8.3.0.jar, or latest version)
%Copy/paste your driver jar file to a local directory, and note the
%address.

%Install the MATLAB Database Explorer toolbox.

%Make an ssh tunnel connection to the database, on OS X using Terminal:
%>> ssh -f iced@stoneage.ice-d.org -L 12345:34.73.248.9:3306 -N
% and wait a few seconds for it to return done.


%Script section 1: To get started, use one of these two options (option 1 and option 2) to make a connection to
%the database:

%Option 1. Open MATLAB Database Explorer:
% Select 'Configure Data Source' and 'Configure JDBC Data Source'.
% Populate the fields in pop-up menu:
% Give the source a name (e.g., "iced_connect")
% Driver Location: <local address>/mysql-connector-j-8.3.0.jar
% Vendor = MySQL
% Database = "iced"
% PortNumber = "12345"
% Test the connection: reader/beryllium-10
% Save the connection and close Database Explorer
% Update the name of the connection (e.g., "iced_connect") in the
% 'database'
% function call below (about line 60). Then you can run this script to access the database.

%Option 2. As an alternative to option 1, you can instead put the connection info into the
%'database' function below (about line 68). The java path needs to match the location of the downloaded driver.

%for more info on connecting to ICED, see: https://wiki.ice-d.org/applications:connect_matlab_mac

% Script section 2: query the database using the parameters that you
% require, using the same format as when you connect to the database
% directly.

%for more info on writing good queries, see: https://wiki.ice-d.org/pluginto:useful_sql_queries

%Then the sample ages can either be;
% Script section 3: collected from the database, which are updated daily and use a standard production rate calibration, or;
% Script section 4: sample data can be used to produce recalibrated ages using cosmo_calculator, e.g., to adjust calibration parameters.

%When you are finished using the database, use Terminal to close the
%tunnel:
%Run this command to find connection 
% >> ps aux | grep 3306
%and then this command to close the connection:
% >> kill <connection number>

% Notes:
%Version 1 took 500 s to run 830 NZ sample ages
%Version 2 took 200 s to run 934 NZ sample ages

%Created by Greg Balco
%Last modifed by Ann Rowan on 20/02/24


clear all
close all
tic
%% 1. Connect to the database
%Both options assume that there is a connection to the database server, so an SSH tunnel needs to be open to the database.
%Note use of read-only login: reader/beryllium-10

%Option 1;
%dbc = database('iced_connect','reader','beryllium-10');

%Option 2;
[sys1,sys2] = system('ps aux | grep 3306');
portindex = strfind(sys2,':34.73.248.9:');
portstr = sys2((portindex(1)-5):(portindex(1)-1));
javaaddpath([matlabroot,'/java/jarext/mysql-connector-j-8.3.0.jar'])
configureJDBCDataSource("Vendor",'MySQL');
dbc = database('iced','reader','beryllium-10','Vendor','MySQL','Server','localhost','port',str2num(portstr));

%% 2. Query ICED to return a list of sample names
%Make a MySQL query to return a list of all samples from moraines in the Southern Alps
q1 = ['select base_site.short_name, base_sample.name, base_sample.lon_DD,base_sample.lat_DD,base_sample.elv_m, base_continent.name ' ...
    'from base_sample join base_site on base_site.id = base_sample.site_id join base_continent on base_site.continent_id = base_continent.id ' ...
    'where (base_site.range like "%New Zealand, Southern Alps%") ' ...
    'and base_site.what like "%moraine%"'];
d.sites = fetch(dbc,q1);

%Put the returned sample names into a cell array called name_list. This is
%useful to double check for duplicates or missing values.
name_list(:,1) = d.sites.name;
no_samples = length(name_list);
%Print number of samples found
disp(strcat("Number of samples = ",num2str(no_samples)))


return

%% 3. Collect sample data for all samples indentified and put into a cell array
% Sample name needs to have this format to query the database: '"Barr2007-A-WH-01B"'
sample_data = cell(no_samples,9);
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




%% 4. Send sample data to cosmo calculator and return age and age errors
%This part of the script calls a different script; cosmo_calculator
%The script returns the sample names into col3 of the table so they can be
%checked against the original names in col1 as q quick check that the data
%is collected as expected. If the sample is missing, col3 has an error
%message instead.
for i  = 1:no_samples
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
        pause(0.1)
    end
end
toc

%format the results into a Matlab table and save
sample_data = cell2table(sample_data,'VariableNames',{'name','cosmocalcinput','name2','lat_dd','lon_dd','elv_m','LSDn_age','LSDn_int','LSDn_ext'});
save('sample_data','sample_data')




