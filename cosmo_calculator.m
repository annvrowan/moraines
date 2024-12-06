function [names,LSDn_ages,LSDn_ints,LSDn_exts,sum_ext,sum_int,sum_val] = cosmo_calculator(sample_data)

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

%% Test

%text = ['Suth2007-A-13 -44.03550 168.47778 215.00000 std 5.0 2.65 1.0000 0 2005; ' ...
   % 'Suth2007-A-13 Be-10 quartz 109000.000 11000.000 NIST_30600; ' ...
   % 'Suth2007-A-14 -44.03550 168.47778 215.00000 std 5.0 2.65 1.0000 0 2005; ' ...
   % 'Suth2007-A-14 Be-10 quartz 81000.000 10000.000 NIST_30600;'];

%% Calculations

%Send sample info to cosmo calculator
url = "https://hess.ess.washington.edu/cgi-bin/matweb";
data = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no','text_block',text,'summary','yes');

%Load the parser and parse string from data returned from cosmo calculator
import matlab.io.xml.dom.*
xDoc = parseString(Parser,data);

% Get all LSDn ages and SD for samples
name_elements= getElementsByTagName(xDoc,'sample_name');
LSDn_age_elements = getElementsByTagName(xDoc, 't10quartz_LSDn');
LSDn_int_elements = getElementsByTagName(xDoc, 'delt10quartz_int_LSDn');
LSDn_ext_elements = getElementsByTagName(xDoc, 'delt10quartz_ext_LSDn');

no_samples = name_elements.getLength;
names = strings(1, no_samples);
LSDn_ages = zeros(1, no_samples);
LSDn_ints = zeros(1, no_samples);
LSDn_exts = zeros(1, no_samples);

% Loop through each element and extract the values
for i = 0:no_samples-1
    names(i+1) = name_elements.item(i).getTextContent;
    LSDn_ages(i+1) = str2double(LSDn_age_elements.item(i).getTextContent);
    LSDn_ints(i+1) = str2double(LSDn_int_elements.item(i).getTextContent);
    LSDn_exts(i+1) = str2double(LSDn_ext_elements.item(i).getTextContent);
end

%% Calculate landform age

%Get the summary values of the LSDn scaling method
summary= getElementsByTagName(xDoc, 'summary').item(0);
% Navigate to the <all> element within <summary>
all = getElementsByTagName(summary, 'all').item(0);
% Navigate to the <St> element within <all>
LSDn = getElementsByTagName(all, 'LSDn').item(0);

% Get the content of the 'sumval' element within <St>
sum_val = str2double(getTextContent(getElementsByTagName(LSDn, 'sumval').item(0)));
sum_int = str2double(getTextContent(getElementsByTagName(LSDn, 'sumdel_int').item(0)));
sum_ext = str2double(getTextContent(getElementsByTagName(LSDn, 'sumdel_ext').item(0)));







   
   
   