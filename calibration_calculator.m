function [name,LSDn_age,LSDn_int,LSDn_ext] = cosmo_calculator_cal(sample_data)

%A script to generate local prodution rate from calibration data, send sample data to the adjusted online cosmo calculator and collect the
%results. Sample_data is the sample info returned from ICE-D by the script
%iced_query.m that has been reformatted to tab spaced for cosmo calculator.

%Example copied from cosmo calc website
%text = ['PH-1',sprintf('\t'),num2str(41.3567),sprintf('\t'),num2str(-70.7348),sprintf('\t'),num2str(91),sprintf('\t'),'std',sprintf('\t'),num2str(4.5),sprintf('\t'),num2str(2.65),sprintf('\t'),num2str(1),sprintf('\t'),num2str(0.00008),sprintf('\t'),num2str(1999),';', sprintf('\n'),'PH-1',sprintf('\t'),'Be-10',sprintf('\t'),'quartz',sprintf('\t'),num2str(123453),sprintf('\t'),num2str(3717),sprintf('\t'),'KNSTD;',sprintf('\n'),'PH-1',sprintf('\t'),'Al-26',sprintf('\t'),'quartz',sprintf('\t'),num2str(712408),sprintf('\t'),num2str(31238),sprintf('\t'),'KNSTD;'];

%Source: https://wiki.ice-d.org/pluginto:calculators (retrieved 26/11/24 by
%KP)
%Created by Karlijn on 26/11/24

%% Get calibration data

%clear all;

% Get some calibration data from the calibration website

cal_page_html = webread('https://version2.ice-d.org/production%20rate%20calibration%20data/site/MACAULAY/');

% Note: this input data must include data for only one nuclide

% Scrape the formatted text block out of the HTML
startindex = strfind(cal_page_html,'<!-- begin v3 --><pre>') + length('<!-- begin v3 --><pre>');
endindex = strfind(cal_page_html,'</pre><!-- end v3 -->') - 1;
cal_input_text = cal_page_html(startindex:endindex);

%Make sure to only have one nuclide in the input text!
lines = splitlines(cal_input_text);
filtered_lines = lines(~contains(lines, 'C-14')); % Filter C-14 out 
filtered_text = strjoin(filtered_lines, '\n');


%% Get local production rates
%Calculator
url = "http://hess.ess.washington.edu/cgi-bin/matweb";
cal_xml_result = webread(url,'mlmfile','cal_input_v3','reportType','XML','plotFlag','no','text_block',filtered_text);

temp = regexp(cal_xml_result,['<nuclide>(.*?)</nuclide>'],'tokens');
nuclide_string = temp{1}{1};

% Get calibrated production rate parameters for LSDn scaling method
%temp = regexp(cal_xml_result,['<summary_value_St>(.*?)</summary_value_St>'],'tokens');
%value_St_string = temp{1}{1};
%temp = regexp(cal_xml_result,['<summary_uncert_St>(.*?)</summary_uncert_St>'],'tokens');
%uncert_St_string = temp{1}{1};
%temp = regexp(cal_xml_result,['<summary_value_Lm>(.*?)</summary_value_Lm>'],'tokens');
%value_Lm_string = temp{1}{1};
%temp = regexp(cal_xml_result,['<summary_uncert_Lm>(.*?)</summary_uncert_Lm>'],'tokens');
%uncert_Lm_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_value_LSDn>(.*?)</summary_value_LSDn>'],'tokens');
value_LSDn_string = temp{1}{1};
temp = regexp(cal_xml_result,['<summary_uncert_LSDn>(.*?)</summary_uncert_LSDn>'],'tokens');
uncert_LSDn_string = temp{1}{1};

%% Get sample data to calculate exposure ages for
%copied from cosmo_calculator.m

%Check if sample data contains gaps and skip samples if so
sample_data = sample_data{1};
%Check sample data is the correct size for cosmo calculator
a = find(sample_data == ':'); size(a);
if a < 14; return; end

%Format sample data for input to cosmo calculator
text = regexprep(sample_data,':','\t');


%% Calculate ages with non-default production rate

data = webread(url,'mlmfile','age_input_v3','reportType','XML','resultType','long','plotFlag','no',...
    'text_block',text,...
    'trace_string','nothing here but this is required',...
    'calib_name','nothing here either but this is required too',...
    'nuclide_name',nuclide_string,...
    'P_St',value_St_string,'delP_St',uncert_St_string,...
    'P_Lm',value_Lm_string,'delP_Lm',uncert_Lm_string,...
    'P_LSDn',value_LSDn_string,'delP_LSDn',uncert_LSDn_string);

%Load the parser and parse string from data returned from cosmo calculator
import matlab.io.xml.dom.*
xDoc = parseString(Parser,data);

%Get the content of the stated elements to return as number
name = getTextContent(getElementsByTagName(xDoc,'sample_name'));
LSDn_age = str2double(getTextContent(getElementsByTagName(xDoc,'t10quartz_LSDn')));
LSDn_int = str2double(getTextContent(getElementsByTagName(xDoc,'delt10quartz_int_LSDn')));
LSDn_ext = str2double(getTextContent(getElementsByTagName(xDoc,'delt10quartz_ext_LSDn')));







