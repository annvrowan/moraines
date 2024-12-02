function [name,LSDn_age,LSDn_int,LSDn_ext] = calibration_calculator(sample_data,nuclide_string,value_LSDn_string,uncert_LSDn_string)

%A script to generate local prodution rate from calibration data, send sample data to the adjusted online cosmo calculator and collect the
%results. Sample_data is the sample info returned from ICE-D by the script
%iced_query.m that has been reformatted to tab spaced for cosmo calculator.

%Example copied from cosmo calc website
%text = ['PH-1',sprintf('\t'),num2str(41.3567),sprintf('\t'),num2str(-70.7348),sprintf('\t'),num2str(91),sprintf('\t'),'std',sprintf('\t'),num2str(4.5),sprintf('\t'),num2str(2.65),sprintf('\t'),num2str(1),sprintf('\t'),num2str(0.00008),sprintf('\t'),num2str(1999),';', sprintf('\n'),'PH-1',sprintf('\t'),'Be-10',sprintf('\t'),'quartz',sprintf('\t'),num2str(123453),sprintf('\t'),num2str(3717),sprintf('\t'),'KNSTD;',sprintf('\n'),'PH-1',sprintf('\t'),'Al-26',sprintf('\t'),'quartz',sprintf('\t'),num2str(712408),sprintf('\t'),num2str(31238),sprintf('\t'),'KNSTD;'];

%Source: https://wiki.ice-d.org/pluginto:calculators (retrieved 26/11/24 by
%KP)
%Created by Karlijn on 26/11/24


%% Check sample data
%Check if sample data contains gaps and skip samples if so
%sample_data = sample_data{1};

%Check sample data is the correct size for cosmo calculator
%a = find(sample_data == ':'); 
%a = find(strcmp(sample_data, ':'));
%size(a);
%if a < 14; return; end

sample_data=string(sample_data);

%Format sample data for input to cosmo calculator
text = regexprep(sample_data,':','\t');

%%
% Send data to cosmo calculator with non-default production rate parameters
url = "https://hess.ess.washington.edu/cgi-bin/matweb";
data = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no',...
    'text_block',text,...
    'trace_string','nothing here but this is required',...
    'calib_name','nothing here either but this is required too',...
    'nuclide_name',nuclide_string,...
    'P_LSDn',value_LSDn_string,'delP_LSDn',uncert_LSDn_string);

%Load the parser and parse string from data returned from cosmo calculator
import matlab.io.xml.dom.*
xDoc = parseString(Parser,data);

%Get the content of the stated elements to return as number
name = getTextContent(getElementsByTagName(xDoc,'sample_name'));
LSDn_age = str2double(getTextContent(getElementsByTagName(xDoc,'t10quartz_LSDn')));
LSDn_int = str2double(getTextContent(getElementsByTagName(xDoc,'delt10quartz_int_LSDn')));
LSDn_ext = str2double(getTextContent(getElementsByTagName(xDoc,'delt10quartz_ext_LSDn')));







