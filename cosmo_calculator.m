function [name,LSDn_age,LSDn_int,LSDn_ext] = cosmo_calculator(sample_data)

%A script to send sample data to the online cosmo calculator and collect the
%results. Sample_data is the sample info returned from ICE-D by the script
%iced_query.m that has been reformatted to tab spaced for cosmo calculator.

%Example copied from cosmo calc website
%text = ['PH-1',sprintf('\t'),num2str(41.3567),sprintf('\t'),num2str(-70.7348),sprintf('\t'),num2str(91),sprintf('\t'),'std',sprintf('\t'),num2str(4.5),sprintf('\t'),num2str(2.65),sprintf('\t'),num2str(1),sprintf('\t'),num2str(0.00008),sprintf('\t'),num2str(1999),';', sprintf('\n'),'PH-1',sprintf('\t'),'Be-10',sprintf('\t'),'quartz',sprintf('\t'),num2str(123453),sprintf('\t'),num2str(3717),sprintf('\t'),'KNSTD;',sprintf('\n'),'PH-1',sprintf('\t'),'Al-26',sprintf('\t'),'quartz',sprintf('\t'),num2str(712408),sprintf('\t'),num2str(31238),sprintf('\t'),'KNSTD;'];

%Requires MATLAB R2021a or later to run Parser

%Created by Ann Rowan on 03/05/21
%Last modifed by Ann on 10/01/24


%Check if sample data contains gaps and skip samples if so
sample_data = sample_data{1};
%Check sample data is the correct size for cosmo calculator
a = find(sample_data == ':'); size(a);
if a < 14; return; end

%Format sample data for input to cosmo calculator
text = regexprep(sample_data,':','\t');

%Send sample info to cosmo calculator
url = "https://hess.ess.washington.edu/cgi-bin/matweb";
data = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no','text_block',text);

%Load the parser and parse string from data returned from cosmo calculator
import matlab.io.xml.dom.*
xDoc = parseString(Parser,data);

%Get the content of the stated elements to return as number
name = getTextContent(getElementsByTagName(xDoc,'sample_name'));
LSDn_age = str2double(getTextContent(getElementsByTagName(xDoc,'t10quartz_LSDn')));
LSDn_int = str2double(getTextContent(getElementsByTagName(xDoc,'delt10quartz_int_LSDn')));
LSDn_ext = str2double(getTextContent(getElementsByTagName(xDoc,'delt10quartz_ext_LSDn')));





   
   
   